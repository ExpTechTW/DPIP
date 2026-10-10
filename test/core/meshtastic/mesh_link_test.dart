import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const device = MeshDevice(id: 'AA:BB', name: 'YuYu_7d70');

  late SettingsStore settings;

  Future<(MeshLink, FakeMeshService)> makeLink([
    Map<String, Object> initial = const {},
  ]) async {
    final service = FakeMeshService();
    settings = SettingsStore.inMemory(initial);
    return (MeshLink(service, settings), service);
  }

  void emit(FakeMeshService service, MeshConnectionState state) =>
      service.connections.add(MeshConnectionStatus(state: state));

  // start() registers an app-lifecycle listener on the binding. A test that
  // leaves it there makes the next test's lifecycle transitions drive a dead
  // link, and that link's retry timer is then pending in the new test.
  void own(MeshLink link) => addTearDown(link.dispose);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('attach', () {
    test('remembers the radio so a restart can pick it up', () async {
      final (link, service) = await makeLink();
      expect(await link.attach(device), isNull);

      expect(service.connectedIds, ['AA:BB']);
      expect(settings.getString(SettingKeys.meshDeviceId), 'AA:BB');
      expect(settings.getString(SettingKeys.meshDeviceName), 'YuYu_7d70');
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
      own(link);
      await settle();

      expect(service.connectedIds, ['AA:BB']);
      expect(link.savedRadioName, 'YuYu_7d70');
    });

    test('does nothing without a saved radio', () async {
      final (link, service) = await makeLink();
      link.start();
      own(link);
      await settle();

      expect(service.connectCalls, 0);
      expect(link.reconnecting, isFalse);
    });
  });

  group('link loss', () {
    test('schedules a reconnect after an unexpected drop', () async {
      final (link, service) = await makeLink();
      link.start();
      own(link);
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
      own(link);
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
      own(link);
      await link.attach(device);
      await link.detach();

      emit(service, MeshConnectionState.disconnected);
      await settle();

      expect(link.reconnecting, isFalse);
      expect(settings.getString(SettingKeys.meshDeviceId), isNull);
    });
  });

  group('provisioning', () {
    test('creates the DPIP channel once the radio is up', () async {
      final (link, service) = await makeLink();
      service
        ..region = 'TW'
        ..ensureChannelResult = const Ok(2);
      link.start();
      own(link);
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
        own(link);
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
      own(link);
      await link.attach(device);

      emit(service, MeshConnectionState.connected);
      await settle();

      expect(service.appliedRegions, [DpipMeshChannel.region]);
    });

    test('never changes a region someone else chose', () async {
      final (link, service) = await makeLink();
      service.region = 'EU_868';
      link.start();
      own(link);
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
      own(link);
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

  test('a saved name finds the radio after its id rotates', () async {
    final (link, service) = await makeLink({
      'meshtastic.deviceId': 'AA:BB',
      'meshtastic.deviceName': 'YuYu_7d70',
    });
    service
      ..connectResults = const [
        Err(UnexpectedFailure('unknown peripheral')),
        Ok(null),
      ]
      ..scanResults = const [MeshDevice(id: 'CC:DD', name: 'YuYu_7d70')];
    link.start();
    own(link);
    await settle();

    expect(service.connectedIds, contains('CC:DD'));
    expect(settings.getString(SettingKeys.meshDeviceId), 'CC:DD');
    expect(link.lastError, isNull);
  });

  test('a connect that finds nothing records why', () async {
    final (link, service) = await makeLink({
      'meshtastic.deviceId': 'AA:BB',
      'meshtastic.deviceName': 'YuYu_7d70',
    });
    service
      ..connectResults = const [Err(UnexpectedFailure('gone'))]
      ..scanResults = const [];
    link.start();
    own(link);
    await settle();
    expect(link.lastError, 'gone');
  });

  test('a scan that throws still records the connect error', () async {
    final service = _ThrowingScan()
      ..connectResults = const [Err(UnexpectedFailure('gone'))];
    settings = SettingsStore.inMemory({
      'meshtastic.deviceId': 'AA:BB',
      'meshtastic.deviceName': 'YuYu_7d70',
    });
    final link = MeshLink(service, settings)..start();
    own(link);
    await settle();
    expect(link.lastError, 'gone');
  });

  testWidgets('resuming reconnects instead of waiting out the backoff', (
    tester,
  ) async {
    final (link, service) = await makeLink();
    link.start();
    await link.attach(device);
    emit(service, MeshConnectionState.connected);
    await tester.pump();

    final before = service.connectCalls;
    _resume(tester);
    await tester.pump();
    expect(service.connectCalls, before);

    emit(service, MeshConnectionState.disconnected);
    service.isConnected = false;
    await tester.pump();
    expect(link.willRetry, isTrue);

    _resume(tester);
    await tester.pump();
    expect(service.connectCalls, greaterThan(before));
    link.dispose();
  });

  testWidgets('applying a region reconnects after the reboot grace', (
    tester,
  ) async {
    final (link, service) = await makeLink();
    service.region = 'EU_868';
    link.start();
    await link.attach(device);
    emit(service, MeshConnectionState.connected);
    await tester.pump();

    expect(await link.applyRegion(), isNull);
    expect(link.willRetry, isTrue);
    service.isConnected = false;
    final calls = service.connectCalls;
    await tester.pump(const Duration(seconds: 12));
    expect(service.connectCalls, greaterThan(calls));
    link.dispose();
  });

  testWidgets('a connect that never returns is given up', (tester) async {
    final service = _HangingConnect();
    settings = SettingsStore.inMemory({
      'meshtastic.deviceId': 'AA:BB',
      'meshtastic.deviceName': 'YuYu_7d70',
    });
    final link = MeshLink(service, settings)..start();
    await tester.pump();
    expect(link.lastError, isNull);

    await tester.pump(const Duration(seconds: 50));
    expect(link.willRetry, isTrue);
    link.dispose();
  });
}

void _resume(WidgetTester tester) {
  // The listener's state machine is resumed → inactive → hidden → paused,
  // and the way back is paused → hidden → inactive → resumed.
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

class _ThrowingScan extends FakeMeshService {
  @override
  Stream<MeshDevice> scanForDevices({Duration timeout = Duration.zero}) =>
      Stream<MeshDevice>.error(StateError('scan failed'));
}

class _HangingConnect extends FakeMeshService {
  final gate = Completer<Result<void>>();

  @override
  Future<Result<void>> connectToId(String id) {
    connectCalls++;
    return gate.future;
  }
}
