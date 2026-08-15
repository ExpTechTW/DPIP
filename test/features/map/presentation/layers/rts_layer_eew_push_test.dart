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
/// free; skipping a *live* one is not, because the wavefront geometry is a
/// function of the calibrated clock — every tick genuinely differs, and a
/// dropped one is a ring that stops expanding during an earthquake.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
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
  Future<Result<Map<String, SeismicStation>>> stations() async =>
      const Ok(<String, SeismicStation>{});
}

Eew _alert() => Eew(
  agency: 'CWA',
  id: 'a',
  serial: 1,
  status: 0,
  isFinal: false,
  info: EewInfo(
    time: DateTime.utc(2026, 8, 12, 12).millisecondsSinceEpoch,
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
_build({required List<Eew> alerts, required _FakeElapsed eewElapsed}) async {
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
}
