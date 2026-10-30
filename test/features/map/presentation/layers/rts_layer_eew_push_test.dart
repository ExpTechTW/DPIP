/// Pins how often [RtsMapLayer] hands the EEW overlay to the native map.
///
/// The RTS feed notifies roughly once a second and `_pushUpdate` ends with an
/// unconditional EEW push, so a **calm** feed used to re-upload the same empty
/// `FeatureCollection` every second — a platform-channel round trip and a native
/// GeoJSON source replacement, for a source that was already empty, for as long
/// as the layer stayed attached (which includes while the map tab is hidden:
/// pausing the render loop does not stop the Dart listener).
///
/// The guard must be exactly one-sided. Skipping a redundant *empty* push is
/// free. A live ring is skipped only while it has moved less than a screen
/// pixel; the upload that follows draws the radius at that instant, so the
/// ring never stays behind the wave.
library;

import 'dart:async';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/render_tier.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

const String _eewSourceId = 'rts-eew-src';

/// Adds `setGeoJsonSource` recording to the shared recording controller, which
/// otherwise absorbs it through `noSuchMethod`.
class _EewRecordingController extends RecordingMapController {
  final List<Map<String, dynamic>> eewPushes = [];

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {
    if (sourceId == _eewSourceId) eewPushes.add(geojson);
    calls.add('setGeoJsonSource:$sourceId');
  }
}

/// Holds every EEW write open until [gate] completes — a phone whose map takes
/// longer than a wavefront tick to apply a ring set.
class _SlowEewController extends _EewRecordingController {
  Completer<void>? gate;

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {
    await super.setGeoJsonSource(sourceId, geojson, promoteId: promoteId);
    if (sourceId == _eewSourceId) await gate?.future;
  }
}

/// [AppTime] reads [DateTime.now], which a [FakeAsync] zone does not move.
/// The wavefront is measured against [AppTime], so the ticker tests install
/// a clock that follows [FakeAsync.elapsed]. Otherwise the radius sits still
/// and the pixel gate holds every tick.
FakeAsync? _fake;

class _ZoneClock implements Clock {
  @override
  DateTime now() {
    final fake = _fake;
    if (fake == null) return DateTime.now().toUtc();
    return fake
        .getClock(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        .now();
  }
}

void _during(void Function(FakeAsync async) body) {
  fakeAsync((async) {
    _fake = async;
    try {
      body(async);
    } finally {
      _fake = null;
    }
  });
}

class _UnusedServerTime implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => const Ok(0);
}

void _followFakeTime() {
  AppTime.install(
    ServerClock(_ZoneClock(), _FakeElapsed(), _UnusedServerTime()),
  );
}

void _restoreWallClock() {
  AppTime.install(
    ServerClock(const SystemClock(), _FakeElapsed(), _UnusedServerTime()),
  );
}

class _FakeClock implements Clock {
  _FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  void advance(Duration d) => value += d;
  @override
  Duration get elapsed => value;
}

class _FakeTicker implements Ticker {
  @override
  TickerHandle start(Duration interval, void Function() onTick) =>
      _NoopHandle();
}

class _NoopHandle implements TickerHandle {
  @override
  void cancel() {}
}

class _StaticSource<T> extends RealtimeSource<T> {
  _StaticSource(this.data);
  final T data;

  @override
  Future<Result<T>> fetch() async => Ok(data);

  @override
  DateTime? timestampOf(T value) => null;

  @override
  bool sameData(T? a, T? b) {
    if (a is List && b is List) return listEquals(a, b);
    return a == b;
  }
}

class _EmptyStations implements TremStationRepository {
  @override
  Future<Map<String, SeismicStation>?> saved() async => null;

  @override
  Future<Result<Map<String, SeismicStation>>> refresh() async =>
      const Ok(<String, SeismicStation>{});
}

Eew _alert({DateTime? time}) => Eew(
  agency: 'CWA',
  id: 'a',
  serial: 1,
  status: 0,
  isFinal: false,
  info: EewInfo(
    time: (time ?? DateTime.utc(2026, 8, 12, 12)).millisecondsSinceEpoch,
    longitude: 121.5,
    latitude: 23.5,
    depth: 10,
    magnitude: 6.0,
    location: '花蓮縣',
    max: 4,
  ),
);

RealtimeChannel<T> _channel<T>(
  T data,
  RealtimeConfig config,
  Elapsed elapsed,
) => RealtimeChannel<T>(
  source: _StaticSource<T>(data),
  clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
  elapsed: elapsed,
  ticker: _FakeTicker(),
  config: config,
  label: 'test',
);

Future<
  ({
    RtsMapLayer layer,
    RealtimeChannel<List<Eew>> eewChannel,
    RealtimeChannel<Rts> rtsChannel,
    _FakeElapsed rtsElapsed,
  })
>
_build({
  required List<Eew> alerts,
  required _FakeElapsed eewElapsed,
  Future<RenderTier>? renderTier,
}) async {
  final rtsElapsed = _FakeElapsed();
  final rtsChannel = _channel<Rts>(const Rts(), RealtimeConfig.rts, rtsElapsed);
  await rtsChannel.refreshNow();
  final eewChannel = _channel<List<Eew>>(
    alerts,
    RealtimeConfig.eew,
    eewElapsed,
  );
  await eewChannel.refreshNow();

  return (
    layer: RtsMapLayer(
      RealtimeNotifier<Rts>(rtsChannel),
      _EmptyStations(),
      eew: RealtimeNotifier<List<Eew>>(eewChannel),
      travelTimeTable: Future<SeismicTravelTimeTable>.value(
        const SeismicTravelTimeTable({
          0: [(p: 1, r: 5, s: 2), (p: 10, r: 50, s: 20)],
        }),
      ),
      boxGrid: Future<RtsBoxGrid>.value(const RtsBoxGrid({})),
      townDirectory: const TownDirectory({}),
      renderTier: renderTier,
    ),
    eewChannel: eewChannel,
    rtsChannel: rtsChannel,
    rtsElapsed: rtsElapsed,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a calm feed never re-uploads the empty collection', () async {
    final eewElapsed = _FakeElapsed();
    final built = await _build(alerts: const [], eewElapsed: eewElapsed);
    final controller = _EewRecordingController();

    await built.layer.render(controller);
    await pumpEventQueue(); // let the travel-time table land too
    expect(
      controller.eewPushes,
      isEmpty,
      reason: 'setupEew already seeded the source empty',
    );

    // The real driver: an RTS notification runs `_pushUpdate`, which ends with
    // an EEW push whether or not anything is happening. This is the ~1 Hz path
    // that was re-uploading the same empty collection all day.
    for (var i = 0; i < 20; i++) {
      built.rtsElapsed.advance(const Duration(seconds: 1));
      built.rtsChannel.recomputeStatus();
      eewElapsed.advance(const Duration(seconds: 1));
      built.eewChannel.recomputeStatus();
      await pumpEventQueue();
    }

    expect(
      controller.eewPushes,
      isEmpty,
      reason: 'an already-empty source must not be re-uploaded',
    );
  });

  test('a live alert is still pushed on every repaint', () async {
    final eewElapsed = _FakeElapsed();
    final built = await _build(alerts: [_alert()], eewElapsed: eewElapsed);
    final controller = _EewRecordingController();

    expect(
      built.eewChannel.state.status,
      RealtimeStatus.live,
      reason: 'the alert must be live for this test to mean anything',
    );

    await built.layer.render(controller);
    await pumpEventQueue();
    // More than one is expected and correct: the attach pushes once, and the
    // travel-time table resolving pushes again with the rings it unlocks. What
    // matters is that the guard never swallowed a live frame.
    expect(
      controller.eewPushes,
      isNotEmpty,
      reason: 'attaching with an alert up draws it',
    );
    for (final push in controller.eewPushes) {
      expect(
        push['features'] as List,
        isNotEmpty,
        reason: 'a live alert renders real geometry, not the empty collection',
      );
    }
  });

  test('the overlay is cleared once, when the alert ends', () async {
    final eewElapsed = _FakeElapsed();
    final built = await _build(alerts: [_alert()], eewElapsed: eewElapsed);
    final controller = _EewRecordingController();

    await built.layer.render(controller);
    await pumpEventQueue();
    controller.eewPushes.clear();

    // The feed ages out of `live`, so the wavefront must stop being presented
    // as current — exactly once, and then never again.
    eewElapsed.advance(const Duration(minutes: 5));
    built.eewChannel.recomputeStatus();
    await pumpEventQueue();
    expect(
      controller.eewPushes,
      hasLength(1),
      reason: 'the stale wavefront is cleared',
    );
    expect((controller.eewPushes.single['features'] as List), isEmpty);

    for (var i = 0; i < 10; i++) {
      eewElapsed.advance(const Duration(seconds: 1));
      built.eewChannel.recomputeStatus();
      await pumpEventQueue();
    }
    expect(
      controller.eewPushes,
      hasLength(1),
      reason: 'cleared stays cleared without further uploads',
    );
  });

  test(
    'a feed of only cancelled alerts draws nothing, like a calm one',
    () async {
      final eewElapsed = _FakeElapsed();
      final built = await _build(
        alerts: [_alert().copyWith(status: 3)],
        eewElapsed: eewElapsed,
      );
      final controller = _EewRecordingController();
      expect(built.eewChannel.state.status, RealtimeStatus.live);

      await built.layer.render(controller);
      await pumpEventQueue();
      for (var i = 0; i < 5; i++) {
        built.rtsElapsed.advance(const Duration(seconds: 1));
        built.rtsChannel.recomputeStatus();
        await pumpEventQueue();
      }

      expect(
        controller.eewPushes,
        isEmpty,
        reason: 'a cancelled alert has no wavefront to draw',
      );
    },
  );

  group('the wavefront ticker', () {
    setUp(_followFakeTime);
    tearDown(_restoreWallClock);

    /// Renders a live alert inside [async] and returns the layer, settled.
    RtsMapLayer attach(
      FakeAsync async,
      _EewRecordingController controller, {
      RenderTier? tier,
    }) {
      late RtsMapLayer layer;
      // Origin is this fake clock, so elapse grows the wave. The bundled
      // fixture would already be past the table and the radius would sit still.
      _build(
        // Two seconds in, the fixture is between its two rows and the
        // radius is actually moving. Before the first row it sits still.
        alerts: [
          _alert(time: _ZoneClock().now().subtract(const Duration(seconds: 2))),
        ],
        eewElapsed: _FakeElapsed(),
        renderTier: tier == null ? null : Future.value(tier),
      ).then((built) => layer = built.layer);
      async.flushMicrotasks();
      layer.render(controller);
      async.flushMicrotasks();
      return layer;
    }

    test('a sub-pixel step is not uploaded', () {
      _during((async) {
        final controller = _EewRecordingController();
        final layer = attach(async, controller);

        final before = controller.eewPushes.length;
        // At zoom 7 one pixel is about 560 m here (512 px tiles, 23.5°N);
        // this fixture moves about 400 m in 80 ms, under one pixel.
        async.elapse(const Duration(milliseconds: 16 * 5));
        expect(controller.eewPushes, hasLength(before));
        layer.clear(controller);
        async.flushMicrotasks();
      });
    });

    test('waits for the previous write instead of queueing behind it', () {
      _during((async) {
        final controller = _SlowEewController()..reportCamera(zoom: 14);
        final layer = attach(async, controller);

        final gate = controller.gate = Completer<void>();
        final before = controller.eewPushes.length;
        // Fifteen 16 ms ticks while the map is still busy with one write.
        async.elapse(const Duration(milliseconds: 16 * 15));
        expect(
          controller.eewPushes,
          hasLength(before + 1),
          reason: 'one write out, and every tick behind it skipped',
        );

        controller.gate = null;
        gate.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 16 * 3));
        expect(
          controller.eewPushes,
          hasLength(before + 4),
          reason: 'once it lands, every tick writes again',
        );
        layer.clear(controller);
        async.flushMicrotasks();
      });
    });

    test('treats a write that never answers as lost, not slow', () {
      _during((async) {
        final controller = _SlowEewController()..reportCamera(zoom: 14);
        final layer = attach(async, controller);

        controller.gate = Completer<void>(); // never completed
        final before = controller.eewPushes.length;
        async.elapse(const Duration(milliseconds: 1100));
        expect(
          controller.eewPushes,
          hasLength(before + 2),
          reason: 'a lost platform call must not freeze the rings for good',
        );
        layer.clear(controller);
        async.flushMicrotasks();
      });
    });

    test('a low-end phone redraws the rings five times a second', () {
      _during((async) {
        // Zoomed in until one 200 ms step of this wave is more than a pixel.
        // Farther out the pixel gate holds the tick and the count is not the
        // ticker rate.
        final controller = _EewRecordingController()..reportCamera(zoom: 14);
        final layer = attach(async, controller, tier: RenderTier.low);

        final before = controller.eewPushes.length;
        async.elapse(const Duration(seconds: 1));
        expect(controller.eewPushes, hasLength(before + 5));
        layer.clear(controller);
        async.flushMicrotasks();
      });
    });

    test('a low-end phone still gives up on a lost write after a second', () {
      _during((async) {
        final controller = _SlowEewController()..reportCamera(zoom: 14);
        final layer = attach(async, controller, tier: RenderTier.low);

        controller.gate = Completer<void>(); // never completed
        final before = controller.eewPushes.length;
        // A write at 200 ms, five skipped ticks behind it, a write at 1400.
        async.elapse(const Duration(milliseconds: 1300));
        expect(controller.eewPushes, hasLength(before + 1));
        async.elapse(const Duration(milliseconds: 100));
        expect(controller.eewPushes, hasLength(before + 2));
        layer.clear(controller);
        async.flushMicrotasks();
      });
    });

    test('writes on every tick while the map keeps up', () {
      _during((async) {
        final controller = _EewRecordingController()..reportCamera(zoom: 14);
        final layer = attach(async, controller);

        final before = controller.eewPushes.length;
        async.elapse(const Duration(milliseconds: 16 * 10));
        expect(controller.eewPushes, hasLength(before + 10));
        layer.clear(controller);
        async.flushMicrotasks();
      });
    });
  });
}
