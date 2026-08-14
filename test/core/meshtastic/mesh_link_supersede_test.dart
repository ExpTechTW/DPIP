import 'dart:async';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_mesh_service.dart';

/// A service whose connect can be released by the test, so `attach` /
/// `detach` can be driven *while an attempt is in flight*.
class _SlowService extends FakeMeshService {
  final gate = Completer<void>();
  var gated = true;

  @override
  Future<Result<void>> connectToId(String id) async {
    if (gated) {
      gated = false;
      await gate.future;
    }
    return super.connectToId(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const first = MeshDevice(id: 'AA:11', name: 'radio-a');
  const second = MeshDevice(id: 'BB:22', name: 'radio-b');

  Future<(MeshLink, T)> makeLink<T extends FakeMeshService>(T service) async {
    SharedPreferences.setMockInitialValues({});
    final link = MeshLink(
      service,
      Prefs(await SharedPreferences.getInstance()),
    );
    link.start();
    return (link, service);
  }

  test('picking a second radio while connected switches to it', () async {
    final (link, service) = await makeLink(FakeMeshService());
    await link.attach(first);
    service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.connected),
    );
    await Future<void>.delayed(Duration.zero);

    expect(await link.attach(second), isNull);

    // The old link is dropped and the new radio is the one connected and
    // remembered — the single-flight guard used to swallow this silently.
    expect(service.connectedIds.last, 'BB:22');
    expect(link.savedRadioId, 'BB:22');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('meshtastic.deviceId'), 'BB:22');
  });

  test('a superseded attempt cannot write its radio back', () async {
    final (link, service) = await makeLink(_SlowService());
    final firstAttach = link.attach(first); // parks inside connectToId
    await Future<void>.delayed(Duration.zero);

    final secondAttach = link.attach(second);
    service.gate.complete();
    await firstAttach;
    await secondAttach;

    expect(link.savedRadioId, 'BB:22');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('meshtastic.deviceId'), 'BB:22');
  });

  test('detach during a connect leaves no phantom link', () async {
    final (link, service) = await makeLink(_SlowService());
    final attaching = link.attach(first);
    await Future<void>.delayed(Duration.zero);

    await link.detach();
    service.gate.complete();
    await attaching;
    await Future<void>.delayed(Duration.zero);

    // The forgotten radio must not stay connected, and a `connected` that
    // lands afterwards must not be adopted either.
    expect(link.savedRadioId, isNull);
    expect(service.isConnected, isFalse);

    service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.connected),
    );
    await Future<void>.delayed(Duration.zero);
    expect(link.willRetry, isFalse);
  });
}
