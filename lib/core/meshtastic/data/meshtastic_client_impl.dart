/// BLE transport for [MeshtasticService] backed by the `meshtastic_flutter`
/// package (`MeshtasticClient` over `flutter_blue_plus`).
///
/// Owns every mapping between the package's types and the domain models in
/// `domain/meshtastic_service.dart`, and converts transport exceptions into
/// typed [Failure]s — no `MeshtasticException` or protobuf type leaks above
/// this file. The client is created lazily on first use so importing the
/// transport costs nothing at startup; a device handle maps by its BLE
/// `remoteId`, which [scanForDevices] captures while scanning.
///
/// `meshtastic_flutter`'s own `initialize()` requests all four permissions in
/// a chain and throws on the first denial — with no way to tell a one-off
/// denial from a permanently-denied one. So this impl requests the
/// permissions itself first and maps a denial to a typed
/// [PermissionDeniedFailure]; once granted, the package's re-request is a
/// no-op.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/data/mesh_traffic_counter.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show BluetoothAdapterState, BluetoothDevice, FlutterBluePlus, Guid;
import 'package:logging/logging.dart' as logging;
import 'package:meshtastic_flutter/meshtastic_flutter.dart' as mesh;
import 'package:permission_handler/permission_handler.dart' as ph;

/// The Meshtastic BLE service, needed to ask iOS which peripherals are already
/// connected (it refuses an unfiltered query for privacy reasons).
const String _meshtasticServiceUuid = '6ba1b218-15a8-461f-9fa8-5dcae273eafd';

/// Channel slots every Meshtastic radio reports (`MAX_NUM_CHANNELS`).
const int _channelSlots = 8;

/// Production impl: talks BLE to a Meshtastic radio.
class MeshtasticClientImpl implements MeshtasticService {
  mesh.MeshtasticClient? _client;
  bool _initialized = false;
  int? _cachedSdk;
  bool _logBridgeInstalled = false;
  final Map<String, BluetoothDevice> _devicesById = {};
  String? _lastBridgedMessage;
  int _lastBridgedCount = 0;
  MeshConnectionStatus? _lastConnectionLog;

  final StreamController<MeshTraffic> _trafficController =
      StreamController<MeshTraffic>.broadcast();
  final MeshTrafficCounter _counter = MeshTrafficCounter();

  mesh.MeshtasticClient get _c {
    _installLogBridge();
    final existing = _client;
    if (existing != null) return existing;
    final created = mesh.MeshtasticClient();
    _client = created;
    // Counted here, from one permanent subscription — not inside the mapped
    // public streams, which run once per listener (and not at all when nobody
    // is listening).
    // Never cancelled: the client lives as long as the app does, and the
    // counters are session totals.
    created.packetStream.listen(_countRx);
    return created;
  }

  void _countRx(mesh.MeshPacketWrapper packet) {
    final decoded = packet.decoded;
    _counter.recordRx(
      portnum: decoded?.portnum.value,
      bytes: decoded?.payload.length ?? packet.encrypted?.length ?? 0,
    );
    _publishTraffic();
  }

  void _countTx(int portnum, int bytes) {
    _counter.recordTx(portnum: portnum, bytes: bytes);
    _publishTraffic();
  }

  void _publishTraffic() {
    if (_trafficController.hasListener) _trafficController.add(traffic);
  }

  /// Bridges the package's `package:logging` records into [Log], so its
  /// per-step BLE telemetry (connect, service discovery, config download,
  /// packet TX/RX) shows up in the app log.
  ///
  /// Records below INFO are dropped: the package logs every raw `FromRadio`
  /// protobuf dump (and every `/prefs/*.proto` file header) at FINE — with the
  /// config download reading ~20 packets in 1.5 s that floods the log with
  /// near-identical blocks. INFO keeps one line per node/config step.
  ///
  /// Two repeat-suppressions on top: identical consecutive records collapse
  /// to `(×N)` (the config download emits `Received Config`/`ModuleConfig`
  /// once per packet), and the per-advertisement scan lines are dropped
  /// because this impl logs the same discovery once.
  void _installLogBridge() {
    if (_logBridgeInstalled) return;
    _logBridgeInstalled = true;
    logging.Logger.root.level = logging.Level.INFO;
    logging.Logger.root.onRecord.listen(_handleLogRecord);
  }

  void _handleLogRecord(logging.LogRecord record) {
    final text = record.message;
    if (text.startsWith('Found Meshtastic device:') ||
        text.startsWith('Scanning for Meshtastic devices')) {
      return; // covered by `meshtastic scan: found/starting` from this impl
    }
    final message = '[meshtastic] ${record.loggerName}: $text';
    if (message == _lastBridgedMessage) {
      _lastBridgedCount++;
      return;
    }
    if (_lastBridgedCount > 1) {
      Log.info('$_lastBridgedMessage (×$_lastBridgedCount)');
    }
    _lastBridgedMessage = message;
    _lastBridgedCount = 1;
    switch (record.level) {
      case >= logging.Level.SEVERE:
        Log.error(message);
      case >= logging.Level.WARNING:
        Log.warning(message);
      default:
        Log.info(message);
    }
  }

  @override
  Future<Result<void>> initialize() async {
    if (_initialized) return const Ok(null);
    Log.debug('meshtastic initialize: requesting permissions');
    try {
      final denied = await _ensurePermissions();
      if (denied != null) {
        Log.warning(
          'meshtastic initialize: ${denied.permission} denied'
          '${denied.permanent ? ' (permanent)' : ''}',
        );
        return Err(
          PermissionDeniedFailure(
            denied.permanent
                ? '${denied.permission} is permanently denied — enable it '
                      'in system settings, then scan again'
                : '${denied.permission} was denied — allow it and scan again',
          ),
        );
      }
      // Never call the package's own `initialize()`: it re-requests all four
      // Android permissions, and on iOS `permission_handler` hardcodes
      // bluetoothConnect/bluetoothScan as permanently denied, so it always
      // throws there. Permissions are handled above; do its remaining
      // environment checks here.
      if (!await FlutterBluePlus.isSupported) {
        Log.warning('meshtastic initialize: bluetooth not supported');
        return const Err(
          UnexpectedFailure('Bluetooth is not supported on this device'),
        );
      }
      final adapter = await _ensureAdapterReady();
      if (adapter != null) return Err(adapter);
      _initialized = true;
      Log.info('meshtastic initialize: ready');
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic initialize');
      return Err(_mapFailure(error));
    }
  }

  /// Requests the runtime permissions the radio needs, one at a time, so a
  /// denial (or a permanent denial) is attributed precisely instead of the
  /// package's blanket throw. Returns the first un-granted permission, or
  /// `null`.
  ///
  /// **Android only.** Which permissions are runtime permissions depends on
  /// the API level, and asking for the wrong ones fails in ways the user
  /// cannot fix:
  ///
  /// - API 31+: `BLUETOOTH_CONNECT` / `BLUETOOTH_SCAN`. `BLUETOOTH` is
  ///   declared `maxSdkVersion="30"`, so on 31+ the platform drops it from the
  ///   manifest and `permission_handler` reports it **denied with no dialog** —
  ///   asking for it (as this used to, first in the list) bricks mesh on every
  ///   modern Android device. Location is not needed either: `BLUETOOTH_SCAN`
  ///   is declared `neverForLocation`.
  /// - API ≤30: `BLUETOOTH` / `BLUETOOTH_ADMIN` are install-time permissions
  ///   and cannot be requested; a BLE scan there really does need location.
  ///
  /// iOS goes through CoreBluetooth instead — see [_ensureAdapterReady].
  Future<({String permission, bool permanent})?> _ensurePermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final sdk = await _androidSdk();
    final required = sdk >= 31
        ? const [ph.Permission.bluetoothConnect, ph.Permission.bluetoothScan]
        : const [ph.Permission.locationWhenInUse];
    for (final permission in required) {
      final status = await permission.request();
      Log.debug('meshtastic permission $permission → $status');
      if (!status.isGranted) {
        return (
          permission: permission.toString(),
          permanent: status.isPermanentlyDenied,
        );
      }
    }
    return null;
  }

  /// Waits for a usable Bluetooth adapter, or returns why it isn't.
  ///
  /// This is also **iOS's authorisation check**, on purpose. `permission_
  /// handler`'s iOS Bluetooth strategy reads `CBCentralManager.authorization`
  /// without ever triggering the system prompt, and maps `notDetermined` to
  /// *denied* — so asking it before any CoreBluetooth work (which is when a
  /// fresh install always is) reports a denial the user was never given the
  /// chance to grant. Instead we let CoreBluetooth itself answer: the adapter
  /// settles on `unauthorized` only after a real refusal, and the prompt is
  /// raised by the first scan/connect.
  Future<Failure?> _ensureAdapterReady() async {
    // The state settles asynchronously — CBCentralManager starts at `unknown`
    // and reports `on` only after init, so a bare `.first` reads too early and
    // falsely reports Bluetooth off.
    final BluetoothAdapterState state;
    try {
      state = await FlutterBluePlus.adapterState
          .firstWhere((s) => s != BluetoothAdapterState.unknown)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      Log.warning('meshtastic initialize: adapter state never settled');
      return const UnexpectedFailure(
        'Bluetooth is not responding — check it is enabled and allowed for '
        'this app, then try again',
      );
    }
    Log.debug('meshtastic initialize: adapter state = $state');
    return switch (state) {
      BluetoothAdapterState.on => null,
      // iOS-only state: the user refused the Bluetooth prompt. Telling them to
      // "turn Bluetooth on" would be wrong — it already is.
      BluetoothAdapterState.unauthorized => const PermissionDeniedFailure(
        'Bluetooth access is off for this app — enable it in system settings',
      ),
      _ => const UnexpectedFailure('Bluetooth is not enabled'),
    };
  }

  /// Android API level, cached. Falls back to 31 (the modern permission model)
  /// if the platform channel can't answer — the safer guess, because asking
  /// for `BLUETOOTH` on a modern device is unrecoverable while asking for
  /// CONNECT/SCAN on an old one merely prompts.
  Future<int> _androidSdk() async {
    if (_cachedSdk != null) return _cachedSdk!;
    try {
      final details = await DeviceInfoService.load();
      return _cachedSdk = details.sdkInt ?? 31;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic android sdk');
      return _cachedSdk = 31;
    }
  }

  @override
  Stream<MeshDevice> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    final init = await initialize();
    if (init case Err(:final failure)) {
      throw StateError(failure.message);
    }
    Log.info('meshtastic scan: starting (timeout ${timeout.inSeconds}s)');
    try {
      // The package re-advertises each radio on every scan batch — report a
      // device once per scan, or the log and UI get the same radio N times.
      final seen = <String>{};
      await for (final device in _c.scanForDevices(timeout: timeout)) {
        final id = device.remoteId.toString();
        if (!seen.add(id)) continue;
        _devicesById[id] = device;
        Log.info('meshtastic scan: found "${device.platformName}" ($id)');
        yield MeshDevice(id: id, name: device.platformName);
      }
      Log.info('meshtastic scan: finished');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic scan');
      rethrow;
    }
  }

  @override
  Future<Result<void>> connect(MeshDevice device) async {
    // A device from a scan carries its handle; anything else (a saved radio
    // being picked back up) goes through the id path.
    final handle = _devicesById[device.id];
    if (handle == null) return connectToId(device.id);
    Log.info(
      'meshtastic connect: connecting to "${device.name}" (${device.id})',
    );
    return _connect(() => _c.connectToDevice(handle), device.id);
  }

  @override
  Future<Result<void>> connectToId(String id) {
    Log.info('meshtastic connect: connecting by id ($id)');
    return _connect(() => _c.connectToId(id), id);
  }

  Future<Result<void>> _connect(
    Future<void> Function() attempt,
    String id,
  ) async {
    // Permissions and a settled, powered-on adapter first: a connect issued
    // before CoreBluetooth is up fails in a way that looks like a missing
    // radio. Matters most on the bootstrap reconnect, which runs while the
    // Bluetooth stack is still starting.
    final init = await initialize();
    if (init case Err()) return init;
    try {
      // A link this process still holds (a previous session, a half-torn-down
      // connection) makes the GATT calls fail in confusing ways — drop it
      // first. A link held by *another app* can't be dropped from here; that
      // is what `linkOwner` reports so the UI can tell the user.
      await _dropOurLink(id);
      await attempt();
      Log.info('meshtastic connect: done');
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic connect');
      return Err(_mapFailure(error));
    }
  }

  Future<void> _dropOurLink(String id) async {
    for (final device in FlutterBluePlus.connectedDevices) {
      if (device.remoteId.toString() != id) continue;
      Log.info('meshtastic connect: dropping our stale link to $id');
      try {
        await device.disconnect();
      } catch (error, stackTrace) {
        Log.handle(error, stackTrace, 'meshtastic drop stale link');
      }
    }
  }

  @override
  Future<MeshLinkOwner> linkOwner(String deviceId) async {
    if (FlutterBluePlus.connectedDevices.any(
      (d) => d.remoteId.toString() == deviceId,
    )) {
      return MeshLinkOwner.thisApp;
    }
    try {
      // Both platforms report links opened by *any* app here (iOS needs the
      // service filter for privacy; Android ignores it).
      final system = await FlutterBluePlus.systemDevices([
        Guid(_meshtasticServiceUuid),
      ]);
      final held = system.any((d) => d.remoteId.toString() == deviceId);
      if (held) {
        Log.warning('meshtastic: $deviceId is already held by another app');
      }
      return held ? MeshLinkOwner.otherApp : MeshLinkOwner.free;
    } catch (error, stackTrace) {
      // Never let a diagnostic block a connection attempt.
      Log.handle(error, stackTrace, 'meshtastic linkOwner');
      return MeshLinkOwner.free;
    }
  }

  @override
  Future<Result<void>> disconnect() async {
    try {
      await _c.disconnect();
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic disconnect');
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<void>> sendText(String text, {int channel = 0}) async {
    try {
      final bytes = utf8.encode(text);
      Log.info('meshtastic send: channel=$channel bytes=${bytes.length}');
      await _c.sendTextMessage(text, channel: channel);
      _countTx(MeshPorts.text, bytes.length);
      Log.info('meshtastic send: done');
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic sendText');
      return Err(_mapFailure(error));
    }
  }

  @override
  Stream<MeshConnectionStatus> get connectionStream => _c.connectionStream.map((
    status,
  ) {
    final state = switch (status.state) {
      mesh.MeshtasticConnectionState.disconnected =>
        MeshConnectionState.disconnected,
      mesh.MeshtasticConnectionState.connecting =>
        MeshConnectionState.connecting,
      mesh.MeshtasticConnectionState.configuring =>
        MeshConnectionState.configuring,
      mesh.MeshtasticConnectionState.connected => MeshConnectionState.connected,
      mesh.MeshtasticConnectionState.error => MeshConnectionState.error,
    };
    final mapped = MeshConnectionStatus(
      state: state,
      deviceName: status.deviceName,
      errorMessage: status.errorMessage,
    );
    // The package emits `disconnected` twice back-to-back on connect (its
    // own disconnect() plus the BLE state listener) — log the transition
    // once; the UI still receives every event.
    final last = _lastConnectionLog;
    if (last == null ||
        last.state != mapped.state ||
        last.errorMessage != mapped.errorMessage) {
      _lastConnectionLog = mapped;
      Log.info(
        'meshtastic connection: ${state.name}'
        '${status.deviceName != null ? ' (${status.deviceName})' : ''}'
        '${status.errorMessage != null ? ' — ${status.errorMessage}' : ''}',
      );
    }
    return mapped;
  });

  @override
  Stream<MeshNode> get nodeStream => _c.nodeStream.map((node) {
    return MeshNode(
      num: node.num,
      displayName: node.displayName,
      isOnline: node.isOnline,
      batteryLevel: node.batteryLevel,
      lastHeard: node.lastHeard,
      latitude: node.latitude,
      longitude: node.longitude,
      snr: node.snr,
      viaMqtt: node.viaMqtt,
    );
  });

  @override
  Stream<MeshMessage> get messageStream =>
      _c.packetStream.where((packet) => packet.isTextMessage).map((packet) {
        final payload = packet.decoded?.payload ?? const [];
        final text = utf8.decode(payload, allowMalformed: true);
        // `bytes` distinguishes "the radio sent an empty body" from "the body
        // arrived but the UI didn't render it" — a blank row is otherwise
        // indistinguishable from a rendering bug.
        Log.info(
          'meshtastic message: from #${packet.from.toRadixString(16)} '
          'ch=${packet.channel} bytes=${payload.length} rxTime=${packet.rxTime} '
          '"$text"',
        );
        return MeshMessage(
          from: packet.from,
          channel: packet.channel,
          // utf8, not String.fromCharCodes — multi-byte CJK survives.
          text: text,
          // A radio with no time source stamps `rxTime` 0; that would date a
          // message to 1970 instead of "just now" — most visible on the
          // backlog replayed after a reconnect.
          timestamp: packet.rxTime > 0
              ? DateTime.fromMillisecondsSinceEpoch(packet.rxTime * 1000)
              : AppTime.utc.toLocal(),
        );
      });

  @override
  Stream<MeshDataPacket> get dataStream =>
      _c.packetStream.where((packet) => packet.decoded != null).map((packet) {
        return MeshDataPacket(
          from: packet.from,
          channel: packet.channel,
          portnum: packet.decoded!.portnum.value,
          payload: packet.decoded!.payload,
          timestamp: packet.rxTime > 0
              ? DateTime.fromMillisecondsSinceEpoch(packet.rxTime * 1000)
              : AppTime.utc.toLocal(),
        );
      });

  @override
  Future<Result<void>> sendData({
    required int portnum,
    required List<int> payload,
    int channel = 0,
    bool wantAck = false,
  }) async {
    final port = mesh.PortNum.valueOf(portnum);
    if (port == null) {
      return Err(UnexpectedFailure('Unknown Meshtastic port $portnum'));
    }
    if (payload.length > MeshPorts.maxPayloadBytes) {
      return Err(
        UnexpectedFailure(
          'Payload of ${payload.length} B exceeds the '
          '${MeshPorts.maxPayloadBytes} B mesh frame',
        ),
      );
    }
    try {
      await _c.sendData(
        portnum: port,
        payload: payload,
        channel: channel,
        wantAck: wantAck,
      );
      _countTx(portnum, payload.length);
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic sendData');
      return Err(_mapFailure(error));
    }
  }

  @override
  MeshTraffic get traffic => _counter.snapshot;

  @override
  Stream<MeshTraffic> get trafficStream => _trafficController.stream;

  @override
  MeshRadioInfo? get radioInfo {
    final nodeNum = _c.myNodeNum;
    if (nodeNum == null) return null;
    final node = _c.localNode;
    // Live telemetry first: the node-DB copy is a snapshot from connect time
    // and is regularly stale or absent for the radio's own entry, which is
    // exactly the reading a user checks.
    final metrics = _c.metricsFor(nodeNum) ?? node?.deviceMetrics;
    final metadata = _c.metadata;
    final lora = _c.loraConfig;
    return MeshRadioInfo(
      nodeNum: nodeNum,
      longName: node?.longName ?? _c.localUser?.longName,
      shortName: node?.shortName ?? _c.localUser?.shortName,
      hardware: (metadata?.hwModel ?? node?.hwModel)?.name,
      firmware: metadata?.firmwareVersion,
      role: (metadata?.role ?? node?.role)?.name,
      region: region,
      modemPreset: lora?.modemPreset.name,
      hopLimit: lora?.hopLimit,
      txPower: lora?.txPower,
      batteryPercent: metrics?.hasBatteryLevel() ?? false
          ? metrics!.batteryLevel
          : null,
      voltage: metrics?.hasVoltage() ?? false ? metrics!.voltage : null,
      channelUtilization: metrics?.hasChannelUtilization() ?? false
          ? metrics!.channelUtilization
          : null,
      airUtilTx: metrics?.hasAirUtilTx() ?? false ? metrics!.airUtilTx : null,
      uptime: metrics?.hasUptimeSeconds() ?? false
          ? Duration(seconds: metrics!.uptimeSeconds)
          : null,
      metricsAt: _c.metricsAgeFor(nodeNum),
      isLicensed: node?.isLicensed ?? false,
      hasWifi: metadata?.hasWifi ?? false,
      hasBluetooth: metadata?.hasBluetooth ?? false,
    );
  }

  @override
  List<MeshChannel> get channels => [
    for (final (index, channel) in _c.channels.indexed)
      MeshChannel(
        index: index,
        name: channel.settings.name,
        psk: channel.settings.psk,
        enabled: channel.role != mesh.Channel_Role.DISABLED,
      ),
  ];

  @override
  String? get region {
    final code = _c.loraConfig?.region;
    if (code == null) return null;
    // The two values anything branches on are pinned to literals rather than
    // `enum.name`: protobuf can be built with `protobuf.omit_enum_names`, which
    // would make every name empty and every radio look mis-regioned.
    return switch (code) {
      mesh.Config_LoRaConfig_RegionCode.TW => 'TW',
      mesh.Config_LoRaConfig_RegionCode.UNSET => 'UNSET',
      _ => code.name,
    };
  }

  @override
  int? get myNodeNum => _c.myNodeNum;

  @override
  Future<Result<int>> ensureChannel(MeshChannelSpec spec) async {
    if (!isConnected) {
      return const Err(UnexpectedFailure('Radio not connected'));
    }
    final table = channels;
    // The firmware always sends all 8 slots during the config download, so a
    // short table means the download was cut off. Choosing a "free" slot from
    // a partial view could hand out one that is actually in use — and would
    // report "no free slot" on a radio that has five.
    if (table.length < _channelSlots) {
      Log.warning('meshtastic channel: only ${table.length} slots known');
      return const Err(
        UnexpectedFailure('The radio has not reported its channels yet'),
      );
    }

    for (final channel in table) {
      if (!channel.enabled || channel.name != spec.name) continue;
      if (_samePsk(channel.psk, spec.psk)) {
        Log.info(
          'meshtastic channel: "${spec.name}" ready at ${channel.index}',
        );
        return Ok(channel.index);
      }
      // Same name, different key. **Never** rewrite it: a `set_channel` is a
      // whole-struct overwrite, so this would replace the user's key with the
      // published default one (cutting them off from their own mesh and
      // exposing it), and at index 0 it would also demote their primary
      // channel. A licensed radio also strips PSKs by itself, which would turn
      // "fix it up" into an endless rewrite-and-reboot loop. Report it.
      Log.warning(
        'meshtastic channel: "${spec.name}" at ${channel.index} has a '
        'different key — leaving it alone',
      );
      return Err(
        MeshChannelConflictFailure(
          'A channel named "${spec.name}" already exists on the radio with a '
          'different key — rename or remove it, or set its key to AQ==',
        ),
      );
    }

    // Index 0 is the user's primary channel and is never a candidate.
    for (final channel in table) {
      if (channel.index == 0 || channel.enabled) continue;
      return _writeChannel(channel.index, spec);
    }
    Log.warning('meshtastic channel: no free slot for "${spec.name}"');
    return const Err(
      MeshChannelNoSlotFailure('The radio has no free channel slot'),
    );
  }

  /// Writes one **free** channel slot, then reads it back — a write the radio
  /// silently dropped must not look like success.
  ///
  /// Deliberately *not* wrapped in a `begin_edit_settings` /
  /// `commit_edit_settings` transaction, even though the reference Python
  /// client uses one. `commit_edit_settings` makes the firmware call
  /// `disableBluetooth()` and reboot, so the link would be gone before any
  /// confirmation could arrive and every first-time provision would look like
  /// a failure. A bare `set_channel` already persists on its own
  /// (`saveChanges(SEGMENT_CHANNELS, false)` — save, no reboot) and leaves the
  /// link up, which is what makes the read-back possible at all. It also can't
  /// leave a half-open transaction behind, which would silently suppress every
  /// later config save on that radio — including the official app's.
  Future<Result<int>> _writeChannel(int index, MeshChannelSpec spec) async {
    StreamSubscription<mesh.Channel>? replies;
    try {
      Log.info('meshtastic channel: writing "${spec.name}" to slot $index');
      final confirmation = Completer<mesh.Channel>();
      replies = _c.adminStream
          .where((m) => m.hasGetChannelResponse())
          .map((m) => m.getChannelResponse)
          .where((c) => c.index == index)
          .listen((c) {
            if (!confirmation.isCompleted) confirmation.complete(c);
          });

      await _c.sendAdmin(
        mesh.AdminMessage(
          setChannel: mesh.Channel(
            index: index,
            role: mesh.Channel_Role.SECONDARY,
            settings: mesh.ChannelSettings(name: spec.name, psk: spec.psk),
          ),
        ),
      );
      // `get_channel_request` is 1-based: 1 asks for index 0. A radio in
      // managed mode drops local admin without replying, so the timeout is
      // also how that is detected.
      await _c.sendAdmin(
        mesh.AdminMessage(getChannelRequest: index + 1),
        wantResponse: true,
      );
      final written = await confirmation.future.timeout(
        const Duration(seconds: 8),
      );
      if (written.settings.name != spec.name ||
          !_samePsk(written.settings.psk, spec.psk)) {
        Log.warning('meshtastic channel: slot $index did not take the write');
        return const Err(
          UnexpectedFailure('The radio did not accept the channel'),
        );
      }
      // Keep the cached table honest, or the next provisioning pass in this
      // session would see the pre-write state and write the same slot again.
      _c.cacheChannel(written);
      Log.info('meshtastic channel: "${spec.name}" created at $index');
      return Ok(index);
    } on TimeoutException {
      Log.warning('meshtastic channel: no confirmation from the radio');
      return const Err(
        UnexpectedFailure(
          'The radio did not confirm the channel — it may be in managed mode',
        ),
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic ensureChannel');
      return Err(_mapFailure(error));
    } finally {
      await replies?.cancel();
    }
  }

  @override
  Future<Result<void>> applyRegion(String region) async {
    if (!isConnected) {
      return const Err(UnexpectedFailure('Radio not connected'));
    }
    final code = region == 'TW'
        ? mesh.Config_LoRaConfig_RegionCode.TW
        : mesh.Config_LoRaConfig_RegionCode.values
              .where((r) => r.name == region)
              .firstOrNull;
    if (code == null) {
      return Err(UnexpectedFailure('Unknown LoRa region "$region"'));
    }
    // Read-modify-write, and **only** that. `set_config(lora)` replaces the
    // whole LoRaConfig struct, so writing a default-constructed one would ship
    // `tx_enabled = false` with no modem parameters — a radio that cannot
    // transmit, recoverable only over serial. If we never read the radio's
    // config, we have nothing safe to modify.
    final current = _c.loraConfig;
    if (current == null) {
      Log.warning('meshtastic region: refusing to write without a base config');
      return const Err(
        UnexpectedFailure('The radio has not reported its LoRa settings yet'),
      );
    }
    try {
      // No read-back: the firmware disables Bluetooth and reboots as soon as
      // it applies a radio-parameter change, so the link is gone before any
      // confirmation could arrive. The reconnect verifies it instead.
      Log.warning('meshtastic region: setting $region — the radio will reboot');
      await _c.sendAdmin(
        mesh.AdminMessage(
          setConfig: mesh.Config(lora: current.deepCopy()..region = code),
        ),
      );
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'meshtastic applyRegion');
      return Err(_mapFailure(error));
    }
  }

  bool _samePsk(List<int> a, List<int> b) =>
      a.length == b.length && !a.indexed.any((e) => b[e.$1] != e.$2);

  @override
  bool get isConnected => _c.isConnected && _c.isConfigured;

  /// Maps any transport error to a user-surfaced [Failure].
  Failure _mapFailure(Object error) => switch (error) {
    mesh.MeshtasticException(:final message) => UnexpectedFailure(message),
    _ => UnexpectedFailure('$error'),
  };
}
