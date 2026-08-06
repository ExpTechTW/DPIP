import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PotentialPayload.decode multi-storm cyclones[]', () {
    final payload = PotentialPayload.decode(const {
      'updated': 1783987200,
      'cyclones': [
        {
          'tdNo': '14',
          'name': '白海豚',
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
        },
        {
          'tdNo': '15',
          'name': 'TD15',
          'past': [
            [119.0, 16.5],
          ],
          'forecast': <dynamic>[],
          'cone': <dynamic>[],
          'circle': null,
          'current': [118.4, 16.4],
          'points': <dynamic>[],
        },
      ],
    });

    expect(payload.updated, 1783987200);
    expect(payload.cyclones, hasLength(2));
    final dolphin = payload.cyclones.first;
    expect(dolphin.tdNo, '14');
    expect(dolphin.name, '白海豚');
    expect(dolphin.past.first.latitude, 10.7);
    expect(dolphin.past.first.longitude, 136.7);
    expect(dolphin.current, const LatLng(12.7, 134.5));
    expect(dolphin.circle, isNull);
    expect(dolphin.points.single.label, '07月14日14時');
    expect(payload.cyclones[1].tdNo, '15');
  });

  test('PotentialPayload.decode ignores legacy flat payload', () {
    final payload = PotentialPayload.decode(const {
      'updated': 1,
      'name': 'TD11',
      'past': <dynamic>[],
      'forecast': <dynamic>[],
      'cone': <dynamic>[],
      'points': <dynamic>[],
    });
    expect(payload.cyclones, isEmpty);
  });
}
