import 'package:dpip/core/weather/solar_time.dart';
import 'package:flutter_test/flutter_test.dart';

const _latitude = 23.75;
const _longitude = 121.0;
const _utcOffsetHours = 8.0;
const _utcOffset = Duration(hours: 8);

bool _isNight(DateTime instant) {
  return isNightAt(
    instant,
    latitude: _latitude,
    longitude: _longitude,
    utcOffsetHours: _utcOffsetHours,
  );
}

DateTime _nextTransition(DateTime instant) {
  return nextDayNightTransitionAt(
    instant,
    latitude: _latitude,
    longitude: _longitude,
    utcOffsetHours: _utcOffsetHours,
  );
}

DateTime _localInstant(
  int year,
  int month,
  int day,
  int hour, [
  int minute = 0,
]) {
  return DateTime.utc(year, month, day, hour, minute).subtract(_utcOffset);
}

({DateTime sunrise, DateTime sunset}) _canonicalSunTransitions(
  int year,
  int month,
  int day,
) {
  final localNoonUtc = _localInstant(year, month, day, 12);
  final times = sunTimes(
    localNoonUtc,
    latitude: _latitude,
    longitude: _longitude,
    utcOffsetHours: _utcOffsetHours,
  );
  final localMidnight = DateTime.utc(year, month, day);

  DateTime transition(double localHour) {
    return localMidnight
        .add(Duration(seconds: (localHour * Duration.secondsPerHour).round()))
        .subtract(_utcOffset);
  }

  return (sunrise: transition(times.sunrise), sunset: transition(times.sunset));
}

void main() {
  final today = _canonicalSunTransitions(2026, 9, 16);
  final tomorrow = _canonicalSunTransitions(2026, 9, 17);

  group('exact-instant day/night contract', () {
    test('before sunrise is night and transitions to today sunrise', () {
      final instant = today.sunrise.subtract(const Duration(seconds: 1));

      expect(_isNight(instant), isTrue);
      expect(_nextTransition(instant), today.sunrise);
    });

    test('during daytime transitions to today sunset', () {
      final instant = _localInstant(2026, 9, 16, 12);

      expect(_isNight(instant), isFalse);
      expect(_nextTransition(instant), today.sunset);
    });

    test('after sunset is night and transitions to tomorrow sunrise', () {
      final instant = today.sunset.add(const Duration(seconds: 1));

      expect(_isNight(instant), isTrue);
      expect(_nextTransition(instant), tomorrow.sunrise);
    });

    test('exact rounded sunrise is daytime and transitions to sunset', () {
      expect(_isNight(today.sunrise), isFalse);
      expect(_nextTransition(today.sunrise), today.sunset);
    });

    test('exact rounded sunset is nighttime and transitions to sunrise', () {
      expect(_isNight(today.sunset), isTrue);
      expect(_nextTransition(today.sunset), tomorrow.sunrise);
    });

    test('returns a UTC transition', () {
      final transition = _nextTransition(_localInstant(2026, 9, 16, 12));

      expect(transition, today.sunset);
      expect(transition.isUtc, isTrue);
    });

    test('normalizes equivalent instant representations to UTC', () {
      final utc = DateTime.utc(2026, 9, 16, 4);
      final offset = DateTime.parse('2026-09-16T12:00:00+08:00');

      expect(offset, utc);
      expect(_isNight(offset), _isNight(utc));
      expect(_nextTransition(offset), _nextTransition(utc));
      expect(_nextTransition(offset).isUtc, isTrue);
    });

    test('uses the local calendar date when UTC is still the previous day', () {
      final localSeptember16 = _localInstant(2026, 9, 16, 0, 30);

      expect(localSeptember16, DateTime.utc(2026, 9, 15, 16, 30));
      expect(_isNight(localSeptember16), isTrue);
      expect(_nextTransition(localSeptember16), today.sunrise);
    });
  });
}
