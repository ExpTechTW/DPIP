import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic 0-km table: P reaches 5 km in 1 s, S in 2 s; at 5 s both fronts
/// interpolate well inside the table.
const SeismicTravelTimeTable _table = SeismicTravelTimeTable({
  0: [(p: 1, r: 5, s: 2), (p: 10, r: 50, s: 20)],
});

Eew _alert({
  String id = 'a',
  required DateTime origin,
  double longitude = 121.5,
  double latitude = 23.5,
  String location = '花蓮縣',
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
    location: location,
    max: 4,
  ),
);

void main() {
  test('no alerts renders an empty collection', () {
    final geo = eewWaveGeoJson(const [], _table, DateTime.utc(2026, 1, 1));
    expect(geo['features'], isEmpty);
  });

  test(
    'the epicentre cross renders even before the travel-time table resolves',
    () {
      final geo = eewWaveGeoJson(
        [_alert(origin: DateTime.utc(2026, 1, 1))],
        null,
        DateTime.utc(2026, 1, 1, 0, 0, 5),
      );
      final features = geo['features'] as List;
      expect(features, hasLength(1));
      expect(features.single['properties']['type'], 'x');
    },
  );

  test('an alert past its origin draws the P/S rings and the cross', () {
    final origin = DateTime.utc(2026, 1, 1);
    final geo = eewWaveGeoJson(
      [_alert(origin: origin)],
      _table,
      origin.add(const Duration(seconds: 5)),
    );
    final features = geo['features'] as List;
    expect(features, hasLength(4));
    expect(features.map((f) => f['properties']['type']).toSet(), {
      'p-line',
      's-fill',
      's-line',
      'x',
    });
  });

  test('a not-yet-originated report draws only the cross — no wavefront that '
      'hasn’t started', () {
    final origin = DateTime.utc(2026, 1, 1);
    final geo = eewWaveGeoJson(
      [_alert(origin: origin.add(const Duration(seconds: 60)))],
      _table,
      origin,
    );
    final features = geo['features'] as List;
    expect(features, hasLength(1));
    expect(features.single['properties']['type'], 'x');
  });

  test('every active alert renders (multi-report)', () {
    final origin = DateTime.utc(2026, 1, 1);
    final geo = eewWaveGeoJson(
      [
        _alert(id: 'a', origin: origin, longitude: 121.0),
        _alert(id: 'b', origin: origin, longitude: 122.0),
      ],
      _table,
      origin.add(const Duration(seconds: 5)),
    );
    final features = geo['features'] as List;
    expect(features, hasLength(8));
    expect(features.where((f) => f['properties']['type'] == 'x'), hasLength(2));
  });
}
