import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every window reads its own column and wire key', () {
    const observation = RainObservation(
      id: 'C0A001',
      now: 1,
      min10: 2,
      hour1: 3,
      hour3: 4,
      hour6: 5,
      hour12: 6,
      hour24: 7,
      day2: 8,
      day3: 9,
    );
    expect(
      {
        for (final interval in RainInterval.values)
          interval.apiKey: interval.valueOf(observation),
      },
      {
        'now': 1,
        '10m': 2,
        '1h': 3,
        '3h': 4,
        '6h': 5,
        '12h': 6,
        '24h': 7,
        '2d': 8,
        '3d': 9,
      },
    );
  });
}
