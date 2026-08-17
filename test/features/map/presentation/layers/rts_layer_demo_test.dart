/// 強震監視器 (RTS) — through-the-layer integration test.
///
/// Wires a real [RealtimeChannel] per feed into [RtsMapLayer] exactly as the
/// map page does, records the GeoJSON actually handed to MapLibre, and checks
/// that a large event's data is complete: stations, EEW wavefront, and the
/// box grid — with the swept boxes correctly dropped.
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
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

const String _eewSourceId = 'rts-eew-src';
const String _boxSourceId = 'rts-box-src';
const String _rtsSourceId = 'rts-src';

/// Records the GeoJSON handed to each of the three map sources.
class _RecordingController extends RecordingMapController {
  final List<Map<String, dynamic>> eewPushes = [];
  final List<Map<String, dynamic>> boxPushes = [];
  final List<Map<String, dynamic>> rtsPushes = [];

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {
    switch (sourceId) {
      case _eewSourceId:
        eewPushes.add(geojson);
      case _boxSourceId:
        boxPushes.add(geojson);
      case _rtsSourceId:
        rtsPushes.add(geojson);
    }
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
  T data;
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

/// A small real station directory so GeoJSON features actually get built.
class _Stations implements TremStationRepository {
  @override
  Future<Result<Map<String, SeismicStation>>> stations() async => const Ok({
    'TWD001': SeismicStation(id: 'TWD001', latitude: 25.03, longitude: 121.56),
    'TWD002': SeismicStation(id: 'TWD002', latitude: 23.8, longitude: 121.0),
    'TWD003': SeismicStation(id: 'TWD003', latitude: 24.5, longitude: 121.3),
  });
}

Eew _alert({
  String id = 'a',
  required DateTime origin,
  double longitude = 121.5,
  double latitude = 23.5,
}) => Eew(
  agency: 'CWA',
  id: id,
  serial: 1,
  status: 0,
  isFinal: false,
  info: EewInfo(
    time: origin.millisecondsSinceEpoch,
    longitude: longitude,
    latitude: latitude,
    depth: 10,
    magnitude: 6.0,
    location: '花蓮縣',
    max: 4,
  ),
);

Future<
  ({
    RtsMapLayer layer,
    RealtimeNotifier<Rts> rts,
    RealtimeNotifier<List<Eew>> eew,
    _StaticSource<Rts> rtsSource,
    RealtimeChannel<Rts> rtsChannel,
  })
>
_build({
  Rts rts = const Rts(),
  List<Eew> alerts = const [],
  required SeismicTravelTimeTable table,
  required RtsBoxGrid grid,
}) async {
  final rtsElapsed = _FakeElapsed();
  final clock = _FakeClock(DateTime.utc(2026, 8, 12, 12));
  final rtsSource = _StaticSource<Rts>(rts);
  final rtsChannel = RealtimeChannel<Rts>(
    source: rtsSource,
    clock: clock,
    elapsed: rtsElapsed,
    ticker: _FakeTicker(),
    config: RealtimeConfig.rts,
    label: 'test-rts',
  );
  await rtsChannel.refreshNow();

  final eewElapsed = _FakeElapsed();
  final eewSource = _StaticSource<List<Eew>>(alerts);
  final eewChannel = RealtimeChannel<List<Eew>>(
    source: eewSource,
    clock: clock,
    elapsed: eewElapsed,
    ticker: _FakeTicker(),
    config: RealtimeConfig.eew,
    label: 'test-eew',
  );
  await eewChannel.refreshNow();

  return (
    layer: RtsMapLayer(
      RealtimeNotifier<Rts>(rtsChannel),
      _Stations(),
      eew: RealtimeNotifier<List<Eew>>(eewChannel),
      travelTimeTable: Future<SeismicTravelTimeTable>.value(table),
      boxGrid: Future<RtsBoxGrid>.value(grid),
      townDirectory: const TownDirectory({}),
    ),
    rts: RealtimeNotifier<Rts>(rtsChannel),
    eew: RealtimeNotifier<List<Eew>>(eewChannel),
    rtsSource: rtsSource,
    rtsChannel: rtsChannel,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A broadband table so a box swept at *any* reasonable attach-time elapsed is
  // deterministically dropped / kept regardless of the device clock (the layer
  // measures against AppTime.utc). Box 1 hugs the epicentre — the S wave
  // reaches it within seconds — while box 2 sits far beyond the table's
  // farthest S radius, so it can never be swept within any test duration.
  final table = SeismicTravelTimeTable({
    10: [
      (p: 1, r: 1, s: 2),
      (p: 60, r: 300, s: 120),
      (p: 240, r: 1500, s: 480),
    ],
  });
  final grid = const RtsBoxGrid({
    // Box 1: 0.2°×0.2° cell around (121.5, 23.5) — every corner ~15–25 km
    // from the epicentre, so the S wave covers it within its first minute.
    1: [
      [121.4, 23.4],
      [121.6, 23.4],
      [121.6, 23.6],
      [121.4, 23.6],
      [121.4, 23.4],
    ],
    // Box 2: far northeast, ~230 km from the epicentre, beyond the table's
    // farthest S radius (1500 km takes 480 s) — immune to clock skew.
    2: [
      [121.8, 25.4],
      [122.0, 25.4],
      [122.0, 25.6],
      [121.8, 25.6],
      [121.8, 25.4],
    ],
  });

  List<Map<String, dynamic>> featuresOf(List<Map<String, dynamic>> pushes) => [
    for (final push in pushes)
      for (final feature in push['features'] as List)
        feature as Map<String, dynamic>,
  ];

  test('a clean, closed scene reaches all three map sources', () async {
    // A just-published event: origin a few seconds before "now" (the layer
    // measures elapsed against AppTime.utc — device clock in tests).
    //
    // 60s so the S wave front has grown well past box 1 (>~40 km) but is still
    // far short of box 2 (>~220 km) whatever the precise elapsed is.
    final origin = DateTime.now().toUtc().subtract(const Duration(seconds: 60));
    final built = await _build(
      rts: Rts(
        time: origin.millisecondsSinceEpoch,
        box: {'1': 4, '2': 3},
        station: {
          'TWD001': const RtsStation(
            pga: 40,
            pgv: 8,
            intensityRaw: 4.0,
            intensity: 4.0,
            alert: true,
          ),
          'TWD002': const RtsStation(
            pga: 10,
            pgv: 2,
            intensityRaw: 1.5,
            intensity: 1.5,
          ),
        },
      ),
      alerts: [_alert(origin: origin)],
      table: table,
      grid: grid,
    );
    final controller = _RecordingController();
    await built.layer.render(controller);
    await pumpEventQueue(); // travel-time table + box grid resolve

    // Overlay: the closed EEW geometry — cross, both wavefronts, the S disc.
    final eew = featuresOf(controller.eewPushes);
    expect(eew, isNotEmpty, reason: 'a live alert must draw geometry');
    final eewTypes = eew.map((f) => f['properties']['type']).toSet();
    expect(eewTypes, containsAll({'x', 'p-line', 's-line', 's-fill'}));

    // The box grid: the box already swept by the S wave is dropped, the far
    // box still outside the wavefront stays.
    expect(
      controller.boxPushes,
      isNotEmpty,
      reason: 'box data must reach the map',
    );
    final drawn = featuresOf(controller.boxPushes);
    final boxIds = drawn.map((f) => f['properties']['i']).toSet();
    expect(boxIds, isNot(contains(4)), reason: 'swept box must be dropped');
    expect(
      boxIds,
      contains(3),
      reason: 'the untouched far box must stay drawn',
    );

    // Station dots: both live stations are present as features…
    final dots = featuresOf(controller.rtsPushes);
    expect(dots, hasLength(2));
    // …and each carries the shake values the layer re-publishes.
    for (final dot in dots) {
      final i = dot['properties']['i'] as num;
      expect(i, greaterThan(0));
    }
  });

  test('a large event without EEW still draws its box grid', () async {
    final original = DateTime.now().toUtc().subtract(
      const Duration(seconds: 5),
    );
    final built = await _build(
      rts: Rts(
        time: original.millisecondsSinceEpoch,
        box: {'1': 4, '2': 3},
        station: {
          'TWD001': const RtsStation(
            pga: 40,
            pgv: 8,
            intensityRaw: 4.0,
            intensity: 4.0,
            alert: true,
          ),
        },
      ),
      alerts: const [],
      table: table,
      grid: grid,
    );
    final controller = _RecordingController();
    await built.layer.render(controller);
    await pumpEventQueue();

    // No EEW → no overlay, but the boxes must still reach the map.
    expect(controller.eewPushes, isEmpty);
    expect(controller.boxPushes, isNotEmpty);

    final drawn = featuresOf(controller.boxPushes);
    expect(
      drawn.any((f) => f['properties']['i'] == 3),
      isTrue,
      reason: 'a far box must be drawn even without an EEW alert',
    );
  });

  test(
    "a large event's box grid never swaps station dots for square badges",
    () async {
      // Real-time instrumental readings (this feed's per-station `i`) are
      // always circles — the discrete-intensity square badges are
      // 震度速報/地震報告 artwork for a different data product, and the legacy
      // monitor's habit of swapping to them whenever `rts.box` had data was
      // never correct for live station dots (see the layer's class doc).
      final origin = DateTime.now().toUtc().subtract(
        const Duration(seconds: 5),
      );
      final built = await _build(
        rts: Rts(
          time: origin.millisecondsSinceEpoch,
          box: {'1': 4, '2': 3},
          station: {
            'TWD001': const RtsStation(
              pga: 40,
              pgv: 8,
              intensityRaw: 4.0,
              intensity: 4.0,
              alert: true,
            ),
          },
        ),
        alerts: const [],
        table: table,
        grid: grid,
      );
      final controller = _RecordingController();
      await built.layer.render(controller);
      await pumpEventQueue();

      expect(
        controller.calls,
        isNot(contains('setLayerVisibility:rts-circle:false')),
        reason: 'a box-grid event must never hide the live station dots',
      );
      expect(
        controller.visibilityOf('rts-circle'),
        isNot('none'),
        reason: 'station dots stay visible through a large event',
      );
      expect(
        controller.calls,
        isNot(contains('addSymbolLayer:rts-intensity')),
        reason:
            'the square discrete-intensity badge layer must not exist — '
            '"rts-intensity-circle" (the circular badge) is a different, '
            'legitimate layer this check must not false-positive on',
      );
    },
  );

  test('the epicentre cross stacks above the box grid, which stacks above the '
      'station dots — matching the legacy monitor', () async {
    final origin = DateTime.now().toUtc().subtract(const Duration(seconds: 5));
    final built = await _build(
      rts: Rts(
        time: origin.millisecondsSinceEpoch,
        box: {'1': 4, '2': 3},
        station: const {
          'TWD001': RtsStation(
            pga: 40,
            pgv: 8,
            intensityRaw: 4.0,
            intensity: 4.0,
            alert: true,
          ),
        },
      ),
      alerts: [_alert(origin: origin)],
      table: table,
      grid: grid,
    );
    final controller = _RecordingController();
    await built.layer.render(controller);
    await pumpEventQueue();

    expect(
      controller.isAbove('rts-eew-epicenter', 'rts-box-line'),
      isTrue,
      reason: 'the epicentre must never be buried under the detection-box grid',
    );
    expect(
      controller.isAbove('rts-box-line', 'rts-circle'),
      isTrue,
      reason: 'the box grid must still sit above the plain station dots',
    );
  });

  test(
    'a large event declutters to shaking stations, badged with the discrete '
    'reading on a circle — legacy behaviour, ported without the square badge',
    () async {
      final origin = DateTime.now().toUtc().subtract(
        const Duration(seconds: 5),
      );
      final built = await _build(
        rts: Rts(
          time: origin.millisecondsSinceEpoch,
          box: {'1': 4},
          station: const {
            // Shaking and alerting — must stay, badged with its discrete
            // reading (matching the legacy badge's number, minus the square).
            'TWD001': RtsStation(
              pga: 40,
              pgv: 8,
              intensityRaw: 4.0,
              intensity: 4.0,
              alert: true,
            ),
            // Calm and not alerting — must drop out entirely, or a big event
            // paints the whole island in identical dots and buries where the
            // shaking actually is.
            'TWD002': RtsStation(
              pga: 0,
              pgv: 0,
              intensityRaw: 0.0,
              intensity: 0.0,
              alert: false,
            ),
            // Alerting but reading a flat 0 — stays on the map (unlike
            // TWD002) but as a plain grey dot, not a numbered badge: the
            // legacy monitor's separate `intensity0` layer painted exactly
            // this case grey rather than the continuous ramp's near-zero
            // pale colour.
            'TWD003': RtsStation(
              pga: 0,
              pgv: 0,
              intensityRaw: 0.0,
              intensity: 0.0,
              alert: true,
            ),
          },
        ),
        alerts: const [],
        table: table,
        grid: grid,
      );
      final controller = _RecordingController();
      await built.layer.render(controller);
      await pumpEventQueue();

      final drawn = featuresOf(controller.rtsPushes);
      expect(
        drawn,
        hasLength(2),
        reason: 'the calm, non-alerting station must be decluttered away',
      );
      final byLabel = {
        for (final f in drawn) (f['properties']! as Map)['label']: f,
      };
      // The badge carries the number — the plain "id\nreading" label is
      // untouched, so the station is never left unidentified.
      expect(byLabel['TWD001\n4.0']!['properties']['icon'], 'circle-4');
      expect(byLabel['TWD001\n4.0']!['properties']['grey'], 0);
      expect(byLabel['TWD003\n0.0']!['properties']['icon'], '');
      expect(byLabel['TWD003\n0.0']!['properties']['grey'], 1);
    },
  );

  test(
    'the sort key follows the alert-aware reading, not the raw sensor value',
    () async {
      final origin = DateTime.now().toUtc().subtract(
        const Duration(seconds: 5),
      );
      final built = await _build(
        rts: Rts(
          time: origin.millisecondsSinceEpoch,
          box: {'1': 4},
          station: const {
            // Alerting: the broadcast discrete reading (6.0, a high badge)
            // far outranks this station's own, much lower raw sensor value
            // (-1.0) — the badge must draw above TWD002 regardless, so its
            // sort key has to track the discrete reading, not the raw one.
            'TWD001': RtsStation(
              pga: 40,
              pgv: 8,
              intensityRaw: -1.0,
              intensity: 6.0,
              alert: true,
            ),
            // Not alerting: sorts on its own raw value, same as always.
            'TWD002': RtsStation(
              pga: 20,
              pgv: 4,
              intensityRaw: 3.0,
              intensity: 0.0,
              alert: false,
            ),
          },
        ),
        alerts: const [],
        table: table,
        grid: grid,
      );
      final controller = _RecordingController();
      await built.layer.render(controller);
      await pumpEventQueue();

      final drawn = featuresOf(controller.rtsPushes);
      final byLabel = {
        for (final f in drawn) (f['properties']! as Map)['label']: f,
      };
      expect(byLabel['TWD001\n-1.0']!['properties']['sort'], 6.0);
      expect(byLabel['TWD002\n3.0']!['properties']['sort'], 3.0);
    },
  );
}
