import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storage/memory_db.dart';
import 'fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime.utc(2026, 1, 1, 12);
  late List<MeshAlert> posted;

  Future<(MeshAlerts, FakeMeshService)> makeAlerts([
    Map<String, Object> initial = const {},
  ]) async {
    clock = DateTime.utc(2026, 1, 1, 12);
    posted = [];
    final service = FakeMeshService();
    final alerts = MeshAlerts(
      service,
      SettingsStore.inMemory(initial),
      post: (alert) async => posted.add(alert),
      now: () => clock,
    )..start();
    return (alerts, service);
  }

  MeshMessage message(String text, {int channel = 0, DateTime? at}) =>
      MeshMessage(
        from: 0x1234,
        channel: channel,
        text: text,
        timestamp: at ?? clock,
      );

  MeshNode node(int num) => MeshNode(num: num, displayName: 'node $num');

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Brings the link up and moves past the node-DB dump window.
  Future<void> linkReadyAndSettled(FakeMeshService service) async {
    service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.connected),
    );
    await settle();
    clock = clock.add(const Duration(minutes: 1));
  }

  group('messages', () {
    test('raises a notification by default', () async {
      final (_, service) = await makeAlerts();
      service.messages.add(message('hello'));
      await settle();

      expect(posted.single.channelKey, 'mesh_message');
    });

    test('titles with the channel and names the sender', () async {
      final (_, service) = await makeAlerts();
      service
        ..channels = const [
          MeshChannel(index: 2, name: 'DPIP', psk: [1], enabled: true),
        ]
        ..nodes.add(const MeshNode(num: 0x1234, displayName: '保大 node'));
      await settle();

      service.messages.add(
        message('地震', channel: 2, at: DateTime.utc(2026, 1, 1, 9, 5, 7)),
      );
      await settle();

      expect(posted.single.title, 'Meshtastic - DPIP');
      expect(posted.single.body, '保大 node - 09:05:07\n地震');
    });

    test('falls back to the channel index when no name is known', () async {
      // Exactly the offline case: channel names live in the radio's table, and
      // with no radio attached there is no table.
      final (_, service) = await makeAlerts();
      service.messages.add(message('hello', channel: 1));
      await settle();

      expect(posted.single.title, 'Meshtastic - CH1');
      // Sender, clock, then the message on its own line.
      expect(posted.single.body, '0x1234 - 12:00:00\nhello');
    });

    test('stays quiet for the conversation already on screen', () async {
      final (alerts, service) = await makeAlerts();
      alerts.setVisibleChannel(0);
      service.messages.add(message('hello'));
      await settle();

      expect(posted, isEmpty);
    });

    test('still announces another channel while one is on screen', () async {
      final (alerts, service) = await makeAlerts();
      alerts.setVisibleChannel(0);
      service.messages.add(message('hello', channel: 3));
      await settle();

      expect(posted, hasLength(1));
    });

    test(
      'announces the visible channel once the app is backgrounded',
      () async {
        final (alerts, service) = await makeAlerts();
        alerts
          ..setVisibleChannel(0)
          ..setForeground(foreground: false);
        service.messages.add(message('hello'));
        await settle();

        expect(posted, hasLength(1));
      },
    );

    test('respects the off switch', () async {
      final (_, service) = await makeAlerts({
        'meshtastic.notifyMessages': false,
      });
      service.messages.add(message('hello'));
      await settle();

      expect(posted, isEmpty);
    });

    test('ignores an empty body', () async {
      final (_, service) = await makeAlerts();
      service.messages.add(message(''));
      await settle();

      expect(posted, isEmpty);
    });
  });

  group('nodes', () {
    test('are off by default', () async {
      final (_, service) = await makeAlerts();
      await linkReadyAndSettled(service);
      service.nodes.add(node(1));
      await settle();

      expect(posted, isEmpty);
    });

    test('never announce the node DB delivered on connect', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      // Config download: nodes arrive before the link reports `connected`.
      for (var i = 0; i < 20; i++) {
        service.nodes.add(node(i));
      }
      await settle();

      expect(posted, isEmpty);
    });

    test('stay quiet during the settle window after connecting', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      service.connections.add(
        const MeshConnectionStatus(state: MeshConnectionState.connected),
      );
      await settle();
      clock = clock.add(const Duration(seconds: 5));

      service.nodes.add(node(99));
      await settle();
      expect(posted, isEmpty);
    });

    test('announce a node first heard after things settled', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      await linkReadyAndSettled(service);

      service.nodes.add(node(99));
      await settle();

      expect(posted.single.channelKey, 'mesh_node');
      expect(posted.single.title, 'Meshtastic');
      expect(posted.single.body, 'node 99');
    });

    test('announce each node only once', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      await linkReadyAndSettled(service);

      service.nodes
        ..add(node(99))
        ..add(node(99));
      await settle();

      expect(posted, hasLength(1));
    });

    test('cap a burst of new neighbours', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      await linkReadyAndSettled(service);

      for (var i = 100; i < 110; i++) {
        service.nodes.add(node(i));
      }
      await settle();

      expect(posted, hasLength(3));
    });

    test('a reconnect re-arms the dump suppression', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      await linkReadyAndSettled(service);

      service.connections.add(
        const MeshConnectionStatus(state: MeshConnectionState.disconnected),
      );
      await settle();
      // The next connection dumps the node DB again — nothing in it is new.
      service.nodes.add(node(500));
      await settle();

      expect(posted, isEmpty);
    });

    test('an empty display name is announced as the node id', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      await linkReadyAndSettled(service);
      service.nodes.add(const MeshNode(num: 0x10, displayName: ''));
      await settle();
      expect(posted.single.body, '0x10');
    });

    test('a burst window expires after a minute', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      await linkReadyAndSettled(service);
      for (var i = 1; i <= 3; i++) {
        service.nodes.add(node(i));
      }
      await settle();
      expect(posted, hasLength(3));

      clock = clock.add(const Duration(minutes: 2));
      service.nodes.add(node(4));
      await settle();
      expect(posted, hasLength(4));
    });

    test('an error clears the settle window', () async {
      final (_, service) = await makeAlerts({'meshtastic.notifyNodes': true});
      await linkReadyAndSettled(service);
      service.connections.add(
        const MeshConnectionStatus(state: MeshConnectionState.error),
      );
      await settle();
      service.nodes.add(node(8));
      await settle();
      expect(posted, isEmpty);
    });
  });

  test('binary messages are recorded by the chat, not announced', () async {
    final (_, service) = await makeAlerts();
    service.messages.add(
      MeshMessage(
        from: 1,
        channel: 0,
        text: '00 ff',
        timestamp: clock,
        binary: true,
      ),
    );
    await settle();
    expect(posted, isEmpty);
  });

  test('the toggles persist', () async {
    final (alerts, _) = await makeAlerts();
    await alerts.setMessagesEnabled(enabled: false);
    await alerts.setNodesEnabled(enabled: true);
    expect(alerts.messagesEnabled, isFalse);
    expect(alerts.nodesEnabled, isTrue);
    alerts.dispose();
  });

  test('a remembered channel name beats an empty radio slot', () async {
    final db = openMemoryDb();
    addTearDown(db.close);
    await MeshStore.createSchema(db);
    final store = MeshStore(db);
    await store.writeChannels({2: 'DPIP'});

    posted = [];
    final service = FakeMeshService()
      ..channels = const [
        MeshChannel(index: 2, name: '', psk: [1], enabled: true),
      ];
    final alerts = MeshAlerts(
      service,
      SettingsStore.inMemory(),
      store: store,
      post: (alert) async => posted.add(alert),
      now: () => clock,
    )..start();
    addTearDown(alerts.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    service.messages.add(message('hello', channel: 2));
    await settle();
    expect(posted.single.title, 'Meshtastic - DPIP');
  });

  test('the OS post succeeds and a rejection is swallowed', () async {
    // macOS uses the plugin's empty implementation, which never calls the
    // channel. The permissions-page test uses this same seam.
    AwesomeNotificationsPlatform.operatingSystem = 'ios';
    AwesomeNotificationsPlatform.resetInstance();
    addTearDown(() {
      AwesomeNotificationsPlatform.operatingSystem = 'macos';
      AwesomeNotificationsPlatform.resetInstance();
    });

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('awesome_notifications');
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'createNewNotification') return null;
      calls++;
      if (calls == 1) throw PlatformException(code: 'notify');
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final service = FakeMeshService();
    final settings = SettingsStore.inMemory();
    final alerts = MeshAlerts(service, settings, now: () => clock)..start();
    addTearDown(alerts.dispose);
    alerts.setForeground(foreground: false);

    service.messages.add(message('one'));
    await settle();
    service.messages.add(
      message('two', at: clock.add(const Duration(seconds: 1))),
    );
    await settle();
    expect(calls, 2);
    expect(settings.getBool(SettingKeys.meshNotifyMessages), isNull);
  });
}
