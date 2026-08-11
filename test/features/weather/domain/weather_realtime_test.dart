/// Decoding tests for the nearest-station realtime observation — chiefly the
/// id normalisation: the API returns the 5-char station code, which must pad
/// to the `/station` directory's 6-char key so the station sheet / `trend`
/// lookups address the same key space as every other weather source.
library;

import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a 5-char realtime id pads to the 6-char station directory key', () {
    final realtime = WeatherRealtime.fromJson({
      'id': 'C0X16',
      'station': {
        'name': '仁德',
        'lat': 22.9683,
        'lon': 120.2577,
        'altitude': 26,
        'distance': 0.81,
      },
      'time': 0,
      'data': {
        'weather': '陰',
        'weatherCode': 300,
        'wind': {'speed': -99, 'beaufort': -99},
        'gust': {'speed': -99, 'beaufort': -99},
      },
    });

    expect(realtime.id, 'C0X160');
  });

  test('an already-6-char id is left untouched', () {
    final realtime = WeatherRealtime.fromJson({
      'id': '467410',
      'station': {
        'name': '臺南',
        'lat': 23.0,
        'lon': 120.2,
        'altitude': 40,
        'distance': 1.2,
      },
      'time': 0,
      'data': {
        'weather': '晴',
        'weatherCode': 100,
        'wind': {'speed': -99, 'beaufort': -99},
        'gust': {'speed': -99, 'beaufort': -99},
      },
    });

    expect(realtime.id, '467410');
  });
}
