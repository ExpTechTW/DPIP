/// The mesh page, driven by a fake radio.
///
/// The screen is the only place a missed channel, a dead link, or a binary
/// packet is visible. None of that needs a real radio — the page renders
/// whatever [MeshLink] and the chat controller already decided.
library;

import 'dart:convert';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:dpip/features/meshtastic/presentation/pages/meshtastic_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../core/meshtastic/fake_mesh_service.dart';
import '../../core/storage/memory_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const wake = MethodChannel('com.exptech.dpip/screen_wake');

  setUp(() {
    messenger.setMockMethodCallHandler(wake, (call) async => null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(wake, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('the byte cap keeps a CJK draft inside one frame', (
    tester,
  ) async {
    final field = TextEditingController();
    addTearDown(field.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: field,
            inputFormatters: composerInputFormatters,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'a' * 400);
    expect(field.text.length, MeshPorts.maxTextBytes);
    await tester.enterText(find.byType(TextField), '測' * 200);
    expect(
      utf8.encode(field.text).length,
      lessThanOrEqualTo(MeshPorts.maxTextBytes),
    );
    expect(
      utf8.encode('${field.text}測').length,
      greaterThan(MeshPorts.maxTextBytes),
    );
  });

  testWidgets('disconnected chrome, the radio picker, and a busy radio', (
    tester,
  ) async {
    final page = await _open(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.meshtasticTitle), findsOneWidget);
    expect(find.text(l10n.meshtasticStateDisconnected), findsOneWidget);
    expect(find.text(l10n.meshtasticNotConnected), findsWidgets);

    page.link.start();
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connecting,
        deviceName: 'Porch',
      ),
    );
    await _rebuild(tester);
    expect(find.textContaining(l10n.meshtasticStateConnecting), findsWidgets);

    page.service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.configuring),
    );
    await _rebuild(tester);
    expect(find.text(l10n.meshtasticStateConfiguring), findsWidgets);

    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.error,
        errorMessage: 'link dropped',
      ),
    );
    await _rebuild(tester);
    expect(find.text('link dropped'), findsOneWidget);

    page.service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.disconnected),
    );
    await _rebuild(tester);

    await tester.tap(find.text(l10n.meshtasticScan));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.meshtasticNoDevices), findsOneWidget);
    await tester.tapAt(const Offset(40, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    page.service.scanResults = const [MeshDevice(id: 'radio-1', name: 'Porch')];
    await tester.tap(find.text(l10n.meshtasticScan));
    // `StreamSubscription.cancel` completes in the root zone, which a
    // widget-test pump does not flush. Turn the real queue once so the
    // new scan can replace the one the dismissed sheet left behind.
    await _flushRoot(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(page.controller.devices.map((d) => d.name), ['Porch']);
    expect(find.text('Porch'), findsOneWidget);

    page.service.owner = MeshLinkOwner.otherApp;
    await tester.tap(find.text('Porch'));
    await _flushRoot(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.meshtasticBusyTitle), findsOneWidget);
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Porch'));
    await _flushRoot(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    page.service.owner = MeshLinkOwner.free;
    await tester.tap(find.text(l10n.meshtasticConnectAnyway));
    await _flushRoot(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await page.close(tester);
  });

  testWidgets('a connected radio shows vitals, channels, and the composer', (
    tester,
  ) async {
    final page = await _open(tester, dpipChannel: 3);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    page.link.start();

    const device = MeshDevice(id: 'radio-1', name: 'Porch');
    await tester.runAsync(() => page.controller.connect(device));
    page.service
      ..region = 'US'
      ..channels = const [
        MeshChannel(index: 0, name: '', psk: [1], enabled: true),
        MeshChannel(index: 3, name: 'DPIP', psk: [1], enabled: true),
      ]
      ..radioInfo = MeshRadioInfo(
        nodeNum: 1,
        longName: 'Porch node',
        modemPreset: 'LONG_FAST',
        batteryPercent: 90,
        voltage: 4.1,
        uptime: const Duration(seconds: 45),
        region: 'US',
        hopLimit: 3,
        txPower: 20,
        channelUtilization: 1.5,
        airUtilTx: 0.4,
      )
      ..traffic = MeshTraffic(
        rxPackets: 4,
        txPackets: 2,
        rxBytes: 500,
        txBytes: 2048,
        rxUndecoded: 1,
        lastRx: AppTime.utc.toLocal(),
        lastTx: AppTime.utc.toLocal().subtract(const Duration(minutes: 5)),
        rxByPort: const {1: 2, 3: 1, 256: 1, 99: 4},
      );
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connected,
        deviceName: 'Porch',
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining(l10n.meshtasticStateConnected), findsWidgets);
    expect(find.textContaining(l10n.meshtasticChannelReady), findsOneWidget);
    expect(find.text('Switch to TW'), findsOneWidget);
    expect(find.byIcon(Icons.battery_full_outlined), findsOneWidget);
    expect(find.text('↓ 4'), findsOneWidget);

    page.service.radioInfo = MeshRadioInfo(
      nodeNum: 1,
      batteryPercent: 60,
      uptime: const Duration(minutes: 5),
    );
    page.service.traffic = MeshTraffic(
      rxPackets: 5,
      txPackets: 2,
      rxBytes: 500,
      txBytes: 2 * 1024 * 1024,
      lastRx: AppTime.utc.toLocal().subtract(const Duration(minutes: 5)),
    );
    page.service.traffics.add(page.service.traffic);
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connected,
        deviceName: 'Porch',
      ),
    );
    await _rebuild(tester);
    expect(find.byIcon(Icons.battery_5_bar_outlined), findsOneWidget);

    page.service.radioInfo = const MeshRadioInfo(
      nodeNum: 1,
      batteryPercent: 30,
    );
    page.service.traffic = const MeshTraffic(rxPackets: 6);
    page.service.traffics.add(page.service.traffic);
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connected,
        deviceName: 'Porch',
      ),
    );
    await _rebuild(tester);
    expect(find.byIcon(Icons.battery_3_bar_outlined), findsOneWidget);

    page.service.radioInfo = const MeshRadioInfo(
      nodeNum: 1,
      batteryPercent: 10,
    );
    page.service.traffic = MeshTraffic(
      rxPackets: 7,
      lastRx: AppTime.utc.toLocal().subtract(const Duration(minutes: 20)),
    );
    page.service.traffics.add(page.service.traffic);
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connected,
        deviceName: 'Porch',
      ),
    );
    await _rebuild(tester);
    expect(find.byIcon(Icons.battery_1_bar_outlined), findsOneWidget);

    page.service.radioInfo = MeshRadioInfo(
      nodeNum: 1,
      batteryPercent: 101,
      modemPreset: 'LONG_FAST',
      uptime: const Duration(days: 2, hours: 3),
    );
    page.service.traffic = const MeshTraffic(
      rxPackets: 8,
      txBytes: 2 * 1024 * 1024,
      lastRx: null,
      rxByPort: {1: 2, 3: 1, 256: 1, 99: 4},
    );
    page.service.traffics.add(page.service.traffic);
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connected,
        deviceName: 'Porch',
      ),
    );
    await _rebuild(tester);
    expect(find.text('DC'), findsOneWidget);
    expect(find.byIcon(Icons.power_outlined), findsOneWidget);

    await tester.tap(find.text('DC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.meshtasticRadio), findsWidgets);
    expect(find.text('2d 3h'), findsOneWidget);
    expect(find.text(l10n.meshtasticExternalPower), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Text'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Text'), findsOneWidget);
    expect(find.text('Position'), findsOneWidget);
    expect(find.text('DPIP'), findsWidgets);
    expect(find.text('Port 99'), findsOneWidget);
    expect(find.textContaining('2.0 MB'), findsOneWidget);
    await tester.tapAt(const Offset(40, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Switch to TW'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Switch to TW').last);
    await tester.pump();
    expect(page.service.appliedRegions, [DpipMeshChannel.region]);

    page.service.ensureChannelResult = const Err(
      MeshChannelNoSlotFailure('full'),
    );
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connected,
        deviceName: 'Porch',
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.meshtasticChannelNoSlot), findsOneWidget);

    page.service.ensureChannelResult = const Err(
      MeshChannelConflictFailure('key differs'),
    );
    page.service.connections.add(
      const MeshConnectionStatus(
        state: MeshConnectionState.connected,
        deviceName: 'Porch',
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('key differs'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(find.textContaining('/${MeshPorts.maxTextBytes}'), findsOneWidget);
    page.service.sendFailure = const NetworkFailure('radio refused');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(find.text('radio refused'), findsOneWidget);

    page.service.sendFailure = null;
    await tester.enterText(find.byType(TextField), 'sent from here');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(find.text('sent from here'), findsOneWidget);

    await tester.runAsync(() async {
      page.service.messages.add(
        MeshMessage(
          from: 7,
          channel: 3,
          text: '',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
      page.service.messages.add(
        MeshMessage(
          from: 7,
          channel: 3,
          text: '00 ff',
          timestamp: DateTime.utc(2026, 1, 2),
          binary: true,
        ),
      );
      page.service.messages.add(
        MeshMessage(
          from: 7,
          channel: 0,
          text: 'other room',
          timestamp: DateTime.utc(2026, 1, 2, 1),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.text(l10n.meshtasticEmptyMessage), findsOneWidget);
    expect(find.textContaining('Binary payload'), findsOneWidget);

    await tester.longPress(find.textContaining('Binary payload'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(l10n.meshtasticCopied), findsOneWidget);

    await tester.tap(find.text('DPIP').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('LONG_FAST'), findsWidgets);
    await tester.tap(find.text('LONG_FAST').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    page.nodes.start();
    page.service.nodes.add(const MeshNode(num: 7, displayName: 'Roof'));
    page.service.nodes.add(const MeshNode(num: 8, displayName: ''));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.hub_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Roof'), findsWidgets);
    await tester.tapAt(const Offset(40, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(l10n.meshtasticNotifyNodes));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(page.alerts.nodesEnabled, isTrue);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(l10n.meshtasticClearMessages));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(page.controller.messages, isEmpty);

    await page.close(tester);
  });
}

class _Page {
  _Page({
    required this.service,
    required this.link,
    required this.alerts,
    required this.controller,
    required this.nodes,
  });

  final FakeMeshService service;
  final MeshLink link;
  final MeshAlerts alerts;
  final MeshChatController controller;
  final MeshNodeStore nodes;
  var _closed = false;

  Future<void> close(WidgetTester tester) async {
    if (_closed) return;
    _closed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    alerts.dispose();
    nodes.dispose();
    link.dispose();
  }
}

/// Lets a root-zone future resume. Widget-test pumps only flush the fake
/// async zone, and a completed stream-subscription cancel lives in the root.
Future<void> _flushRoot(WidgetTester tester) {
  return tester.runAsync(() => Future<void>.delayed(Duration.zero));
}

/// The page watches [MeshLink], but a status delivered from a broadcast
/// stream during a test does not always mark that element dirty. Rebuild
/// it explicitly so the assertions observe the model the link already holds.
Future<void> _rebuild(WidgetTester tester) async {
  final page = tester.element(find.byType(MeshtasticPage));
  page.markNeedsBuild();
  await tester.pump();
}

Future<_Page> _open(WidgetTester tester, {int? dpipChannel}) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  late _Page page;
  await tester.runAsync(() async {
    final settings = SettingsStore.inMemory();
    if (dpipChannel != null) {
      await settings.setInt(SettingKeys.meshDpipChannel, dpipChannel);
    }
    final db = openMemoryDb();
    addTearDown(db.close);
    await MeshStore.createSchema(db);
    final store = MeshStore(db);
    final service = FakeMeshService();
    final link = MeshLink(service, settings);
    final alerts = MeshAlerts(
      service,
      settings,
      store: store,
      post: (_) async {},
    )..start();
    final nodes = MeshNodeStore(service, settings);
    final controller = MeshChatController(service, link, store);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    page = _Page(
      service: service,
      link: link,
      alerts: alerts,
      controller: controller,
      nodes: nodes,
    );
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<MeshtasticService>.value(value: page.service),
        ChangeNotifierProvider<MeshLink>.value(value: page.link),
        ChangeNotifierProvider<MeshAlerts>.value(value: page.alerts),
        ChangeNotifierProvider<MeshChatController>.value(
          value: page.controller,
        ),
        ChangeNotifierProvider<MeshNodeStore>.value(value: page.nodes),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MeshtasticPage(),
      ),
    ),
  );
  await tester.pump();
  addTearDown(() => page.close(tester));
  return page;
}
