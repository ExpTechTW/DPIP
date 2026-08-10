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

/// A trend whose first [n] minutes carry [values] then the rest of the hour is
/// dry — controls both the peak and where the rain stops.
RainHourTrend _trend(List<double> values) => RainHourTrend(
  startSecond: 0,
  mm: [...values, ...List<double>.filled(60 - values.length, 0)],
);

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

  group('summary', () {
    test('all-dry hour is none', () {
      final s = _trend(List.filled(60, 0)).summary;
      expect(s.grade, RainHourTrendGrade.none);
      expect(s.sustained, isFalse);
      expect(s.stopInMinutes, isNull);
    });

    test('peak below 5 mm is scattered', () {
      final s = _trend([0, 4.9, 0, 0, 0, 2.5]).summary;
      expect(s.grade, RainHourTrendGrade.scattered);
    });

    test('peak exactly 5 mm is light', () {
      final s = _trend([5]).summary;
      expect(s.grade, RainHourTrendGrade.light);
    });

    test('light rain that stops mid-hour reports the stop minute', () {
      // Rain through minute 20, dry after — stop is the minute after the last
      // wet sample.
      final s = _trend([for (var i = 0; i < 21; i++) 6.0]).summary;
      expect(s.grade, RainHourTrendGrade.light);
      expect(s.sustained, isFalse);
      expect(s.stopInMinutes, 21);
    });

    test('light rain still falling late in the hour is sustained', () {
      final values = List<double>.filled(51, 6.0); // wet through minute 50
      final s = _trend(values).summary;
      expect(s.grade, RainHourTrendGrade.light);
      expect(s.sustained, isTrue);
      expect(s.stopInMinutes, isNull);
    });

    test('peak at the light threshold (15 mm) is heavy', () {
      final s = _trend([15]).summary;
      expect(s.grade, RainHourTrendGrade.heavy);
    });

    test('heavy rain stopping mid-hour reports the stop minute', () {
      final s = _trend([for (var i = 0; i < 10; i++) 40.0]).summary;
      expect(s.grade, RainHourTrendGrade.heavy);
      expect(s.sustained, isFalse);
      expect(s.stopInMinutes, 10);
    });

    test('heavy rain continuing through the hour is sustained', () {
      final s = _trend(List.filled(60, 40.0)).summary;
      expect(s.grade, RainHourTrendGrade.heavy);
      expect(s.sustained, isTrue);
      expect(s.stopInMinutes, isNull);
    });
  });
}
