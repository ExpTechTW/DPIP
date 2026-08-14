import 'package:dpip/core/meshtastic/data/mesh_traffic_counter.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var clock = DateTime.utc(2026, 1, 1);
  MeshTrafficCounter counter() => MeshTrafficCounter(now: () => clock);

  setUp(() => clock = DateTime.utc(2026, 1, 1));

  test('starts empty', () {
    final traffic = counter().snapshot;
    expect(traffic.isEmpty, isTrue);
    expect(traffic.lastRx, isNull);
    expect(traffic.lastTx, isNull);
  });

  test('counts packets, bytes and ports in each direction', () {
    final c = counter()
      ..recordRx(portnum: MeshPorts.text, bytes: 10)
      ..recordRx(portnum: MeshPorts.text, bytes: 5)
      ..recordRx(portnum: MeshPorts.private, bytes: 20)
      ..recordTx(portnum: MeshPorts.private, bytes: 7);

    final traffic = c.snapshot;
    expect(traffic.rxPackets, 3);
    expect(traffic.rxBytes, 35);
    expect(traffic.rxByPort, {MeshPorts.text: 2, MeshPorts.private: 1});
    expect(traffic.txPackets, 1);
    expect(traffic.txBytes, 7);
    expect(traffic.txByPort, {MeshPorts.private: 1});
    expect(traffic.isEmpty, isFalse);
  });

  test('counts a packet the radio could not decrypt', () {
    // It carries no port and no readable payload, but it is still proof the
    // link is delivering — which is the whole reason the counters exist.
    final traffic = (counter()..recordRx(portnum: null, bytes: 32)).snapshot;
    expect(traffic.rxPackets, 1);
    expect(traffic.rxUndecoded, 1);
    expect(traffic.rxBytes, 32);
    expect(traffic.rxByPort, isEmpty);
  });

  test('stamps the last packet in each direction', () {
    final c = counter()..recordRx(portnum: 1, bytes: 1);
    expect(c.snapshot.lastRx, DateTime.utc(2026, 1, 1));
    expect(c.snapshot.lastTx, isNull);

    clock = DateTime.utc(2026, 1, 1, 0, 5);
    c.recordTx(portnum: 1, bytes: 1);
    expect(c.snapshot.lastRx, DateTime.utc(2026, 1, 1));
    expect(c.snapshot.lastTx, DateTime.utc(2026, 1, 1, 0, 5));
  });

  test('hands out an unmodifiable snapshot', () {
    final traffic = (counter()..recordRx(portnum: 1, bytes: 1)).snapshot;
    expect(() => traffic.rxByPort[9] = 1, throwsUnsupportedError);
  });
}
