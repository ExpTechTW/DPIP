/// A station's weather trend chart is five parallel arrays index-aligned to
/// one delta-encoded time axis. Two failure modes are easy to introduce and
/// invisible in a quick look at the code: restoring `ts` as raw deltas
/// instead of a running sum would compress the whole x-axis into the first
/// few seconds, and reading `-99` as a real value instead of the v5 missing
/// sentinel would plot a station reporting a 99-degree, -99% humidity hour
/// instead of leaving a gap in the chart.
library;

import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decode restores the delta axis and maps -99 to null per series', () {
    final trend = WeatherTrend.decode({
      'id': 'C0A520',
      'range': '24h',
      'ts': [1700000000, 3600, 3600],
      'temp': [28.5, -99, 27.9],
      'rh': [80, -99, 78],
      'pres': [1008.2, 1007.9, -99],
      'wspd': [2.1, -99, 3.4],
      'wdir': [180, -99, 200],
    });

    expect(trend.id, 'C0A520');
    expect(trend.range, '24h');
    expect(trend.times, [1700000000, 1700003600, 1700007200]);
    expect(trend.temperature, [28.5, null, 27.9]);
    expect(trend.humidity, [80, null, 78]);
    expect(trend.pressure, [1008.2, 1007.9, null]);
    expect(trend.windSpeed, [2.1, null, 3.4]);
    expect(trend.windDirection, [180, null, 200]);
  });

  test('a station with no samples yet decodes to five empty series', () {
    final trend = WeatherTrend.decode(const {'id': 'C0A520', 'range': '7d'});

    expect(trend.times, isEmpty);
    expect(trend.temperature, isEmpty);
    expect(trend.humidity, isEmpty);
    expect(trend.pressure, isEmpty);
    expect(trend.windSpeed, isEmpty);
    expect(trend.windDirection, isEmpty);
  });
}
