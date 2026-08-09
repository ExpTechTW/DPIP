import 'dart:math' as math;

import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe_data.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/solar_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// The solar ephemeris is what decides whether the backdrop looks like noon,
/// sunset or midnight, so it is pinned against real astronomy for Taipei
/// rather than eyeballed. Getting it wrong would not crash anything — it
/// would just quietly show the wrong sky, which is exactly the kind of bug a
/// test has to catch.
void main() {
  // Taipei.
  const lat = 25.033;
  const lon = 121.565;

  double deg(double radians) => radians * 180.0 / math.pi;

  /// Local Taiwan time (UTC+8) as a UTC instant.
  DateTime taipei(int y, int m, int d, int hour, [int minute = 0]) =>
      DateTime.utc(y, m, d, hour, minute).subtract(const Duration(hours: 8));

  group('solarPosition', () {
    test('equinox noon elevation matches 90° − latitude', () {
      // At the March equinox the sun is over the equator, so its noon
      // elevation is 90° − |latitude| ≈ 65° for Taipei.
      final sun = solarPosition(
        taipei(2026, 3, 20, 12, 10),
        latitude: lat,
        longitude: lon,
      );
      expect(deg(sun.elevation), closeTo(65.0, 1.5));
    });

    test('summer sun climbs far higher than winter sun', () {
      final summer = solarPosition(
        taipei(2026, 6, 21, 12, 10),
        latitude: lat,
        longitude: lon,
      );
      final winter = solarPosition(
        taipei(2026, 12, 21, 12, 10),
        latitude: lat,
        longitude: lon,
      );

      // Taipei sits just north of the Tropic of Cancer, so the June sun
      // passes almost exactly overhead; in December it barely clears 41°.
      expect(deg(summer.elevation), closeTo(88.3, 2.0));
      expect(deg(winter.elevation), closeTo(41.5, 2.0));
    });

    test('sun is below the horizon at local midnight', () {
      final sun = solarPosition(
        taipei(2026, 6, 21, 0),
        latitude: lat,
        longitude: lon,
      );
      expect(deg(sun.elevation), lessThan(-20.0));
    });

    test('sun rises in the east and sets in the west', () {
      // Azimuth is measured clockwise from true north.
      final morning = solarPosition(
        taipei(2026, 3, 20, 7),
        latitude: lat,
        longitude: lon,
      );
      final evening = solarPosition(
        taipei(2026, 3, 20, 17),
        latitude: lat,
        longitude: lon,
      );
      expect(deg(morning.azimuth), closeTo(90.0, 15.0));
      expect(deg(evening.azimuth), closeTo(270.0, 15.0));
    });

    test('daylight is longer in June than December', () {
      int daylightMinutes(DateTime dayStartLocal) {
        var count = 0;
        for (var m = 0; m < 24 * 60; m += 5) {
          final sun = solarPosition(
            dayStartLocal.add(Duration(minutes: m)),
            latitude: lat,
            longitude: lon,
          );
          if (sun.elevation > 0) count += 5;
        }
        return count;
      }

      final june = daylightMinutes(taipei(2026, 6, 21, 0));
      final december = daylightMinutes(taipei(2026, 12, 21, 0));

      // Real values for Taipei are roughly 13h40m and 10h35m.
      expect(june, closeTo(13 * 60 + 40, 20));
      expect(december, closeTo(10 * 60 + 35, 20));
      expect(june, greaterThan(december));
    });
  });

  group('sunTimes', () {
    test('matches published Taipei sunrise/sunset', () {
      // Real almanac values for Taipei: 21 Jun ~05:05/18:47,
      // 21 Dec ~06:34/17:12.
      final june = sunTimes(
        taipei(2026, 6, 21, 12),
        latitude: lat,
        longitude: lon,
      );
      final december = sunTimes(
        taipei(2026, 12, 21, 12),
        latitude: lat,
        longitude: lon,
      );

      expect(june.sunrise, closeTo(5.09, 0.25));
      expect(june.sunset, closeTo(18.78, 0.25));
      expect(december.sunrise, closeTo(6.57, 0.25));
      expect(december.sunset, closeTo(17.20, 0.25));
    });

    test('daylight is longer in June than December', () {
      final june = sunTimes(
        taipei(2026, 6, 21, 12),
        latitude: lat,
        longitude: lon,
      );
      final december = sunTimes(
        taipei(2026, 12, 21, 12),
        latitude: lat,
        longitude: lon,
      );
      expect(
        june.sunset - june.sunrise,
        greaterThan(december.sunset - december.sunrise),
      );
    });
  });

  group('keyframePosition', () {
    test('anchors sunrise and sunset to the dawn and dusk keyframes', () {
      // With the default equinox-ish sun the ring is very nearly even.
      double pos(double hour) => keyframePosition(hour, frameCount: 17);

      expect(pos(5.6), closeTo(17 * 5.6 / 24, 0.01)); // sunrise → dawn key
      expect(pos(18.4), closeTo(17 * 18.4 / 24, 0.01)); // sunset → dusk key
      // Keyframe 8 is the ring's peak, and on an even split that is 11.3 h —
      // solar noon, not 12:00.
      expect(pos(11.3), closeTo(8.0, 0.05));
    });

    test('06:00 resolves to dawn, not to night', () {
      // The regression this guards: anchoring the ring to sunrise put 06:00
      // near keyframe 0 — which is midnight — and rendered a dark sky at dawn.
      final dawn = resolveSky(
        sunnyKeyframes,
        position: keyframePosition(
          6,
          frameCount: sunnyKeyframes.length,
          sunrise: 5.3,
          sunset: 18.6,
        ),
        humidity: 0.5,
      );
      final midnight = resolveSky(
        sunnyKeyframes,
        position: keyframePosition(
          0,
          frameCount: sunnyKeyframes.length,
          sunrise: 5.3,
          sunset: 18.6,
        ),
        humidity: 0.5,
      );
      expect(dawn.sunAngleY, greaterThan(midnight.sunAngleY * 2));
    });

    test('the sun peaks near midday and bottoms out overnight', () {
      double angleAt(double hour) => resolveSky(
        sunnyKeyframes,
        position: keyframePosition(hour, frameCount: sunnyKeyframes.length),
        humidity: 0.5,
      ).sunAngleY;

      expect(angleAt(12), greaterThan(angleAt(6)));
      expect(angleAt(12), greaterThan(angleAt(18)));
      expect(angleAt(3), lessThan(angleAt(9)));
    });
  });

  group('resolveSky', () {
    test('interpolates between neighbouring keyframes', () {
      final a = resolveSky(sunnyKeyframes, position: 8, humidity: 0);
      final b = resolveSky(sunnyKeyframes, position: 9, humidity: 0);
      final mid = resolveSky(sunnyKeyframes, position: 8.5, humidity: 0);

      expect(mid.sunAngleY, closeTo((a.sunAngleY + b.sunAngleY) / 2, 1e-9));
    });

    test('wraps around the end of the ring', () {
      final last = resolveSky(sunnyKeyframes, position: 16.5, humidity: 0);
      expect(last.sunAngleY, isNot(isNaN));
      // Position 17 is position 0 again.
      final wrapped = resolveSky(sunnyKeyframes, position: 17, humidity: 0);
      final zero = resolveSky(sunnyKeyframes, position: 0, humidity: 0);
      expect(wrapped.sunAngleY, closeTo(zero.sunAngleY, 1e-9));
    });

    test('humidity blends the dry and wet atmosphere ramps', () {
      final dry = resolveSky(sunnyKeyframes, position: 8, humidity: 0);
      final wet = resolveSky(sunnyKeyframes, position: 8, humidity: 1);
      // The keyframe's humidity ramp raises Mie scattering with moisture.
      expect(wet.mieScatter, greaterThan(dry.mieScatter));
    });

    test('every weather type has keyframes and resolves', () {
      expect(weatherKeyframes.length, 14);
      for (final frames in weatherKeyframes) {
        expect(frames, isNotEmpty);
        final sky = resolveSky(frames, position: 1.5, humidity: 0.5);
        expect(sky.sunAngleY, greaterThan(0));
        expect(sky.sunIntensity, greaterThan(0));
      }
    });
  });
}
