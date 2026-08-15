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
    isOnline: true,
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
    service.traceGate = Completer<Result<void>>();
    final first = layer.startTrace(0x5678);
    await pumpEventQueue();

    await layer.startTrace(0x1234);
    expect(service.tracedNodes, [0x5678]);

    // The first probe settles and answers; only then is the gate open again.
    service.traceGate!.complete(const Ok(null));
    await first;
    service.routes.add(MeshRoute(towards: [hop(0x5678)], back: []));
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

      async.elapse(const Duration(seconds: 21));
      final state = layer.routeState.value;
      expect(state.tracing, isFalse);
      expect(state.failed, isTrue);
    });
  });

  test('clearing the layer drops the trace', () async {
    await layer.render(controller);
    await layer.startTrace(0x5678);
    await layer.clear(controller);
    final state = layer.routeState.value;
    expect(state.tracing, isFalse);
    expect(state.failed, isFalse);
    expect(state.result, isNull);
  });
}
