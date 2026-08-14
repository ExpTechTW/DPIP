import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.setMockInitialValues(initial);
    final service = FakeMeshService();
    final alerts = MeshAlerts(
      service,
      Prefs(await SharedPreferences.getInstance()),
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

  MeshNode node(int num) =>
      MeshNode(num: num, displayName: 'node $num', isOnline: true);

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
        ..nodes.add(
          const MeshNode(num: 0x1234, displayName: '保大 node', isOnline: true),
        );
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
  });
}
