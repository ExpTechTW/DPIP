import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:flutter_test/flutter_test.dart';

/// A full 60-sample rain array (the wire contract), with the first few entries
/// set to [leading] so a decode can be inspected.
List<dynamic> _rain60(List<int> leading) {
  final rain = List<int>.filled(60, 0);
  for (var i = 0; i < leading.length; i++) {
    rain[i] = leading[i];
  }
  return rain;
}

void main() {
  test('decode reads the first non-empty rainforecast series', () {
    final trend = RainHourTrend.decode({
      'rainfallWarnings-rkai': [
        {
          'start': 1786362600,
          'rain': _rain60(const [6, 5, 4]),
        },
      ],
      'rainfallWarnings-other': [
        {'start': 1, 'rain': <dynamic>[]},
      ],
    });

    expect(trend.startSecond, 1786362600);
    expect(trend.mm, hasLength(60));
    expect(trend.mm.sublist(0, 3), [6.0, 5.0, 4.0]);
    expect(trend.mm.sublist(3), everyElement(0.0));
  });

  test('decode aligns an empty response to FormatException', () {
    expect(() => RainHourTrend.decode(const {}), throwsFormatException);
  });

  test('decode skips empty series before the real one', () {
    final trend = RainHourTrend.decode({
      'empty': <dynamic>[],
      'real': [
        {
          'start': 10,
          'rain': _rain60(const [1]),
        },
      ],
    });

    expect(trend.startSecond, 10);
  });

  test('decode rejects a non-numeric start', () {
    expect(
      () => RainHourTrend.decode({
        's': [
          {
            'start': 'now',
            'rain': _rain60(const [1]),
          },
        ],
      }),
      throwsFormatException,
    );
  });

  test('decode rejects a wrong sample count', () {
    expect(
      () => RainHourTrend.decode(const {
        's': [
          {
            'start': 10,
            'rain': [1, 2],
          },
        ],
      }),
      throwsFormatException,
    );
  });

  test('decode rejects a malformed series entry', () {
    expect(
      () => RainHourTrend.decode(const {
        's': [42],
      }),
      throwsFormatException,
    );
  });
}
