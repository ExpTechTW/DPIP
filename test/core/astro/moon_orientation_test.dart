/// The Moon's tilt, checked against physics rather than against a convention.
///
/// Orientation is where sign errors hide: a rendered globe rolled the wrong
/// way looks entirely plausible, and no other reading on the page disagrees
/// with it. So nothing here trusts a position-angle formula. Each test states
/// something that must be true of the sky itself — the crescent points at the
/// Sun; the pole leans away from the meridian on the side the object is on;
/// the tilt vanishes at the pole and is extreme at the equator — and checks
/// the computed angles against that.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/moon_orientation.dart';
import 'package:dpip/core/astro/moon_rise_set.dart';
import 'package:dpip/core/astro/sun_events.dart';
import 'package:flutter_test/flutter_test.dart';

const _taipei = (latitude: 25.0330, longitude: 121.5654);

double _deg(double radians) => radians * 180 / math.pi;

void main() {
  group('MoonOrientation', () {
    test('the lit limb points at the Sun', () {
      // The defining fact. Checked by walking a month at three-hour steps and
      // comparing the limb bearing against the Sun's own bearing from the
      // Moon, computed independently from the two horizontal positions.
      var worst = 0.0;
      for (var hours = 0; hours < 24 * 30; hours += 3) {
        final at = DateTime.utc(2026, 6).add(Duration(hours: hours));
        final orientation = MoonOrientation.at(
          at,
          latitude: _taipei.latitude,
          longitude: _taipei.longitude,
        );
        final sun = SunEvents.lookFrom(
          at,
          latitude: _taipei.latitude,
          longitude: _taipei.longitude,
        );
        final moon = MoonRiseSet.lookFrom(
          at,
          latitude: _taipei.latitude,
          longitude: _taipei.longitude,
        );
        worst = math.max(
          worst,
          signedTurn(orientation.brightLimbBearing - moon.bearingTo(sun)).abs(),
        );
      }
      expect(_deg(worst), lessThan(0.001));
    });

    test('the pole is upright on the meridian and leans either side of it', () {
      // At upper transit the celestial pole is directly above or below the
      // object, so the roll is zero; east of the meridian it leans one way and
      // west the other. A sign flip in the bearing shows up here as the lean
      // going the wrong way, which no luminance test could see.
      final transit = MoonRiseSet.of(
        DateTime.utc(2026, 8, 15, -8),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      ).transit!;

      double rollAt(Duration offset) => MoonOrientation.at(
        transit.add(offset),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      ).northBearing;

      expect(_deg(rollAt(Duration.zero)).abs(), lessThan(0.2));
      final before = rollAt(const Duration(hours: -3));
      final after = rollAt(const Duration(hours: 3));
      expect(before.sign, isNot(after.sign));
      expect(_deg(before).abs(), greaterThan(1));
    });

    test('the tilt is a latitude effect — none at the pole, most at the '
        'equator', () {
      // The whole reason this exists. From the north pole the sky never
      // rotates and a north-up render is right; on the equator the Moon rolls
      // through a large angle between rising and setting.
      double spread(double latitude) {
        var low = math.pi;
        var high = -math.pi;
        for (var hours = 0; hours < 24; hours++) {
          final roll = MoonOrientation.at(
            DateTime.utc(2026, 3, 20).add(Duration(hours: hours)),
            latitude: latitude,
            longitude: 121.0,
          ).northBearing;
          low = math.min(low, roll);
          high = math.max(high, roll);
        }
        return _deg(high - low);
      }

      expect(spread(89.5), lessThan(2), reason: 'near the pole, no roll');
      expect(spread(25.0), greaterThan(40), reason: 'Taiwan rolls visibly');
      expect(spread(0.0), greaterThan(80), reason: 'the equator rolls most');
    });

    test('the terminator is not perpendicular to the polar axis', () {
      // The reason two angles are carried instead of one. If the lit limb were
      // simply 90° from the pole, a single roll would do — but the Sun is on
      // the ecliptic and the Moon's axis follows the equator, so the two
      // disagree by tens of degrees over a month.
      var worst = 0.0;
      for (var hours = 0; hours < 24 * 30; hours += 6) {
        final tilt = MoonOrientation.at(
          DateTime.utc(2026).add(Duration(hours: hours)),
          latitude: _taipei.latitude,
          longitude: _taipei.longitude,
        ).limbTiltFromPole;
        // Distance from a right angle, either way round.
        worst = math.max(worst, (tilt.abs() - math.pi / 2).abs());
      }
      expect(_deg(worst), greaterThan(10));
    });

    test('carries the Moon\'s own position, so a caller needs one call', () {
      final at = DateTime.utc(2026, 8, 15, 12);
      final orientation = MoonOrientation.at(
        at,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      final direct = MoonRiseSet.lookFrom(
        at,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(orientation.horizontal.altitude, direct.altitude);
      expect(orientation.horizontal.azimuth, direct.azimuth);
    });
  });

  group('Observer', () {
    test('azimuth is measured from north, eastward', () {
      // A transiting body is due south from Taiwan and due north from Sydney.
      // Getting this backwards would send every pointing instruction 180° out.
      final transit = MoonRiseSet.of(
        DateTime.utc(2026, 8, 15, -8),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      ).transit!;
      final north = MoonRiseSet.lookFrom(
        transit,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(_deg(north.azimuth), closeTo(180, 5));

      final southern = MoonRiseSet.of(
        DateTime.utc(2026, 8, 15, -10),
        latitude: -33.8688,
        longitude: 151.2093,
      ).transit!;
      final south = MoonRiseSet.lookFrom(
        southern,
        latitude: -33.8688,
        longitude: 151.2093,
      );
      expect(
        math.min(_deg(south.azimuth), 360 - _deg(south.azimuth)),
        lessThan(5),
      );
    });

    test('the Sun is in the east at sunrise and the west at sunset', () {
      final events = SunEvents.of(
        DateTime.utc(2026, 3, 20, -8),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      final rise = SunEvents.lookFrom(
        events.rise!,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      final set = SunEvents.lookFrom(
        events.set!,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      // Equinox, so both are within a degree or so of due east and due west.
      expect(_deg(rise.azimuth), closeTo(90, 2));
      expect(_deg(set.azimuth), closeTo(270, 2));
    });
  });
}
