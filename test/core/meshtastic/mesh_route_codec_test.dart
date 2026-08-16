/// The `TRACEROUTE_APP` wire decode — pinned by tests so the firmware's
/// encoding cannot drift under us.
library;

import 'package:dpip/core/meshtastic/data/meshtastic_client_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtastic_flutter/meshtastic_flutter.dart' as mesh;

void main() {
  group('the probe we send', () {
    test('is addressed to the node, never broadcast', () {
      final probe = traceRouteProbe(0x336699, 0);
      expect(probe.destination, 0x336699);
      // The firmware answers a multi-hop traceroute to 0xFFFFFFFF with
      // "Multi-hop traceroute to broadcast address is not allowed" and drops
      // it, so a broadcast probe never traces anything — it only warns.
      expect(probe.destination, isNot(0xFFFFFFFF));
    });

    test('carries an empty route, so the reply holds only real hops', () {
      final probe = traceRouteProbe(0x336699, 0);
      // Each hop appends itself to what it received; a seeded entry comes
      // back as a hop that was never on the path.
      expect(mesh.RouteDiscovery.fromBuffer(probe.payload).route, isEmpty);
    });

    test('rides the channel the node was heard on', () {
      expect(traceRouteProbe(0x336699, 3).channel, 3);
      // No node-DB entry, or a channel *hash* rather than an index: neither
      // names a slot we can send on, so the primary it is.
      expect(traceRouteProbe(0x336699, null).channel, 0);
      expect(traceRouteProbe(0x336699, 242).channel, 0);
    });
  });

  group('which traceroute packets are ours', () {
    const me = 0x111111;

    bool reply({int? portnum = 70, int requestId = 42, int to = me}) =>
        isTraceRouteReply(
          portnum: portnum,
          requestId: requestId,
          to: to,
          myNodeNum: me,
        );

    test('a reply addressed to this radio is', () {
      expect(reply(), isTrue);
    });

    test('a stranger\'s probe passing through is not', () {
      // Same port, but a request (no requestId) bound elsewhere — accepting
      // it would draw someone else's route as the answer to ours.
      expect(reply(requestId: 0, to: 0xFFFFFFFF), isFalse);
      expect(reply(requestId: 0), isFalse);
      expect(reply(to: 0x222222), isFalse);
    });

    test('another port is not, nor an undecodable packet', () {
      expect(reply(portnum: 1), isFalse);
      expect(reply(portnum: null), isFalse);
    });

    test('nothing is, before the radio has told us who we are', () {
      expect(
        isTraceRouteReply(portnum: 70, requestId: 42, to: me, myNodeNum: null),
        isFalse,
      );
    });
  });

  group('the reply we decode', () {
    // Us, two relays, and the node we traced.
    const me = 0x1000;
    const target = 0x2000;

    test('puts both ends back — the wire carries only what is between', () {
      // What firmware actually sends: each *relay* appends itself, the
      // destination appends only its SNR (SNRonly: isToUs), and the origin
      // never appends. So route[] names neither end.
      final wire = mesh.RouteDiscovery(
        route: const [0x11, 0x12],
        snrTowards: const [-22, -19, 28],
        routeBack: const [0x12, 0x11],
        snrBack: const [30, -21, -25],
      );
      final route = decodeMeshRoute(
        wire.writeToBuffer(),
        origin: me,
        destination: target,
      );
      expect(route.towards.map((hop) => hop.num), [me, 0x11, 0x12, target]);
      expect(route.back.map((hop) => hop.num), [target, 0x12, 0x11, me]);
      expect(route.relayCount, 2);
    });

    test('a direct neighbour is a full result, not an empty one', () {
      // The whole reason the ends must be synthesised: a one-link trace
      // carries an empty route and reads exactly like a failure without it.
      final wire = mesh.RouteDiscovery(snrTowards: const [20], snrBack: [22]);
      final route = decodeMeshRoute(
        wire.writeToBuffer(),
        origin: me,
        destination: target,
      );
      expect(route.towards.map((hop) => hop.num), [me, target]);
      expect(route.relayCount, 0, reason: 'direct — no relays between');
      expect(route.target, target);
    });

    test('the target is the sender, never guessed from the hop list', () {
      // towards.last would be the final *relay* before this fix, and nothing
      // at all on a direct trace.
      final wire = mesh.RouteDiscovery(route: const [0x11]);
      final route = decodeMeshRoute(
        wire.writeToBuffer(),
        origin: me,
        destination: target,
      );
      expect(route.target, target);
    });

    test('SNR belongs to the hop that heard the link, one off the route', () {
      final wire = mesh.RouteDiscovery(
        route: const [0x11],
        // The first relay heard it at -5.5 dB; the destination at 7.0.
        snrTowards: const [-22, 28],
      );
      final route = decodeMeshRoute(
        wire.writeToBuffer(),
        origin: me,
        destination: target,
      );
      expect(route.towards[0].snr, isNull, reason: 'we sent it, we heard none');
      expect(route.towards[1].snr, closeTo(-5.5, 1e-9));
      expect(route.towards[2].snr, closeTo(7.0, 1e-9));
    });

    test('an unmeasured link reads blank, not -32 dB', () {
      // INT8_MIN is the firmware's pad for a hop that stamped no SNR; taken
      // literally it renders as a plausible, wrong -32 dB.
      final wire = mesh.RouteDiscovery(
        route: const [0x11],
        snrTowards: const [-128, 28],
      );
      final route = decodeMeshRoute(
        wire.writeToBuffer(),
        origin: me,
        destination: target,
      );
      expect(route.towards[1].snr, isNull);
      expect(route.towards[2].snr, closeTo(7.0, 1e-9));
    });

    test('a short SNR list leaves the rest blank, not misaligned', () {
      final wire = mesh.RouteDiscovery(
        route: const [0x11, 0x12, 0x13],
        snrTowards: const [-20],
      );
      final route = decodeMeshRoute(
        wire.writeToBuffer(),
        origin: me,
        destination: target,
      );
      expect(route.towards, hasLength(5));
      expect(route.towards[1].snr, closeTo(-5, 1e-9));
      expect(route.towards[2].snr, isNull);
      expect(route.towards[3].snr, isNull);
    });

    test('firmware without a return path yields no back route', () {
      final wire = mesh.RouteDiscovery(route: const [0x11]);
      final route = decodeMeshRoute(
        wire.writeToBuffer(),
        origin: me,
        destination: target,
      );
      // Not [target, me] — that would claim a return link nothing measured.
      expect(route.back, isEmpty);
    });

    test('garbage decodes to nothing rather than throwing', () {
      final route = decodeMeshRoute(
        const [1, 2, 3],
        origin: me,
        destination: target,
      );
      expect(route.towards, isEmpty);
      expect(route.back, isEmpty);
      expect(route.target, isNull);
    });
  });
}
