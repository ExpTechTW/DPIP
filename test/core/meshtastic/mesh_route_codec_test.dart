/// The `TRACEROUTE_APP` wire decode — pinned by tests so the firmware's
/// encoding cannot drift under us.
library;

import 'package:dpip/core/meshtastic/data/meshtastic_client_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtastic_flutter/meshtastic_flutter.dart' as mesh;

void main() {
  test('decodes a reply with per-hop SNR in both directions', () {
    final wire = mesh.RouteDiscovery(
      route: const [0x10, 0x11, 0x12],
      snrTowards: const [-22, -19, 28],
      routeBack: const [0x12, 0x11, 0x10],
      snrBack: const [30, -21, -25],
    );
    final route = decodeMeshRoute(wire.writeToBuffer());
    expect(route.target, 0x12);
    expect(route.towards.map((hop) => hop.num), [0x10, 0x11, 0x12]);
    // Each hop's reading is the SNR it received the probe at, scaled by 4 on
    // the wire (firmware's own contract).
    expect(route.towards[0].snr, closeTo(-5.5, 1e-9));
    expect(route.towards[1].snr, closeTo(-4.75, 1e-9));
    expect(route.towards[2].snr, closeTo(7.0, 1e-9));
    expect(route.back.map((hop) => hop.num), [0x12, 0x11, 0x10]);
    expect(route.back[1].snr, closeTo(-5.25, 1e-9));
  });

  test('a short SNR list leaves the missing hops blank, not misaligned', () {
    // Older hops do not stamp SNR; the route then says more than the SNR
    // lists. The extra hops must stay present, just unmeasured.
    final wire = mesh.RouteDiscovery(
      route: const [0x10, 0x11, 0x12, 0x13],
      snrTowards: const [-20],
    );
    final route = decodeMeshRoute(wire.writeToBuffer());
    expect(route.towards, hasLength(4));
    expect(route.towards[0].snr, closeTo(-5, 1e-9));
    expect(route.towards[1].snr, isNull);
    expect(route.towards[2].snr, isNull);
  });

  test('garbage payload decodes to an empty route rather than throwing', () {
    final route = decodeMeshRoute(const [1, 2, 3]);
    expect(route.towards, isEmpty);
    expect(route.back, isEmpty);
  });
}
