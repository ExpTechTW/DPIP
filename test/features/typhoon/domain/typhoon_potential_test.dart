import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TyphoonPotential.decode swaps [lng,lat] → LatLng(lat,lng)', () {
    final potential = TyphoonPotential.decode(const {
      'updated': 1783987200,
      'name': 'TD11',
      'past': [
        [136.7, 10.7],
        [136.5, 11.0],
      ],
      'forecast': [
        [134.5, 12.7],
      ],
      'cone': [
        [134.54, 12.72],
      ],
      'circle': null,
      'current': [134.5, 12.7],
      'points': [
        {'label': '07月14日14時', 'lng': 135.0, 'lat': 13.3},
      ],
    });

    expect(potential.name, 'TD11');
    expect(potential.past, hasLength(2));
    // [136.7, 10.7] is [lng, lat] → latitude 10.7, longitude 136.7.
    expect(potential.past.first.latitude, 10.7);
    expect(potential.past.first.longitude, 136.7);
    expect(potential.current, const LatLng(12.7, 134.5));
    expect(potential.circle, isNull, reason: 'too weak → null');
    expect(potential.points.single.latitude, 13.3);
    expect(potential.points.single.longitude, 135.0);
    expect(potential.points.single.label, '07月14日14時');
  });

  test('empty geometry decodes to empty lists and nulls', () {
    final potential = TyphoonPotential.decode(const {
      'updated': 1,
      'past': <dynamic>[],
      'forecast': <dynamic>[],
      'cone': <dynamic>[],
      'points': <dynamic>[],
    });
    expect(potential.past, isEmpty);
    expect(potential.current, isNull);
    expect(potential.name, isNull);
  });
}
