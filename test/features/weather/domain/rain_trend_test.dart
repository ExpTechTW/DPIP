/// [RainTrend] shares its decode shape with [WeatherTrend]: a delta-encoded
/// time axis restored to absolute Unix seconds, paired with one `-99`-sentinel
/// value series. A rain chart is the one place this matters most acutely — a
/// `-99` read as a literal value would plot negative rainfall, and a station
/// with a real gap (sensor offline) would be indistinguishable from a station
/// recording bone-dry zeros.
library;

import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decode restores the delta axis and maps -99 rainfall to null', () {
    final trend = RainTrend.decode({
      'id': 'C0A520',
      'range': '24h',
      'ts': [1700000000, 600, 600, 600],
      'rain': [0.0, 2.5, -99, 0.0],
    });

    expect(trend.id, 'C0A520');
    expect(trend.range, '24h');
    expect(trend.times, [1700000000, 1700000600, 1700001200, 1700001800]);
    expect(trend.rain, [0.0, 2.5, null, 0.0]);
  });

  test('a station with no samples yet decodes to two empty series', () {
    final trend = RainTrend.decode(const {'id': 'C0A520', 'range': '7d'});

    expect(trend.times, isEmpty);
    expect(trend.rain, isEmpty);
  });
}
