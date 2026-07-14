import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RainSnapshot.decode aligns the 9 windows and maps -99 → null', () {
    final snapshot = RainSnapshot.decode(const {
      'time': 1784019000,
      'ids': ['C1I230', 'X'],
      'now': [0, 0],
      '10m': [0, 0],
      '1h': [0, 0.5],
      '3h': [0, 2],
      '6h': [0, 5],
      '12h': [0, 12],
      '24h': [129.5, -99],
      '2d': [129.5, 0],
      '3d': [130.5, 0],
    });

    expect(snapshot.time, 1784019000);
    expect(snapshot.stations, hasLength(2));
    final first = snapshot.stations.first;
    expect(first.id, 'C1I230');
    expect(first.hour24, 129.5);
    expect(first.day3, 130.5);
    expect(snapshot.stations[1].hour1, 0.5);
    expect(snapshot.stations[1].hour24, isNull, reason: '-99 → null');
  });
}
