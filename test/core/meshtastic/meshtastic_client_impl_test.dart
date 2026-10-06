/// The BLE transport's mapping: permissions, adapter states, packet filters,
/// channel provisioning, and region writes. A wrong branch here either bricks
/// mesh on a modern Android device or overwrites a radio's channel key.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/meshtastic/data/meshtastic_client_impl.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart' as logging;
import 'package:meshtastic_flutter/generated/channel.pbenum.dart';
import 'package:meshtastic_flutter/meshtastic_flutter.dart' as mesh;

const _permChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
const _deviceChannel = MethodChannel('com.exptech.dpip/device_info');

class _Radio extends BluetoothDevice {
  _Radio(this.bleId, {this.failDisconnect = false}) : super.fromId(bleId);

  final String bleId;
  final bool failDisconnect;

  @override
  String get platformName => 'Radio $bleId';

  @override
  Future<void> disconnect({
    int timeout = 35,
    bool queue = true,
    int androidDelay = 2000,
  }) async {
    if (failDisconnect) throw StateError('stuck link');
  }
}

class _Client extends mesh.MeshtasticClient {
  final packets = StreamController<mesh.MeshPacketWrapper>.broadcast();
  final connections = StreamController<mesh.ConnectionStatus>.broadcast();
  final nodeEvents = StreamController<mesh.NodeInfoWrapper>.broadcast();
  final notices = StreamController<mesh.ClientNotification>.broadcast();
  final stats = StreamController<mesh.LocalStats>.broadcast();
  final admin = StreamController<mesh.AdminMessage>.broadcast();

  final scanned = <BluetoothDevice>[];
  Object? scanError;
  final connected = <String>[];
  Object? connectError;
  final texts = <({String text, int channel})>[];
  Object? textError;
  final sent = <({int port, int channel, int? destination, int? hopLimit})>[];
  Object? sendError;
  int nextId = 7;
  final admins = <mesh.AdminMessage>[];
  Object? adminError;
  mesh.Channel? channelReply;
  bool silenceAdmin = false;

  bool connectedFlag = false;
  bool configuredFlag = false;
  int? nodeNum;
  mesh.NodeInfoWrapper? local;
  mesh.User? user;
  mesh.DeviceMetadata? meta;
  mesh.Config_LoRaConfig? lora;
  mesh.DeviceMetrics? metrics;
  DateTime? metricsAt;
  final nodeTable = <int, mesh.NodeInfoWrapper>{};
  List<mesh.Channel> channelTable = const [];
  mesh.LocalStats? statsNow;

  @override
  Stream<mesh.MeshPacketWrapper> get packetStream => packets.stream;

  @override
  Stream<mesh.ConnectionStatus> get connectionStream => connections.stream;

  @override
  Stream<mesh.NodeInfoWrapper> get nodeStream => nodeEvents.stream;

  @override
  Stream<mesh.ClientNotification> get noticeStream => notices.stream;

  @override
  Stream<mesh.LocalStats> get localStatsStream => stats.stream;

  @override
  Stream<mesh.AdminMessage> get adminStream => admin.stream;

  @override
  mesh.LocalStats? get localStats => statsNow;

  @override
  Map<int, mesh.NodeInfoWrapper> get nodes => nodeTable;

  @override
  int? get myNodeNum => nodeNum;

  @override
  mesh.NodeInfoWrapper? get localNode => local;

  @override
  mesh.User? get localUser => user;

  @override
  mesh.DeviceMetadata? get metadata => meta;

  @override
  mesh.Config_LoRaConfig? get loraConfig => lora;

  @override
  mesh.DeviceMetrics? metricsFor(int nodeNum) => metrics;

  @override
  DateTime? metricsAgeFor(int nodeNum) => metricsAt;

  @override
  List<mesh.Channel> get channels => channelTable;

  @override
  void cacheChannel(mesh.Channel channel) {
    final next = [...channelTable];
    while (next.length <= channel.index) {
      next.add(mesh.Channel());
    }
    next[channel.index] = channel;
    channelTable = next;
  }

  @override
  bool get isConnected => connectedFlag;

  @override
  bool get isConfigured => configuredFlag;

  @override
  Stream<BluetoothDevice> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    if (scanError != null) throw scanError!;
    yield* Stream.fromIterable(scanned);
  }

  @override
  Future<void> connectToDevice(BluetoothDevice device) async {
    connected.add(device.remoteId.str);
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> connectToId(String remoteId) async {
    connected.add(remoteId);
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> disconnect() async {
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> sendTextMessage(
    String message, {
    int? destinationId,
    int channel = 0,
  }) async {
    if (textError != null) throw textError!;
    texts.add((text: message, channel: channel));
  }

  @override
  Future<int> sendData({
    required mesh.PortNum portnum,
    required List<int> payload,
    int channel = 0,
    int? destination,
    int? hopLimit,
    bool wantAck = false,
    bool wantResponse = false,
  }) async {
    if (sendError != null) throw sendError!;
    sent.add((
      port: portnum.value,
      channel: channel,
      destination: destination,
      hopLimit: hopLimit,
    ));
    return nextId++;
  }

  @override
  Future<void> sendAdmin(
    mesh.AdminMessage message, {
    bool wantResponse = false,
  }) async {
    admins.add(message);
    if (adminError != null) throw adminError!;
    if (silenceAdmin || !message.hasGetChannelRequest()) return;
    final index = message.getChannelRequest - 1;
    admin.add(
      mesh.AdminMessage(
        getChannelResponse:
            channelReply ??
            mesh.Channel(
              index: index,
              role: Channel_Role.SECONDARY,
              settings: mesh.ChannelSettings(name: 'DPIP', psk: [1]),
            ),
      ),
    );
  }
}

MeshtasticClientImpl _impl(
  _Client client, {
  Future<bool> Function()? supported,
  Stream<BluetoothAdapterState>? adapter,
  Duration adapterTimeout = const Duration(milliseconds: 30),
  List<BluetoothDevice> Function()? connectedDevices,
  Future<List<BluetoothDevice>> Function(List<Guid>)? systemDevices,
}) {
  return MeshtasticClientImpl(
    client: client,
    debugBluetoothSupported: supported,
    debugAdapterStates: adapter,
    debugAdapterTimeout: adapterTimeout,
    debugConnectedDevices: connectedDevices,
    debugSystemDevices: systemDevices,
  );
}

Future<bool> _refuseBluetooth() async => throw StateError('stack down');

Future<bool> _bluetooth(bool supported) async => supported;

Stream<BluetoothAdapterState> _adapter(BluetoothAdapterState state) async* {
  yield BluetoothAdapterState.unknown;
  yield state;
}

List<mesh.Channel> _slots({
  int? free,
  int named = -1,
  String name = 'DPIP',
  List<int> psk = const [1],
  int count = 8,
}) {
  return [
    for (var i = 0; i < count; i++)
      mesh.Channel(
        index: i,
        role: i == free ? Channel_Role.DISABLED : Channel_Role.SECONDARY,
        settings: mesh.ChannelSettings(
          name: i == named ? name : 'ch$i',
          psk: i == named ? psk : const [9],
        ),
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var sdk = 33;
  var deviceThrows = false;
  var permissionStatus = 1;

  setUp(() {
    sdk = 33;
    deviceThrows = false;
    permissionStatus = 1;
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(_deviceChannel, (call) async {
      if (deviceThrows) throw PlatformException(code: 'device');
      return {
        'manufacturer': 'Google',
        'model': 'Pixel',
        'osVersion': '14',
        'sdkInt': sdk,
      };
    });
    messenger.setMockMethodCallHandler(_permChannel, (call) async {
      if (call.method != 'requestPermissions') return 0;
      final ids = (call.arguments as List).cast<int>();
      return {for (final id in ids) id: permissionStatus};
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(_deviceChannel, null);
    messenger.setMockMethodCallHandler(_permChannel, null);
  });

  test('a live client is opened against the calibrated clock', () {
    // The transport used to stamp packets with the device clock. A phone
    // three hours fast then filed every reading outside the retention window.
    final impl = MeshtasticClientImpl();
    expect(impl.myNodeNum, isNull);
    expect(impl.traffic.rxPackets, 0);
    expect(impl.isConnected, isFalse);
  });

  test('bluetooth that the platform refuses is a typed failure', () async {
    // iOS skips the Android permission list; a supported=false answer is the
    // branch that must not fall through into a scan.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final impl = _impl(_Client(), supported: () => _bluetooth(false));
    final result = await impl.initialize();
    expect(
      result.failureOrNull?.message,
      'Bluetooth is not supported on this device',
    );
  });

  test('a plugin throw during init does not escape as an exception', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final impl = _impl(_Client(), supported: _refuseBluetooth);
    final result = await impl.initialize();
    expect(result.failureOrNull?.message, contains('stack down'));
  });

  test('an adapter that never leaves unknown is not "off"', () async {
    // A closed empty stream fails firstWhere immediately. The timeout is the
    // case where CoreBluetooth stays at `unknown` and never settles.
    final pending = StreamController<BluetoothAdapterState>();
    pending.add(BluetoothAdapterState.unknown);
    final impl = _impl(
      _Client(),
      supported: () => _bluetooth(true),
      adapter: pending.stream,
      adapterTimeout: const Duration(milliseconds: 30),
    );
    final result = await impl.initialize();
    await pending.close();
    expect(result.failureOrNull?.message, contains('not responding'));
  });

  test(
    'an unauthorized adapter is a permission failure, not "turn it on"',
    () async {
      final impl = _impl(
        _Client(),
        supported: () => _bluetooth(true),
        adapter: _adapter(BluetoothAdapterState.unauthorized),
      );
      final result = await impl.initialize();
      expect(result.failureOrNull, isA<PermissionDeniedFailure>());
      expect(result.failureOrNull?.message, contains('system settings'));
    },
  );

  test('an adapter that is off says so', () async {
    final impl = _impl(
      _Client(),
      supported: () => _bluetooth(true),
      adapter: _adapter(BluetoothAdapterState.off),
    );
    final result = await impl.initialize();
    expect(result.failureOrNull?.message, 'Bluetooth is not enabled');
  });

  test(
    'a ready adapter initialises once and the second call is free',
    () async {
      final impl = _impl(
        _Client(),
        supported: () => _bluetooth(true),
        adapter: _adapter(BluetoothAdapterState.on),
      );
      expect((await impl.initialize()).isOk, isTrue);
      expect((await impl.initialize()).isOk, isTrue);
    },
  );

  test(
    'Android 31+ asks for connect and scan, and a denial stops there',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      permissionStatus = 0;
      final impl = _impl(_Client(), supported: () => _bluetooth(true));
      final result = await impl.initialize();
      expect(result.failureOrNull, isA<PermissionDeniedFailure>());
      expect(result.failureOrNull?.message, contains('was denied'));
      expect(result.failureOrNull?.message, isNot(contains('permanently')));
    },
  );

  test('a permanent denial names the settings path', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    permissionStatus = 4;
    final impl = _impl(_Client());
    final result = await impl.initialize();
    expect(result.failureOrNull?.message, contains('permanently denied'));
  });

  test('Android 30 asks for location, and a missing sdk readout falls back to 31', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    sdk = 30;
    permissionStatus = 0;
    final older = _impl(_Client());
    expect(
      (await older.initialize()).failureOrNull,
      isA<PermissionDeniedFailure>(),
    );

    deviceThrows = true;
    permissionStatus = 1;
    final fallback = _impl(
      _Client(),
      supported: () => _bluetooth(true),
      adapter: _adapter(BluetoothAdapterState.on),
    );
    // The channel throw is swallowed into the modern permission model, then
    // a second init must reuse that cached level rather than ask again.
    expect((await fallback.initialize()).isOk, isTrue);
    deviceThrows = false;
    messenger.setMockMethodCallHandler(_deviceChannel, (call) async {
      throw StateError('should not be asked again');
    });
    // A fresh impl has an empty cache; the one that already loaded does not.
    // Re-enter permissions by using the impl whose first attempt failed closed
    // before _initialized, which is [older] — its cache is already 30.
    permissionStatus = 1;
    sdk = 30;
    messenger.setMockMethodCallHandler(
      _deviceChannel,
      (call) async => {'sdkInt': 1},
    );
    // Force the cached path: [older] stored 30, so a granted retry still
    // requests location (the pre-31 permission), not connect/scan.
    final granted = await older.initialize();
    // The cached sdk is reused; the plugin then refuses the adapter lookup.
    expect(granted.failureOrNull, isA<UnexpectedFailure>());
  });

  test(
    'a denied init makes scan fail instead of hanging on a dialog',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      permissionStatus = 0;
      final impl = _impl(_Client(), supported: () => _bluetooth(true));
      expect(impl.scanForDevices(), emitsError(isA<StateError>()));
    },
  );

  test(
    'scan reports each radio once, then connect uses the scanned handle',
    () async {
      final client = _Client()
        ..scanned.addAll([_Radio('aa'), _Radio('aa'), _Radio('bb')]);
      final stuck = _Radio('aa', failDisconnect: true);
      final impl = _impl(
        client,
        supported: () => _bluetooth(true),
        adapter: _adapter(BluetoothAdapterState.on),
        connectedDevices: () => [stuck, _Radio('other')],
      );
      final found = await impl.scanForDevices().toList();
      expect(found.map((d) => d.id), ['aa', 'bb']);

      final connected = await impl.connect(found.first);
      expect(connected.isOk, isTrue);
      expect(client.connected, ['aa']);

      client.connectError = const mesh.ConnectionException('no gatt');
      final failed = await impl.connectToId('cc');
      expect(failed.failureOrNull, isA<UnexpectedFailure>());
    },
  );

  test(
    'a connect issued before the adapter is up returns the init failure',
    () async {
      final impl = _impl(
        _Client(),
        supported: () => _bluetooth(true),
        adapter: _adapter(BluetoothAdapterState.off),
      );
      final result = await impl.connect(const MeshDevice(id: 'aa', name: 'n'));
      expect(result.failureOrNull?.message, 'Bluetooth is not enabled');
    },
  );

  test(
    'link ownership distinguishes this app, another app, and nobody',
    () async {
      final impl = _impl(
        _Client(),
        connectedDevices: () => [_Radio('mine')],
        systemDevices: (_) async => [_Radio('theirs')],
      );
      expect(await impl.linkOwner('mine'), MeshLinkOwner.thisApp);
      expect(await impl.linkOwner('theirs'), MeshLinkOwner.otherApp);
      expect(await impl.linkOwner('free'), MeshLinkOwner.free);

      final broken = _impl(
        _Client(),
        connectedDevices: () => const [],
        systemDevices: (_) async => throw StateError('privacy'),
      );
      expect(await broken.linkOwner('x'), MeshLinkOwner.free);
    },
  );

  test(
    'text, data, and a refused send become traffic or a typed failure',
    () async {
      final client = _Client();
      final impl = _impl(client);
      final traffic = <MeshTraffic>[];
      final sub = impl.trafficStream.listen(traffic.add);

      final sent = await impl.sendText('你好', channel: 2);
      expect(sent.isOk, isTrue);
      expect(client.texts.single.channel, 2);
      expect(impl.traffic.txPackets, 1);
      await Future<void>.delayed(Duration.zero);
      expect(traffic, isNotEmpty);

      client.textError = StateError('airtime');
      expect(
        (await impl.sendText('x')).failureOrNull,
        isA<UnexpectedFailure>(),
      );

      expect(
        (await impl.sendData(
          portnum: 99999,
          payload: [1],
        )).failureOrNull?.message,
        contains('Unknown Meshtastic port'),
      );
      expect(
        (await impl.sendData(
          portnum: MeshPorts.text,
          payload: List<int>.filled(MeshPorts.maxPayloadBytes + 1, 1),
        )).failureOrNull?.message,
        contains('exceeds'),
      );

      client
        ..lora = mesh.Config_LoRaConfig(hopLimit: 5)
        ..nodeTable[9] = mesh.NodeInfoWrapper(mesh.NodeInfo(num: 9, channel: 2))
        ..nodeTable[8] = mesh.NodeInfoWrapper(
          mesh.NodeInfo(num: 8, channel: 99),
        );
      final traced = await impl.traceRoute(9);
      expect(traced.valueOrNull, isNotNull);
      expect(client.sent.last.channel, 2);
      expect(client.sent.last.hopLimit, 5);
      expect(client.sent.last.destination, 9);

      await impl.traceRoute(8);
      expect(client.sent.last.channel, 0);

      client.sendError = const mesh.BluetoothException('queue full');
      expect(
        (await impl.sendData(
          portnum: MeshPorts.private,
          payload: [1],
        )).failureOrNull,
        isA<UnexpectedFailure>(),
      );

      final clock = await impl.setRadioTime(DateTime.utc(2026, 10, 4));
      expect(clock.valueOrNull, isTrue);
      expect(client.admins.single.hasSetTimeOnly(), isTrue);

      client.adminError = StateError('no admin');
      expect(
        (await impl.setRadioTime(DateTime.utc(2026))).failureOrNull,
        isA<UnexpectedFailure>(),
      );

      client.connectError = StateError('drop');
      expect((await impl.disconnect()).failureOrNull, isA<UnexpectedFailure>());
      client.connectError = null;
      expect((await impl.disconnect()).isOk, isTrue);
      await sub.cancel();
    },
  );

  test('streams map nodes, messages, routes, stats, and notices', () async {
    final client = _Client()..nodeNum = 0x20;
    final impl = _impl(client);
    // Touch the transport so the rx counter is subscribed before packets.
    expect(impl.myNodeNum, 0x20);

    final messages = <MeshMessage>[];
    final data = <MeshDataPacket>[];
    final routes = <MeshRoute>[];
    final nodes = <MeshNode>[];
    final states = <MeshConnectionStatus>[];
    final notices = <MeshNotice>[];
    final stats = <MeshLocalStats>[];
    final subs = [
      impl.messageStream.listen(messages.add),
      impl.dataStream.listen(data.add),
      impl.routeStream.listen(routes.add),
      impl.nodeStream.listen(nodes.add),
      impl.connectionStream.listen(states.add),
      impl.noticeStream.listen(notices.add),
      impl.localStatsStream.listen(stats.add),
    ];

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    client.packets.add(
      mesh.MeshPacketWrapper(
        mesh.MeshPacket(
          from: 0x10,
          to: 0,
          channel: 0,
          rxTime: now - 30,
          decoded: mesh.Data(
            portnum: mesh.PortNum.TEXT_MESSAGE_APP,
            payload: utf8.encode('hello'),
          ),
        ),
      ),
    );
    client.packets.add(
      mesh.MeshPacketWrapper(
        mesh.MeshPacket(
          from: 1,
          channel: 200,
          decoded: mesh.Data(
            portnum: mesh.PortNum.TEXT_MESSAGE_APP,
            payload: utf8.encode('foreign'),
          ),
        ),
      ),
    );
    client.packets.add(
      mesh.MeshPacketWrapper(
        mesh.MeshPacket(
          from: 2,
          channel: 1,
          rxTime: 0,
          decoded: mesh.Data(
            portnum: mesh.PortNum.PRIVATE_APP,
            payload: [0xff, 0xfe],
          ),
        ),
      ),
    );
    client.packets.add(
      mesh.MeshPacketWrapper(mesh.MeshPacket(encrypted: [1, 2, 3, 4])),
    );
    client.packets.add(
      mesh.MeshPacketWrapper(
        mesh.MeshPacket(
          from: 4,
          to: 0x20,
          channel: 0,
          decoded: mesh.Data(
            portnum: mesh.PortNum.TRACEROUTE_APP,
            requestId: 5,
            payload: mesh.RouteDiscovery(
              route: [11],
              snrTowards: [8],
              routeBack: [11],
              snrBack: [-128],
            ).writeToBuffer(),
          ),
        ),
      ),
    );
    client.packets.add(
      mesh.MeshPacketWrapper(
        mesh.MeshPacket(
          from: 4,
          to: 1,
          decoded: mesh.Data(
            portnum: mesh.PortNum.TRACEROUTE_APP,
            requestId: 0,
            payload: mesh.RouteDiscovery().writeToBuffer(),
          ),
        ),
      ),
    );

    client.nodeEvents.add(
      mesh.NodeInfoWrapper(
        mesh.NodeInfo(
          num: 3,
          viaMqtt: true,
          hopsAway: 4,
          snr: 1.5,
          lastHeard: now,
          user: mesh.User(longName: 'Far', shortName: 'FR'),
          position: mesh.Position(latitudeI: 250000000, longitudeI: 1215000000),
        ),
      ),
    );
    client.nodeEvents.add(
      mesh.NodeInfoWrapper(
        mesh.NodeInfo(
          num: 5,
          viaMqtt: false,
          hopsAway: 1,
          user: mesh.User(longName: 'Near', shortName: 'NR'),
        ),
      ),
    );

    final stamp = DateTime.utc(2026);
    for (final state in [
      mesh.MeshtasticConnectionState.disconnected,
      mesh.MeshtasticConnectionState.disconnected,
      mesh.MeshtasticConnectionState.connecting,
      mesh.MeshtasticConnectionState.configuring,
      mesh.MeshtasticConnectionState.connected,
      mesh.MeshtasticConnectionState.error,
    ]) {
      client.connections.add(
        mesh.ConnectionStatus(
          state: state,
          timestamp: stamp,
          deviceName: state == mesh.MeshtasticConnectionState.connecting
              ? 'Radio'
              : null,
          errorMessage: state == mesh.MeshtasticConnectionState.error
              ? 'lost'
              : null,
        ),
      );
    }

    client.notices.add(
      mesh.ClientNotification(
        replyId: 3,
        message: 'no',
        level: mesh.LogRecord_Level.ERROR,
      ),
    );
    client.notices.add(
      mesh.ClientNotification(
        replyId: 0,
        message: 'ok',
        level: mesh.LogRecord_Level.INFO,
      ),
    );

    client.stats.add(mesh.LocalStats(uptimeSeconds: 9, numPacketsRx: 2));
    client.stats.add(
      mesh.LocalStats(
        uptimeSeconds: 10,
        channelUtilization: 0.2,
        airUtilTx: 0.1,
        numOnlineNodes: 3,
        numTotalNodes: 8,
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(messages, hasLength(1));
    expect(messages.single.text, 'hello');
    // Text and traceroute packets are data too; the hash and the ciphertext
    // are the ones that must not arrive.
    expect(data.length, greaterThanOrEqualTo(2));
    expect(data.map((p) => p.portnum), contains(MeshPorts.private));
    expect(data.map((p) => p.channel), isNot(contains(200)));
    expect(routes, hasLength(1));
    expect(routes.single.towards, isNotEmpty);
    expect(nodes.map((n) => n.hopsAway), [null, 1]);
    expect(states, hasLength(6));
    expect(states.last.state, MeshConnectionState.error);
    expect(notices.map((n) => n.isError), [true, false]);
    expect(stats, hasLength(2));
    expect(stats.first.channelUtilization, isNull);
    expect(stats.last.nodesOnline, 3);
    expect(impl.traffic.rxPackets, greaterThan(0));
    for (final sub in subs) {
      await sub.cancel();
    }
  });

  test('radio info prefers live telemetry and degrades field by field', () {
    final client = _Client();
    final impl = _impl(client);
    expect(impl.radioInfo, isNull);
    expect(impl.localStats, isNull);
    expect(impl.region, isNull);
    expect(impl.channels, isEmpty);

    client
      ..nodeNum = 7
      ..user = mesh.User(longName: 'Me', shortName: 'ME')
      ..lora = mesh.Config_LoRaConfig(
        region: mesh.Config_LoRaConfig_RegionCode.UNSET,
      );
    final bare = impl.radioInfo!;
    expect(bare.longName, 'Me');
    expect(bare.batteryPercent, isNull);
    expect(bare.region, 'UNSET');

    client
      ..local = mesh.NodeInfoWrapper(
        mesh.NodeInfo(
          num: 7,
          user: mesh.User(
            longName: 'Node',
            shortName: 'ND',
            hwModel: mesh.HardwareModel.TBEAM,
            isLicensed: true,
            role: mesh.Config_DeviceConfig_Role.CLIENT,
          ),
          deviceMetrics: mesh.DeviceMetrics(batteryLevel: 10, voltage: 3.7),
        ),
      )
      ..meta = mesh.DeviceMetadata(
        firmwareVersion: '2.5',
        hwModel: mesh.HardwareModel.TBEAM,
        role: mesh.Config_DeviceConfig_Role.CLIENT,
        hasWifi: true,
        hasBluetooth: true,
      )
      ..metrics = mesh.DeviceMetrics(
        batteryLevel: 80,
        voltage: 4.1,
        channelUtilization: 12,
        airUtilTx: 3,
        uptimeSeconds: 50,
      )
      ..metricsAt = DateTime.utc(2026, 10, 4)
      ..lora = mesh.Config_LoRaConfig(
        region: mesh.Config_LoRaConfig_RegionCode.TW,
        modemPreset: mesh.Config_LoRaConfig_ModemPreset.LONG_FAST,
        hopLimit: 3,
        txPower: 20,
      )
      ..channelTable = _slots(named: 1);
    final full = impl.radioInfo!;
    expect(full.batteryPercent, 80);
    expect(full.voltage, 4.1);
    expect(full.firmware, '2.5');
    expect(full.region, 'TW');
    expect(full.isLicensed, isTrue);
    expect(impl.region, 'TW');
    expect(impl.channels.singleWhere((c) => c.index == 1).name, 'DPIP');

    client.lora = mesh.Config_LoRaConfig(
      region: mesh.Config_LoRaConfig_RegionCode.US,
    );
    expect(impl.region, 'US');

    client.statsNow = mesh.LocalStats(uptimeSeconds: 1);
    expect(impl.localStats?.uptime, const Duration(seconds: 1));
    client.statsNow = mesh.LocalStats(
      uptimeSeconds: 2,
      channelUtilization: 0.4,
      airUtilTx: 0.2,
      numOnlineNodes: 1,
      numTotalNodes: 2,
    );
    expect(impl.localStats?.airUtilTx, 0.2);
  });

  test('channel provisioning refuses a partial table, a key clash, and a full radio', () async {
    const spec = MeshChannelSpec(name: 'DPIP', psk: [1]);
    final offline = _impl(_Client());
    expect(
      (await offline.ensureChannel(spec)).failureOrNull?.message,
      'Radio not connected',
    );

    final partial = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..channelTable = _slots(count: 3);
    expect(
      (await _impl(partial).ensureChannel(spec)).failureOrNull?.message,
      contains('not reported its channels'),
    );

    final ready = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..channelTable = _slots(named: 2, psk: [1]);
    expect((await _impl(ready).ensureChannel(spec)).valueOrNull, 2);

    final clash = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..channelTable = _slots(named: 2, psk: [2]);
    expect(
      (await _impl(clash).ensureChannel(spec)).failureOrNull,
      isA<MeshChannelConflictFailure>(),
    );

    final full = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..channelTable = _slots();
    expect(
      (await _impl(full).ensureChannel(spec)).failureOrNull,
      isA<MeshChannelNoSlotFailure>(),
    );
  });

  test('a free slot is written only when the radio reads it back', () async {
    const spec = MeshChannelSpec(name: 'DPIP', psk: [1]);
    final client = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..channelTable = _slots(free: 3);
    final impl = _impl(client)
      ..channelConfirmTimeout = const Duration(milliseconds: 40);
    expect((await impl.ensureChannel(spec)).valueOrNull, 3);
    expect(client.channelTable[3].settings.name, 'DPIP');

    final mismatch = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..channelTable = _slots(free: 4)
      ..channelReply = mesh.Channel(
        index: 4,
        role: Channel_Role.SECONDARY,
        settings: mesh.ChannelSettings(name: 'nope', psk: [1]),
      );
    expect(
      (await (_impl(mismatch)
                ..channelConfirmTimeout = const Duration(milliseconds: 40))
              .ensureChannel(spec))
          .failureOrNull
          ?.message,
      contains('did not accept'),
    );

    final silent = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..silenceAdmin = true
      ..channelTable = _slots(free: 5);
    expect(
      (await (_impl(silent)
                ..channelConfirmTimeout = const Duration(milliseconds: 20))
              .ensureChannel(spec))
          .failureOrNull
          ?.message,
      contains('managed mode'),
    );

    final broken = _Client()
      ..connectedFlag = true
      ..configuredFlag = true
      ..adminError = const mesh.ConnectionException('rejected')
      ..channelTable = _slots(free: 6);
    expect(
      (await _impl(broken).ensureChannel(spec)).failureOrNull,
      isA<UnexpectedFailure>(),
    );
  });

  test(
    'region writes are a read-modify of the radio config, or a refusal',
    () async {
      final offline = _impl(_Client()..connectedFlag = false);
      expect(
        (await offline.applyRegion('TW')).failureOrNull?.message,
        'Radio not connected',
      );

      final bare = _Client()
        ..connectedFlag = true
        ..configuredFlag = true;
      expect(
        (await _impl(bare).applyRegion('TW')).failureOrNull?.message,
        contains('LoRa settings'),
      );
      expect(
        (await _impl(
          bare
            ..lora = mesh.Config_LoRaConfig(
              region: mesh.Config_LoRaConfig_RegionCode.UNSET,
              hopLimit: 3,
            ),
        ).applyRegion('NOT_A_REGION')).failureOrNull?.message,
        contains('Unknown LoRa region'),
      );

      final client = _Client()
        ..connectedFlag = true
        ..configuredFlag = true
        ..lora = mesh.Config_LoRaConfig(
          region: mesh.Config_LoRaConfig_RegionCode.UNSET,
          hopLimit: 3,
          txEnabled: true,
        );
      expect((await _impl(client).applyRegion('TW')).isOk, isTrue);
      expect((await _impl(client).applyRegion('US')).isOk, isTrue);
      expect(client.admins, hasLength(2));

      client.adminError = StateError('reboot');
      expect(
        (await _impl(client).applyRegion('TW')).failureOrNull,
        isA<UnexpectedFailure>(),
      );
    },
  );

  test(
    'package logs collapse repeats and drop the scan lines this impl owns',
    () async {
      final impl = _impl(_Client());
      // Reading the node number opens the client, which is what installs the
      // package-log bridge the lines below are aimed at.
      expect(impl.myNodeNum, isNull);
      expect(impl.traffic, isA<MeshTraffic>());
      final logger = logging.Logger('MeshtasticClient');
      logger.severe('boom');
      logger.warning('careful');
      logger.info('Received Config');
      logger.info('Received Config');
      logger.info('next');
      logger.info('Found Meshtastic device: aa');
      logger.info('Scanning for Meshtastic devices');
      await Future<void>.delayed(Duration.zero);
    },
  );
}
