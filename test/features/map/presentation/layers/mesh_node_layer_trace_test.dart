/// The mesh layer's traceroute state machine: probe → reply → dashed
/// projection, plus the failure paths.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/map/presentation/layers/mesh_node_layer.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/meshtastic/fake_mesh_service.dart';
import '../../raster_timeline_harness.dart';

void main() {
  late FakeMeshService service;
  late MeshNodeStore store;
  late MeshNodeMapLayer layer;
  late RecordingMapController controller;

  setUp(() {
    service = FakeMeshService();
    store = MeshNodeStore(
      service,
      SettingsStore.inMemory({}),
      now: () => DateTime.utc(2026, 1, 1, 12),
    )..start();
    layer = MeshNodeMapLayer(store, service: service);
    controller = RecordingMapController();
  });

  MeshNode node(int num) => MeshNode(
    num: num,
    displayName: 'n${num.toRadixString(16)}',
    latitude: 24.0 + num / 1000,
    longitude: 121.0 + num / 1000,
  );

  MeshRouteHop hop(int num, {double? snr}) => MeshRouteHop(num: num, snr: snr);

  test(
    'a probe marks tracing, the reply lands the result and projects',
    () async {
      await layer.render(controller);
      service.nodes
        ..add(node(0x1234))
        ..add(node(0x5678));
      await pumpEventQueue();

      final sent = layer.startTrace(0x5678);
      expect(layer.routeState.value.tracing, isTrue);

      await sent;
      // Still tracing: the send succeeded, the reply has not come.
      expect(layer.routeState.value.tracing, isTrue);

      service.routes.add(
        MeshRoute(
          target: 0x5678,
          towards: [hop(0x1234, snr: -5.5), hop(0x5678, snr: -4.75)],
          back: [hop(0x5678, snr: -4.75), hop(0x1234, snr: -5.5)],
        ),
      );
      await pumpEventQueue();

      final state = layer.routeState.value;
      expect(state.tracing, isFalse);
      expect(state.result?.target, 0x5678);
      expect(state.result?.towards, hasLength(2));
      // Both hops have positions, so the projection is one continuous line.
      expect(layer.routeSegments.value, hasLength(1));
      expect(layer.routeSegments.value.first, hasLength(2));
    },
  );

  test('a failed send lands in failed, not tracing', () async {
    await layer.render(controller);
    service.traceResult = Err(UnexpectedFailure('radio busy'));
    await layer.startTrace(0x5678);
    final state = layer.routeState.value;
    expect(state.tracing, isFalse);
    expect(state.failed, isTrue);
  });

  test('a second tap while a probe is in flight is ignored', () async {
    service.traceGate = Completer<Result<int>>();
    final first = layer.startTrace(0x5678);
    await pumpEventQueue();

    await layer.startTrace(0x1234);
    expect(service.tracedNodes, [0x5678]);

    // The first probe settles and answers; only then is the gate open again.
    service.traceGate!.complete(const Ok(7));
    await first;
    service.routes.add(
      MeshRoute(target: 0x5678, towards: [hop(0x5678)], back: []),
    );
    await pumpEventQueue();

    await layer.startTrace(0x1234);
    expect(service.tracedNodes, [0x5678, 0x1234]);
  });

  test('a reply that never comes times out to failed', () {
    fakeAsync((async) {
      unawaited(layer.render(controller));
      async.flushMicrotasks();

      unawaited(layer.startTrace(0x5678));
      async.flushMicrotasks();
      expect(layer.routeState.value.tracing, isTrue);

      async.elapse(const Duration(seconds: 61));
      final state = layer.routeState.value;
      expect(state.tracing, isFalse);
      expect(state.failed, isTrue);
    });
  });

  test('clearing the layer drops a settled trace', () async {
    await layer.render(controller);
    await layer.startTrace(0x5678);
    service.routes.add(
      MeshRoute(target: 0x5678, towards: [hop(0x5678)], back: []),
    );
    await pumpEventQueue();

    await layer.clear(controller);
    final state = layer.routeState.value;
    expect(state.tracing, isFalse);
    expect(state.failed, isFalse);
    expect(state.result, isNull);
  });

  test('clearing while a probe is in flight does not abandon it', () async {
    await layer.render(controller);
    await layer.startTrace(0x5678);
    // A base-map reload (a style option, a theme change) calls clear. That is
    // not the user giving up on the trace, and the subscription is the only
    // way its answer can arrive.
    await layer.clear(controller);
    expect(layer.routeState.value.tracing, isTrue);

    await layer.render(controller);
    service.routes.add(
      MeshRoute(target: 0x5678, towards: [hop(0x5678)], back: []),
    );
    await pumpEventQueue();
    expect(layer.routeState.value.result?.target, 0x5678);
  });

  test('the radio refusing the send is reported in its own words', () async {
    await layer.render(controller);
    service.nextPacketId = 99;
    await layer.startTrace(0x5678);
    service.notices.add(
      const MeshNotice(
        replyId: 99,
        message: 'TraceRoute can only be sent once every 30 seconds',
        isError: false,
      ),
    );
    await pumpEventQueue();

    final state = layer.routeState.value;
    expect(state.failed, isTrue);
    expect(state.reason, contains('30 seconds'));
  });

  test('a notice about someone else\'s packet is ignored', () async {
    await layer.render(controller);
    service.nextPacketId = 99;
    await layer.startTrace(0x5678);
    service.notices.add(
      const MeshNotice(replyId: 12345, message: 'unrelated', isError: false),
    );
    await pumpEventQueue();
    expect(layer.routeState.value.tracing, isTrue, reason: 'not our packet');
  });

  test('a reply for a different node does not resolve this probe', () async {
    await layer.render(controller);
    await layer.startTrace(0x5678);
    service.routes.add(
      MeshRoute(target: 0x1234, towards: [hop(0x1234)], back: []),
    );
    await pumpEventQueue();
    expect(layer.routeState.value.tracing, isTrue);
    expect(layer.routeState.value.result, isNull);
  });

  group('the radio\'s throttle', () {
    test('an accepted probe starts the countdown', () async {
      await layer.render(controller);
      expect(layer.traceCooldown.value, 0);

      await layer.startTrace(0x5678);
      // The radio took the packet, so its 30 s clock started — the countdown
      // begins now, not after the next press is refused.
      expect(layer.traceCooldown.value, 30);
    });

    test('a refusal restarts it, since the remainder is unknowable', () async {
      await layer.render(controller);
      service.nextPacketId = 42;
      await layer.startTrace(0x5678);
      service.notices.add(
        const MeshNotice(
          replyId: 42,
          message: 'TraceRoute can only be sent once every 30 seconds',
          isError: false,
        ),
      );
      await pumpEventQueue();

      // Another client's probe may have started the radio's clock, so how
      // much is left cannot be known — a full window is the safe bound.
      expect(layer.traceCooldown.value, 30);
      expect(layer.routeState.value.failed, isTrue);
    });

    test('it ticks down and frees the button', () {
      fakeAsync((async) {
        unawaited(layer.render(controller));
        async.flushMicrotasks();
        unawaited(layer.startTrace(0x5678));
        async.flushMicrotasks();
        expect(layer.traceCooldown.value, 30);

        async.elapse(const Duration(seconds: 10));
        expect(layer.traceCooldown.value, 20);

        async.elapse(const Duration(seconds: 25));
        expect(layer.traceCooldown.value, 0, reason: 'never below zero');
        async.elapse(const Duration(seconds: 60));
      });
    });

    test('losing the radio drops it — the count was about that link', () async {
      await layer.render(controller);
      await layer.startTrace(0x5678);
      expect(layer.traceCooldown.value, 30);

      service.connections.add(
        const MeshConnectionStatus(state: MeshConnectionState.disconnected),
      );
      await pumpEventQueue();
      expect(layer.traceCooldown.value, 0);
    });
  });
}
