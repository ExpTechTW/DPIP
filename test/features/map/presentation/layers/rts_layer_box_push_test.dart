/// Pins how often [RtsMapLayer] re-uploads a large event's detection boxes.
///
/// The wavefront ticker repaints at display rate while an alert is live and
/// ends every tick with a box push. The grid it draws only changes when the
/// feed's box set changes or the S wave sweeps a box out, so every other tick
/// used to serialise the same polygons, ship them across the platform channel
/// and make MapLibre re-tile them — sixty times a second, during an
/// earthquake. The guard is on the *content*: an identical collection is not
/// sent again, a changed one always is.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

const String _boxSourceId = 'rts-box-src';

class _BoxRecordingController extends RecordingMapController {
  final List<Map<String, dynamic>> boxPushes = [];

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {
    if (sourceId == _boxSourceId) boxPushes.add(geojson);
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

/// A source whose answer the test can change between refreshes.
class _MutableSource extends RealtimeSource<Rts> {
  Rts data = const Rts();

  @override
  Future<Result<Rts>> fetch() async => Ok(data);

  @override
  DateTime? timestampOf(Rts value) => null;

  @override
  bool sameData(Rts? a, Rts? b) => a == b;
}

class _EmptyStations implements TremStationRepository {
  @override
  Future<Result<Map<String, SeismicStation>>> stations() async =>
      const Ok(<String, SeismicStation>{});
}

/// A square box around Hualien — four corners, `[lng, lat]`, then closed.
const List<List<double>> _ring = [
  [121.5, 23.5],
  [121.6, 23.5],
  [121.6, 23.6],
  [121.5, 23.6],
  [121.5, 23.5],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an unchanged box collection is uploaded once, not per tick', () async {
    final source = _MutableSource()..data = const Rts(box: {'7': 4});
    final rtsChannel = RealtimeChannel<Rts>(
      source: source,
      clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
      elapsed: _FakeElapsed(),
      ticker: _FakeTicker(),
      config: RealtimeConfig.rts,
      label: 'rts',
    );
    await rtsChannel.refreshNow();
    final eewChannel = RealtimeChannel<List<Eew>>(
      source: _StaticEew(),
      clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
      elapsed: _FakeElapsed(),
      ticker: _FakeTicker(),
      config: RealtimeConfig.eew,
      label: 'eew',
    );
    await eewChannel.refreshNow();
    final layer = RtsMapLayer(
      RealtimeNotifier<Rts>(rtsChannel),
      _EmptyStations(),
      eew: RealtimeNotifier<List<Eew>>(eewChannel),
      travelTimeTable: Future<SeismicTravelTimeTable>.value(
        const SeismicTravelTimeTable({
          0: [(p: 1, r: 5, s: 2), (p: 10, r: 50, s: 20)],
        }),
      ),
      boxGrid: Future<RtsBoxGrid>.value(const RtsBoxGrid({7: _ring})),
      townDirectory: const TownDirectory({}),
    );
    final controller = _BoxRecordingController();

    await layer.render(controller);
    await pumpEventQueue(); // the grid future lands and pushes once
    final afterAttach = controller.boxPushes.length;
    expect(afterAttach, greaterThan(0), reason: 'attaching draws the box');

    // The same feed snapshot notifying again (status recompute, or the
    // display-rate wavefront tick) must not re-send identical polygons.
    for (var i = 0; i < 20; i++) {
      rtsChannel.recomputeStatus();
      await pumpEventQueue();
    }
    expect(
      controller.boxPushes.length,
      afterAttach,
      reason: 'identical box geometry is not re-uploaded',
    );

    // A genuinely different set is.
    source.data = const Rts(box: {'7': 6});
    await rtsChannel.refreshNow();
    await pumpEventQueue();
    expect(
      controller.boxPushes.length,
      afterAttach + 1,
      reason: 'a changed intensity is a new collection',
    );
    final last = controller.boxPushes.last['features'] as List;
    expect((last.single as Map)['properties'], {'i': 6});

    await layer.clear(controller);
  });
}

class _StaticEew extends RealtimeSource<List<Eew>> {
  @override
  Future<Result<List<Eew>>> fetch() async => const Ok(<Eew>[]);

  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) =>
      (a?.isEmpty ?? true) && (b?.isEmpty ?? true);
}
