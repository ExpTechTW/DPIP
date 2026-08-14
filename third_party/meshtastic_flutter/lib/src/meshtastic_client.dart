import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../generated/admin.pb.dart';
import '../generated/mesh.pb.dart';
import '../generated/config.pb.dart';
import '../generated/module_config.pb.dart';
import '../generated/channel.pb.dart';
import '../generated/portnums.pb.dart';
import '../generated/telemetry.pb.dart';
import 'models/connection_state.dart';
import 'models/mesh_packet_wrapper.dart';
import 'models/node_info.dart';
import 'models/meshtastic_config.dart';
import 'exceptions/meshtastic_exceptions.dart';

/// Main client for communicating with Meshtastic devices over BLE
class MeshtasticClient {
  static final Logger _logger = Logger('MeshtasticClient');

  // Meshtastic BLE Service UUID
  static const String _serviceUuid = '6ba1b218-15a8-461f-9fa8-5dcae273eafd';

  // Characteristic UUIDs
  static const String _toRadioUuid = 'f75c76d2-129e-4dad-a1dd-7866124401e7';
  static const String _fromRadioUuid = '2c55e69e-4993-11ed-b878-0242ac120002';
  static const String _fromNumUuid = 'ed9da18c-a800-4f66-a670-aa7547e34453';

  // Maximum packet size
  static const int _maxPacketSize = 512;

  // The radio refills `fromradio` asynchronously, so a single empty read does
  // not always mean "the mailbox is drained". The reference Python client
  // retries the same way before giving up.
  static const int _configEmptyReadRetries = 3;
  static const Duration _emptyReadBackoff = Duration(milliseconds: 100);

  // Private fields
  BluetoothDevice? _device;
  BluetoothCharacteristic? _toRadioChar;
  BluetoothCharacteristic? _fromRadioChar;
  BluetoothCharacteristic? _fromNumChar;

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _fromNumSubscription;

  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<MeshPacketWrapper> _packetController =
      StreamController<MeshPacketWrapper>.broadcast();
  final StreamController<NodeInfoWrapper> _nodeController =
      StreamController<NodeInfoWrapper>.broadcast();
  final StreamController<AdminMessage> _adminController =
      StreamController<AdminMessage>.broadcast();

  // Configuration and state
  final Map<int, NodeInfoWrapper> _nodes = {};

  /// Live device metrics per node, and when each arrived.
  ///
  /// Separate from the node DB because the DB entry is a *snapshot taken at
  /// config-download time* — for the local radio it is often stale or missing
  /// entirely. The truth is broadcast continuously on TELEMETRY_APP, including
  /// by the attached radio about itself.
  final Map<int, DeviceMetrics> _metrics = {};
  final Map<int, DateTime> _metricsAt = {};
  MyNodeInfo? _myNodeInfo;
  Config? _config;
  Config_LoRaConfig? _lora;
  DeviceMetadata? _metadata;
  ModuleConfig? _moduleConfig;
  final List<Channel> _channels = [];
  User? _localUser;

  bool _configComplete = false;

  // Drain scheduling — see [_requestDrain].
  Future<bool>? _drainTask;
  bool _drainRequested = false;
  int _pendingEmptyRetries = 0;

  // Public streams
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;
  Stream<MeshPacketWrapper> get packetStream => _packetController.stream;
  Stream<NodeInfoWrapper> get nodeStream => _nodeController.stream;

  /// Admin replies from the radio (channel/config reads, error responses).
  Stream<AdminMessage> get adminStream => _adminController.stream;

  // Getters for current state
  Map<int, NodeInfoWrapper> get nodes => Map.unmodifiable(_nodes);
  MyNodeInfo? get myNodeInfo => _myNodeInfo;

  /// The local radio's node number, once the config download delivered it.
  int? get myNodeNum => _myNodeInfo?.myNodeNum;

  /// The radio's own entry in the node DB — where its battery, uptime and
  /// air-time live, since the firmware reports them like any other node's.
  NodeInfoWrapper? get localNode {
    final num = myNodeNum;
    return num == null ? null : _nodes[num];
  }

  /// Firmware version, hardware model and capability flags, as sent once
  /// during the config download.
  DeviceMetadata? get metadata => _metadata;

  /// The channel table as last read from the radio, index-ordered.
  List<Channel> get channels => List.unmodifiable(_channels);

  /// The freshest device metrics for [nodeNum] (battery, voltage, air time),
  /// or null if that node has never reported any.
  DeviceMetrics? metricsFor(int nodeNum) => _metrics[nodeNum];

  /// When [metricsFor] last changed for [nodeNum] — a battery reading is only
  /// meaningful next to its age.
  DateTime? metricsAgeFor(int nodeNum) => _metricsAt[nodeNum];

  /// Records a channel we just wrote, so the cached table doesn't keep
  /// reporting the pre-write state for the rest of the session (which would
  /// make a second provisioning pass rewrite the same slot).
  void cacheChannel(Channel channel) {
    while (_channels.length <= channel.index) {
      _channels.add(Channel());
    }
    _channels[channel.index] = channel;
  }

  /// The radio's LoRa config (region, preset), or null before the download.
  ///
  /// Held separately from [_config] on purpose: `Config` carries its sections
  /// in a **oneof**, and the radio sends one section per packet, so the last
  /// packet of the download (bluetooth) would otherwise be the only section
  /// left standing.
  Config_LoRaConfig? get loraConfig => _lora;
  MeshtasticConfigWrapper? get config =>
      _config != null && _moduleConfig != null
      ? MeshtasticConfigWrapper(
          config: _config!,
          moduleConfig: _moduleConfig!,
          channels: _channels,
        )
      : null;
  User? get localUser => _localUser;
  bool get isConnected => _device?.isConnected ?? false;
  bool get isConfigured => _configComplete;

  /// Initialize the client and request necessary permissions
  Future<void> initialize() async {
    _logger.info('Initializing Meshtastic client');

    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      throw const BluetoothException('Bluetooth not supported on this device');
    }

    // Request permissions
    await _requestPermissions();

    // Check if Bluetooth is enabled
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      throw const BluetoothException('Bluetooth is not enabled');
    }

    _logger.info('Meshtastic client initialized successfully');
  }

  /// Request necessary permissions for BLE
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        throw PermissionException('Permission denied: $permission');
      }
    }
  }

  /// Scan for nearby Meshtastic devices. The stream **always closes** when the
  /// timeout elapses or the listener cancels.
  ///
  /// That guarantee is the whole point of the rewrite here. The obvious
  /// `await for (results in FlutterBluePlus.scanResults)` shape cannot deliver
  /// it: `scanResults` is a broadcast stream that is never closed, and
  /// `stopScan` doesn't emit, so a loop that breaks on a flag only breaks when
  /// the *next* advertisement arrives — and after `stopScan` there is no next
  /// one. With no radio in range the generator hangs forever, taking with it
  /// every caller awaiting the scan's end: the picker's spinner never stops,
  /// and a reconnect that falls back to a scan never finishes, never retries,
  /// and never resumes.
  Stream<BluetoothDevice> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) {
    final controller = StreamController<BluetoothDevice>();
    StreamSubscription<List<ScanResult>>? results;
    Timer? deadline;
    var closing = false;

    Future<void> finish() async {
      if (closing) return;
      closing = true;
      deadline?.cancel();
      await results?.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        _logger.warning('Error stopping scan: $e');
      }
      if (!controller.isClosed) await controller.close();
    }

    controller.onListen = () async {
      _logger.info('Scanning for Meshtastic devices');
      results = FlutterBluePlus.scanResults.listen(
        (batch) {
          for (final result in batch) {
            final device = result.device;
            if (device.platformName.isNotEmpty ||
                result.advertisementData.serviceUuids.contains(
                  Guid(_serviceUuid),
                )) {
              if (!controller.isClosed) controller.add(device);
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
      );
      deadline = Timer(timeout, finish);
      try {
        await FlutterBluePlus.startScan(
          withServices: [Guid(_serviceUuid)],
          timeout: timeout,
        );
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
        await finish();
      }
    };
    controller.onCancel = finish;
    return controller.stream;
  }

  /// Connect to a radio by its BLE id, without a preceding scan.
  ///
  /// How a reconnect works after an app restart: the id is the Android MAC /
  /// iOS peripheral UUID, and both platforms can open a link to a known id
  /// directly. On iOS the UUID is only meaningful to this app (and only while
  /// the system still remembers the peripheral), so a caller must be ready for
  /// this to fail and fall back to a scan.
  Future<void> connectToId(String remoteId) =>
      connectToDevice(BluetoothDevice.fromId(remoteId));

  /// Connect to a specific Meshtastic device
  Future<void> connectToDevice(BluetoothDevice device) async {
    _logger.info(
      'Connecting to device: ${device.platformName} (${device.remoteId})',
    );

    try {
      _emitConnectionState(MeshtasticConnectionState.connecting);

      // Disconnect from any existing device
      await disconnect();

      _device = device;

      // Listen for connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // `connect` already negotiates a 512-byte MTU on Android (and ignores
      // the request on iOS, where CoreBluetooth negotiates it itself), so no
      // separate requestMtu — that only bought a second round trip.
      await device.connect(timeout: const Duration(seconds: 30));

      // Discover services
      final services = await device.discoverServices();
      final meshtasticService = services.firstWhere(
        (service) =>
            service.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase(),
        orElse: () =>
            throw const ConnectionException('Meshtastic service not found'),
      );

      // Get characteristics
      _toRadioChar = meshtasticService.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() == _toRadioUuid.toLowerCase(),
        orElse: () =>
            throw const ConnectionException('ToRadio characteristic not found'),
      );

      _fromRadioChar = meshtasticService.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() == _fromRadioUuid.toLowerCase(),
        orElse: () => throw const ConnectionException(
          'FromRadio characteristic not found',
        ),
      );

      _fromNumChar = meshtasticService.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() == _fromNumUuid.toLowerCase(),
        orElse: () =>
            throw const ConnectionException('FromNum characteristic not found'),
      );

      // Log characteristic properties for debugging
      _logger.info(
        'ToRadio properties: write=${_toRadioChar!.properties.write}, '
        'writeWithoutResponse=${_toRadioChar!.properties.writeWithoutResponse}',
      );
      _logger.info(
        'FromRadio properties: read=${_fromRadioChar!.properties.read}, '
        'notify=${_fromRadioChar!.properties.notify}',
      );
      _logger.info(
        'FromNum properties: read=${_fromNumChar!.properties.read}, '
        'notify=${_fromNumChar!.properties.notify}',
      );

      // Enable notifications on FromNum.
      //
      // `lastValueStream` (not `onValueReceived`) on purpose: it replays the
      // cached value on subscribe, so a notification that lands between
      // `setNotifyValue` and this `listen` can't be missed. Every emission
      // just schedules a drain, so the replayed value costs one empty read.
      await _fromNumChar!.setNotifyValue(true);
      _fromNumSubscription = _fromNumChar!.lastValueStream.listen(
        _handleFromNumNotification,
      );

      _emitConnectionState(MeshtasticConnectionState.configuring);

      // Start configuration process
      await _startConfiguration();

      _logger.info('Successfully connected to device');
    } catch (e) {
      _logger.severe('Failed to connect to device: $e');
      _emitConnectionState(
        MeshtasticConnectionState.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    _logger.info('Disconnecting from device');

    await _fromNumSubscription?.cancel();
    _fromNumSubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_device?.isConnected == true) {
      await _device!.disconnect();
    }

    _device = null;
    _toRadioChar = null;
    _fromRadioChar = null;
    _fromNumChar = null;

    _configComplete = false;
    _drainRequested = false;
    _pendingEmptyRetries = 0;
    _nodes.clear();
    _metrics.clear();
    _metricsAt.clear();
    _myNodeInfo = null;
    _config = null;
    _lora = null;
    _metadata = null;
    _moduleConfig = null;
    _channels.clear();
    _localUser = null;

    _emitConnectionState(MeshtasticConnectionState.disconnected);
  }

  /// Send a text message to a specific node or broadcast
  Future<void> sendTextMessage(
    String message, {
    int? destinationId,
    int channel = 0,
  }) async {
    if (!isConnected) {
      throw const ConnectionException('Not connected to a device');
    }

    if (!isConfigured) {
      throw const ConnectionException('Device configuration not complete');
    }

    // Generate a random packet ID
    final packetId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

    final packet = MeshPacket(
      from: _myNodeInfo?.myNodeNum ?? 0, // Set sender node ID
      to: destinationId ?? 0xFFFFFFFF, // 0xFFFFFFFF for broadcast
      channel: channel,
      id: packetId,
      decoded: Data(
        portnum: PortNum.TEXT_MESSAGE_APP,
        payload: utf8.encode(message),
      ),
      wantAck: destinationId != null, // Request ACK for direct messages
      hopLimit: 3,
      priority: MeshPacket_Priority.DEFAULT,
    );

    _logger.info(
      'Sending text message: "$message" from ${packet.from.toRadixString(16)} to ${packet.to.toRadixString(16)} on channel $channel',
    );
    await _sendPacket(packet);
  }

  /// Send a position update
  Future<void> sendPosition(
    double latitude,
    double longitude, {
    int? altitude,
  }) async {
    if (!isConnected) {
      throw const ConnectionException('Not connected to a device');
    }

    if (!isConfigured) {
      throw const ConnectionException('Device configuration not complete');
    }

    final position = Position(
      latitudeI: (latitude * 1e7).round(),
      longitudeI: (longitude * 1e7).round(),
      altitude: altitude,
      time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    // Generate a random packet ID
    final packetId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

    final packet = MeshPacket(
      from: _myNodeInfo?.myNodeNum ?? 0, // Set sender node ID
      to: 0xFFFFFFFF, // Broadcast
      id: packetId,
      decoded: Data(
        portnum: PortNum.POSITION_APP,
        payload: position.writeToBuffer(),
      ),
      hopLimit: 3,
      priority: MeshPacket_Priority.DEFAULT,
    );

    _logger.info(
      'Sending position: lat=$latitude, lon=$longitude, alt=$altitude',
    );
    await _sendPacket(packet);
  }

  /// Send an arbitrary payload on [portnum].
  ///
  /// The general form behind [sendTextMessage]: any app port, any channel,
  /// broadcast or direct. `from` is deliberately left unset — the firmware
  /// overwrites it ("we don't let clients assign nodenums"), and a zero `from`
  /// is what marks a packet as locally originated, which is what exempts
  /// [sendAdmin] from the remote-admin session key.
  Future<void> sendData({
    required PortNum portnum,
    required List<int> payload,
    int channel = 0,
    int? destination,
    bool wantAck = false,
    bool wantResponse = false,
  }) async {
    if (!isConnected) {
      throw const ConnectionException('Not connected to a device');
    }
    if (!isConfigured) {
      throw const ConnectionException('Device configuration not complete');
    }
    final packet = MeshPacket(
      to: destination ?? 0xFFFFFFFF,
      channel: channel,
      id: _nextPacketId(),
      decoded: Data(
        portnum: portnum,
        payload: payload,
        wantResponse: wantResponse,
      ),
      wantAck: wantAck,
      hopLimit: 3,
      priority: MeshPacket_Priority.DEFAULT,
    );
    _logger.info(
      'Sending $portnum: ${payload.length} bytes on channel $channel',
    );
    await _sendPacket(packet);
  }

  /// Sends an [AdminMessage] to the attached radio itself.
  ///
  /// Local admin only — addressed to our own node so the firmware handles it
  /// on the local path, where `mp.from == 0` skips the session-key check that
  /// guards remote administration.
  Future<void> sendAdmin(AdminMessage message, {bool wantResponse = false}) {
    final myNum = myNodeNum;
    if (myNum == null) {
      throw const ConnectionException('Node info not available yet');
    }
    return sendData(
      portnum: PortNum.ADMIN_APP,
      payload: message.writeToBuffer(),
      destination: myNum,
      wantResponse: wantResponse,
    );
  }

  /// Writes one `ToRadio` frame, using a long write where the platform needs
  /// one.
  ///
  /// iOS is the reason this exists. A plain write is capped at the negotiated
  /// ATT MTU minus 3 — 182 bytes on iOS against 509 on Android — so a
  /// full-size payload (a max-length DPIP packet, a long CJK message) succeeds
  /// on Android and fails on iOS with `data longer than allowed`. Asking for a
  /// long write switches CoreBluetooth to queued `WriteWithResponse`, which
  /// carries the full 512 bytes. It is mutually exclusive with
  /// write-without-response, so it only applies when the characteristic
  /// actually supports write-with-response (every Meshtastic radio does).
  Future<void> _writeToRadio(List<int> data) {
    final characteristic = _toRadioChar!;
    if (characteristic.properties.write) {
      return characteristic.write(data, allowLongWrite: true);
    }
    return characteristic.write(data, withoutResponse: true);
  }

  /// Packet ids only need to be unique among in-flight packets.
  int _nextPacketId() => DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

  /// Takes the device metrics out of a telemetry packet.
  ///
  /// This is where a live battery reading actually comes from — for the
  /// attached radio as much as for anyone else on the mesh, because it
  /// broadcasts its own telemetry like any other node. The node DB copy is
  /// updated too, so a re-emitted node carries the new numbers.
  void _absorbTelemetry(MeshPacketWrapper packet) {
    final payload = packet.decoded?.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final telemetry = Telemetry.fromBuffer(payload);
      if (!telemetry.hasDeviceMetrics()) return;
      final from = packet.from;
      _metrics[from] = telemetry.deviceMetrics;
      _metricsAt[from] = DateTime.now();
      final node = _nodes[from];
      if (node != null) {
        node.original.deviceMetrics = telemetry.deviceMetrics;
        _nodeController.add(node);
      }
      _logger.info(
        'Device metrics from ${from.toRadixString(16)}: '
        'battery=${telemetry.deviceMetrics.batteryLevel}% '
        'voltage=${telemetry.deviceMetrics.voltage}V',
      );
    } catch (e) {
      _logger.warning('Unreadable telemetry: $e');
    }
  }

  void _emitAdminReply(MeshPacketWrapper packet) {
    final payload = packet.decoded?.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      _adminController.add(AdminMessage.fromBuffer(payload));
    } catch (e) {
      _logger.warning('Unreadable admin reply: $e');
    }
  }

  /// Send a packet to the device
  Future<void> _sendPacket(MeshPacket packet) async {
    if (_toRadioChar == null) {
      throw const ConnectionException('ToRadio characteristic not available');
    }

    final toRadio = ToRadio(packet: packet);
    final data = toRadio.writeToBuffer();

    if (data.length > _maxPacketSize) {
      throw const ProtocolException('Packet too large');
    }

    _logger.info(
      'Sending packet: from=${packet.from.toRadixString(16)}, to=${packet.to.toRadixString(16)}, '
      'id=${packet.id}, portnum=${packet.decoded.portnum}, size=${data.length} bytes',
    );

    await _writeToRadio(data);
    _logger.fine('Packet sent successfully');
  }

  /// Start the configuration process
  Future<void> _startConfiguration() async {
    _logger.info('Starting configuration process');

    // Send wantConfigId to start configuration download
    await _writeToRadio(ToRadio(wantConfigId: 0).writeToBuffer());

    // One drain covers both halves of the handshake: the config download, and
    // — once the radio has sent `config_complete_id` and moved on to
    // STATE_SEND_PACKETS — the backlog of packets it queued while no phone was
    // connected. Stopping at `config_complete_id` would silently drop every
    // message that arrived during the disconnected window.
    final drained = await _requestDrain(emptyRetries: _configEmptyReadRetries);

    if (!_configComplete && drained) {
      // Firmware that never sent `config_complete_id`: an empty mailbox is the
      // end of the download.
      _logger.warning('Config download ended without config_complete_id');
      _markConfigured();
    }
    if (!_configComplete) {
      throw const ConnectionException(
        'Configuration download failed — the radio stopped responding',
      );
    }
  }

  /// Mark the config handshake finished and report the device as connected.
  void _markConfigured() {
    if (_configComplete) return;
    _configComplete = true;
    _emitConnectionState(MeshtasticConnectionState.connected);
  }

  /// Process incoming data from FromRadio characteristic
  Future<void> _processFromRadioData(List<int> data) async {
    try {
      final fromRadio = FromRadio.fromBuffer(data);
      _logger.fine('Received FromRadio: ${fromRadio.toString()}');

      if (fromRadio.hasMyInfo()) {
        _myNodeInfo = fromRadio.myInfo;
        _logger.info(
          'Received MyNodeInfo: myNodeNum=${_myNodeInfo!.myNodeNum.toRadixString(16)}',
        );
      }

      if (fromRadio.hasNodeInfo()) {
        final nodeInfo = NodeInfoWrapper(fromRadio.nodeInfo);
        _nodes[nodeInfo.num] = nodeInfo;
        final stored = nodeInfo.deviceMetrics;
        // Only as a starting point — a later telemetry packet overwrites it.
        if (stored != null && !_metrics.containsKey(nodeInfo.num)) {
          _metrics[nodeInfo.num] = stored;
        }
        _nodeController.add(nodeInfo);
        _logger.info(
          'Received NodeInfo: num=${nodeInfo.num.toRadixString(16)}, '
          'displayName=${nodeInfo.displayName}',
        );

        // Extract user info from the node info
        if (nodeInfo.user != null &&
            _localUser == null &&
            _myNodeInfo != null &&
            nodeInfo.num == _myNodeInfo!.myNodeNum) {
          _localUser = nodeInfo.user;
          _logger.info(
            'Received local User: longName=${_localUser!.longName}, '
            'shortName=${_localUser!.shortName}',
          );
        }
      }

      if (fromRadio.hasMetadata()) {
        _metadata = fromRadio.metadata;
        _logger.info(
          'Received DeviceMetadata: firmware=${_metadata!.firmwareVersion} '
          'hw=${_metadata!.hwModel}',
        );
      }

      if (fromRadio.hasConfig()) {
        _config = fromRadio.config;
        if (fromRadio.config.hasLora()) _lora = fromRadio.config.lora;
        _logger.info('Received Config');
      }

      if (fromRadio.hasModuleConfig()) {
        _moduleConfig = fromRadio.moduleConfig;
        _logger.info('Received ModuleConfig');
      }

      if (fromRadio.hasChannel()) {
        final channel = fromRadio.channel;
        if (channel.index < _channels.length) {
          _channels[channel.index] = channel;
        } else {
          while (_channels.length <= channel.index) {
            _channels.add(Channel());
          }
          _channels[channel.index] = channel;
        }
        _logger.info('Received Channel ${channel.index}');
      }

      if (fromRadio.hasPacket()) {
        final packetWrapper = MeshPacketWrapper(fromRadio.packet);
        _packetController.add(packetWrapper);
        _logger.info('Received MeshPacket: ${packetWrapper.toString()}');
        if (packetWrapper.portnum == PortNum.ADMIN_APP) {
          _emitAdminReply(packetWrapper);
        }
        if (packetWrapper.portnum == PortNum.TELEMETRY_APP) {
          _absorbTelemetry(packetWrapper);
        }
      }

      if (fromRadio.hasConfigCompleteId()) {
        _logger.info('Configuration complete');
        _markConfigured();

        // Log summary of received configuration
        _logger.info('Configuration summary:');
        _logger.info('  MyNodeInfo: ${_myNodeInfo != null ? "✓" : "✗"}');
        _logger.info('  Config: ${_config != null ? "✓" : "✗"}');
        _logger.info('  ModuleConfig: ${_moduleConfig != null ? "✓" : "✗"}');
        _logger.info('  Channels: ${_channels.length}');
        _logger.info('  Nodes: ${_nodes.length}');
        _logger.info('  LocalUser: ${_localUser != null ? "✓" : "✗"}');
      }
    } catch (e) {
      _logger.warning('Error processing FromRadio data: $e');
      throw ProtocolException('Failed to parse FromRadio data', e);
    }
  }

  /// Handle FromNum notifications
  void _handleFromNumNotification(List<int> data) {
    if (data.length >= 4) {
      final bytes = Uint8List.fromList(data);
      final fromNum = ByteData.view(bytes.buffer).getUint32(0, Endian.little);
      _logger.fine('FromNum notification: $fromNum');
    }
    // The number itself is advisory: it is the radio's own packet counter and
    // it restarts when the radio reboots, so gating reads on "greater than the
    // last one seen" stops delivering packets after a reboot. The reference
    // clients ignore the value and just drain the mailbox — so do we.
    unawaited(_requestDrain());
  }

  /// Read `fromradio` until the radio's mailbox is empty.
  ///
  /// Single-flight: while a drain is running, a new request only raises a flag
  /// (and its retry budget), so notifications never start a second read loop
  /// interleaved with the first on the same characteristic. The returned
  /// future completes once the requester's own pass has run.
  ///
  /// [emptyRetries] is how many empty reads to tolerate before declaring the
  /// mailbox drained; the config handshake allows a few because the radio
  /// refills `fromradio` asynchronously, a notification-driven drain does not
  /// need to wait.
  Future<bool> _requestDrain({int emptyRetries = 0}) {
    if (emptyRetries > _pendingEmptyRetries) {
      _pendingEmptyRetries = emptyRetries;
    }
    _drainRequested = true;
    return _drainTask ??= _drainFromRadio().whenComplete(
      () => _drainTask = null,
    );
  }

  Future<bool> _drainFromRadio() async {
    var clean = true;
    while (_drainRequested) {
      _drainRequested = false;
      final retries = _pendingEmptyRetries;
      _pendingEmptyRetries = 0;
      clean = await _readUntilEmpty(retries);
      if (!clean) break;
    }
    return clean;
  }

  /// One read pass. Returns `false` if it stopped on a transport error rather
  /// than on an empty mailbox.
  Future<bool> _readUntilEmpty(int emptyRetries) async {
    var retries = 0;
    while (true) {
      final char = _fromRadioChar;
      if (char == null) return false;

      List<int> data;
      try {
        data = await char.read();
      } catch (e) {
        _logger.warning('Error reading from FromRadio: $e');
        return false;
      }

      if (data.isEmpty) {
        if (retries >= emptyRetries) return true;
        retries++;
        await Future.delayed(_emptyReadBackoff);
        continue;
      }
      retries = 0;

      try {
        await _processFromRadioData(data);
      } catch (e) {
        // One unparseable packet must not abandon the rest of the backlog.
        _logger.warning('Skipping unreadable FromRadio packet: $e');
      }
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _logger.info('Device disconnected');
    // The next connection re-runs the handshake from scratch; leaving this set
    // would make `isConfigured` lie and skip the config download (and with it
    // the backlog replay) on reconnect.
    _configComplete = false;
    _emitConnectionState(MeshtasticConnectionState.disconnected);
  }

  /// Emit connection state change
  void _emitConnectionState(
    MeshtasticConnectionState state, {
    String? errorMessage,
  }) {
    final status = ConnectionStatus(
      state: state,
      deviceAddress: _device?.remoteId.toString(),
      deviceName: _device?.platformName,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );

    _connectionController.add(status);
  }

  /// Dispose of the client and clean up resources
  void dispose() {
    _logger.info('Disposing Meshtastic client');

    disconnect();
    _connectionController.close();
    _packetController.close();
    _nodeController.close();
    _adminController.close();
  }
}
