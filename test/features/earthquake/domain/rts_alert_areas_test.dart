/// The detection boxes and townships a frame's alerting stations light — the
/// `box` and `int` the server stopped sending and the client now derives.
///
/// Two rules carry the safety weight. Only an **alerting** station lights
/// anything: a calm station's noise must not put boxes across the island.
/// And an area takes its **strongest** station, so a weak station sharing a
/// box with a strong one cannot talk the box down.
library;

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_alert_areas.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:flutter_test/flutter_test.dart';

/// Box 1 covers 121.4–121.6 E × 23.4–23.6 N; box 2 sits well north of it.
const _grid = RtsBoxGrid({
  1: [
    [121.4, 23.4],
    [121.6, 23.4],
    [121.6, 23.6],
    [121.4, 23.6],
    [121.4, 23.4],
  ],
  2: [
    [121.4, 25.0],
    [121.6, 25.0],
    [121.6, 25.2],
    [121.4, 25.2],
    [121.4, 25.0],
  ],
});

const _stations = {
  'A': SeismicStation(
    id: 'A',
    latitude: 23.5,
    longitude: 121.5,
    townCode: '970',
  ),
  'B': SeismicStation(
    id: 'B',
    latitude: 23.45,
    longitude: 121.45,
    townCode: '971',
  ),
  'C': SeismicStation(
    id: 'C',
    latitude: 25.1,
    longitude: 121.5,
    townCode: '100',
  ),
  'SEA': SeismicStation(id: 'SEA', latitude: 22.0, longitude: 120.0),
};

void main() {
  final areas = stationAreas(_stations, _grid);

  test(
    'the ray cast places a point in its box, and outside every box as null',
    () {
      expect(_grid.boxAt(23.5, 121.5), 1);
      expect(_grid.boxAt(25.1, 121.5), 2);
      expect(_grid.boxAt(24.0, 121.5), isNull);
      expect(areas['SEA'], (box: null, town: null));
    },
  );

  test('only alerting stations light anything', () {
    final lit = rtsAlertAreas({
      'A': const RtsStation(intensity: 4.0),
      'C': const RtsStation(intensity: 3.0),
    }, areas);

    expect(lit.boxes, isEmpty);
    expect(lit.towns, isEmpty);
    expect(identical(lit, RtsAlertAreas.none), isTrue);
  });

  test('an area takes the strongest of its alerting stations', () {
    final lit = rtsAlertAreas({
      'A': const RtsStation(intensity: 1.2, alert: true),
      'B': const RtsStation(intensity: 4.7, alert: true),
      'C': const RtsStation(intensity: 2.4, alert: true),
    }, areas);

    // 4.7 is 5弱 — scale 5 — and outranks A's 1 in the shared box.
    expect(lit.boxes, {1: 5, 2: 2});
    expect(lit.towns, {'970': 1, '971': 5, '100': 2});
  });

  test('a station missing from the directory lights nothing', () {
    final lit = rtsAlertAreas({
      'UNKNOWN': const RtsStation(intensity: 5.0, alert: true),
    }, areas);

    expect(lit.boxes, isEmpty);
    expect(lit.towns, isEmpty);
  });

  test('an alerting station outside the grid still lights its township', () {
    final lit = rtsAlertAreas(
      {'X': const RtsStation(intensity: 2.0, alert: true)},
      stationAreas({
        'X': const SeismicStation(
          id: 'X',
          latitude: 22.0,
          longitude: 120.0,
          townCode: '900',
        ),
      }, _grid),
    );

    expect(lit.boxes, isEmpty);
    expect(lit.towns, {'900': 2});
  });
}
