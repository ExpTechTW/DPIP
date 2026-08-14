import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const device = MeshDevice(id: 'AA:BB', name: 'YuYu_7d70');

  Future<(MeshLink, FakeMeshService)> makeLink([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final service = FakeMeshService();
    final prefs = Prefs(await SharedPreferences.getInstance());
    return (MeshLink(service, prefs), service);
  }

  void emit(FakeMeshService service, MeshConnectionState state) =>
      service.connections.add(MeshConnectionStatus(state: state));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('attach', () {
    test('remembers the radio so a restart can pick it up', () async {
      final (link, service) = await makeLink();
      expect(await link.attach(device), isNull);

      expect(service.connectedIds, ['AA:BB']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('meshtastic.deviceId'), 'AA:BB');
      expect(prefs.getString('meshtastic.deviceName'), 'YuYu_7d70');
    });

    test(
      'stops on a radio another app holds, and proceeds when forced',
      () async {
        final (link, service) = await makeLink();
        service.owner = MeshLinkOwner.otherApp;

        expect(await link.attach(device), MeshLink.busySentinel);
        expect(service.connectCalls, 0);

        expect(await link.attach(device, force: true), isNull);
        expect(service.connectCalls, 1);
      },
    );

    test('falls back to a scan when the saved id is stale', () async {
      final (link, service) = await makeLink();
      service
        ..connectResults = const [
          Err(UnexpectedFailure('unknown peripheral')),
          Ok(null),
        ]
        ..scanResults = const [MeshDevice(id: 'AA:BB', name: 'YuYu_7d70')];

      expect(await link.attach(device), isNull);
      expect(service.connectCalls, 2);
    });

    test('does not retry a denied permission', () async {
      final (link, service) = await makeLink();
      service.connectResults = const [
        Err(PermissionDeniedFailure('bluetooth denied')),
      ];

      expect(await link.attach(device), 'bluetooth denied');
      expect(link.reconnecting, isFalse);
      // No scan fallback either — a scan needs the same permission.
      expect(service.connectCalls, 1);
    });
  });

  group('start', () {
    test('reconnects to the saved radio', () async {
      final (link, service) = await makeLink({
        'meshtastic.deviceId': 'AA:BB',
        'meshtastic.deviceName': 'YuYu_7d70',
      });
      link.start();
      await settle();

      expect(service.connectedIds, ['AA:BB']);
      expect(link.savedRadioName, 'YuYu_7d70');
    });

    test('does nothing without a saved radio', () async {
      final (link, service) = await makeLink();
      link.start();
      await settle();

      expect(service.connectCalls, 0);
      expect(link.reconnecting, isFalse);
    });
  });

  group('link loss', () {
    test('schedules a reconnect after an unexpected drop', () async {
      final (link, service) = await makeLink();
      link.start();
      await link.attach(device);
      emit(service, MeshConnectionState.connected);
      await settle();

      emit(service, MeshConnectionState.disconnected);
      await settle();
      expect(link.reconnecting, isTrue);
    });

    test('ignores the disconnect the transport emits mid-connect', () async {
      final (link, service) = await makeLink();
      link.start();
      // A connect that reports `disconnected` while it is running — which the
      // transport does, because it tears down any previous link first.
      service.connectResults = const [Ok(null)];
      final attaching = link.attach(device);
      emit(service, MeshConnectionState.disconnected);
      await attaching;
      await settle();

      expect(link.reconnecting, isFalse);
    });

    test('does not reconnect after the user detached', () async {
      final (link, service) = await makeLink();
      link.start();
      await link.attach(device);
      await link.detach();

      emit(service, MeshConnectionState.disconnected);
      await settle();

      expect(link.reconnecting, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('meshtastic.deviceId'), isNull);
    });
  });

  group('provisioning', () {
    test('creates the DPIP channel once the radio is up', () async {
      final (link, service) = await makeLink();
      service
        ..region = 'TW'
        ..ensureChannelResult = const Ok(2);
      link.start();
      await link.attach(device);

      emit(service, MeshConnectionState.connected);
      await settle();

      expect(service.ensuredChannels.single.name, 'DPIP');
      expect(service.ensuredChannels.single.psk, [0x01]);
      expect(link.provision, MeshProvisionState.ready);
      expect(link.dpipChannel, 2);
    });

    test(
      'reports a radio with no free slot instead of overwriting one',
      () async {
        final (link, service) = await makeLink();
        service
          ..region = 'TW'
          ..ensureChannelResult = const Err(
            MeshChannelNoSlotFailure('The radio has no free channel slot'),
          );
        link.start();
        await link.attach(device);

        emit(service, MeshConnectionState.connected);
        await settle();

        expect(link.provision, MeshProvisionState.noFreeSlot);
        expect(link.dpipChannel, isNull);
      },
    );

    test('sets the region on a radio that has never had one', () async {
      final (link, service) = await makeLink();
      service.region = 'UNSET';
      link.start();
      await link.attach(device);

      emit(service, MeshConnectionState.connected);
      await settle();

      expect(service.appliedRegions, [DpipMeshChannel.region]);
    });

    test('never changes a region someone else chose', () async {
      final (link, service) = await makeLink();
      service.region = 'EU_868';
      link.start();
      await link.attach(device);

      emit(service, MeshConnectionState.connected);
      await settle();

      expect(service.appliedRegions, isEmpty);
      expect(link.regionState, MeshRegionState.mismatch);

      // Only an explicit confirmation applies it.
      expect(await link.applyRegion(), isNull);
      expect(service.appliedRegions, [DpipMeshChannel.region]);
    });

    test('forgets the channel when the link drops', () async {
      final (link, service) = await makeLink();
      service.region = 'TW';
      link.start();
      await link.attach(device);
      emit(service, MeshConnectionState.connected);
      await settle();
      expect(link.dpipChannel, 3);

      emit(service, MeshConnectionState.disconnected);
      await settle();
      expect(link.dpipChannel, isNull);
      expect(link.provision, MeshProvisionState.idle);
    });
  });
}
