/// The numbers and signs the two native wind renderers must share.
///
/// What fails quietly here is direction and placement. A flipped sign draws a
/// perfectly smooth field blowing the wrong way, and a trail quad placed
/// half a cell off looks like weather. So every convention is checked against
/// an independent statement of it: MapLibre's projection for placement, and
/// "east is right, north is up, bearing 90 puts east at the top" for
/// direction.
library;

import 'dart:math' as math;

import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';
import 'package:flutter_test/flutter_test.dart';

const _taipei = WindCamera(
  centerLat: 25.03,
  centerLng: 121.56,
  zoom: 5,
  bearing: 0,
  width: 393,
  height: 852,
);

WindCamera _with(
  WindCamera c, {
  double? lat,
  double? lng,
  double? zoom,
  double? bearing,
}) => WindCamera(
  centerLat: lat ?? c.centerLat,
  centerLng: lng ?? c.centerLng,
  zoom: zoom ?? c.zoom,
  bearing: bearing ?? c.bearing,
  width: c.width,
  height: c.height,
);

/// Clip space (y up, −1..1) to MapLibre's logical points (y down).
Offset _clipToScreen(WindCamera cam, Offset clip) =>
    Offset((clip.dx + 1) / 2 * cam.width, (1 - clip.dy) / 2 * cam.height);

Matcher _near(Offset expected, [double tolerance = 1e-6]) => predicate<Offset>(
  (o) => (o - expected).distance < tolerance,
  'within $tolerance of $expected',
);

void main() {
  group('the tuning tables', () {
    test('tile zoom is MapLibre zoom plus one, not rounded', () {
      expect(tileZoom(3), 4);
      expect(tileZoom(4.67), closeTo(5.67, 1e-12));
    });

    test('the stroke is lineWidth · 1.3 · DPR plus a feathered pixel', () {
      // z5 → tile zoom 6 → 1.8.
      expect(windStrokeWidth(5, 3), closeTo(1.8 * 1.3 * 3 + 1, 1e-9));
      // Never thinner than one pixel plus the feather.
      expect(windStrokeWidth(-3, 1), 2);
    });

    test('particles slow down zoomed out', () {
      expect(windFullSpeed(3, 1), 100 * 0.7);
      expect(windFullSpeed(7, 1), 100 * 1.0);
      expect(windFullSpeed(5, 2.625), closeTo(100 * 0.9 * 2.625, 1e-9));
    });

    test('the count follows the viewport area, halved on mobile', () {
      // 393 × 852 at z5 (tile zoom 6): 334,836 / (50 · 1.6^4) = 1022 → 511
      // particles, 32 per block.
      expect(windParticlesPerBlock(393, 852, 5), 32);
      // Four times the area, four times the particles.
      expect(windParticlesPerBlock(786, 1704, 5), 128);
      // One zoom in, 1.6× fewer.
      expect(windParticlesPerBlock(393, 852, 6), 20);
    });

    test('between whole zooms the field changes smoothly, not by 1.6×', () {
      // Rounding made 4.49 → 4.51 a 1.6× drop in particles.
      final below = windParticlesPerBlock(412, 924, 4.49);
      final above = windParticlesPerBlock(412, 924, 4.51);
      expect(below / above, closeTo(1, 0.03));
      expect(
        windStrokeWidth(4.49, 2.625),
        closeTo(windStrokeWidth(4.51, 2.625), 0.05),
      );
      expect(windFullSpeed(4.49, 1), closeTo(windFullSpeed(4.51, 1), 0.5));
      // The framed-Taiwan view: between its two whole-zoom neighbours.
      final framed = windParticlesPerBlock(412, 924, 4.67);
      expect(framed, lessThan(windParticlesPerBlock(412, 924, 4)));
      expect(framed, greaterThan(windParticlesPerBlock(412, 924, 5)));
      // Tile zoom 5.67: two thirds of the way from width 1.6 to 1.8.
      expect(
        windStrokeWidth(4.67, 1),
        closeTo((1.6 + 0.67 * 0.2) * 1.3 + 1, 1e-9),
      );
    });

    test('the count saturates at 15,000 and never falls below one a block', () {
      expect(windParticlesPerBlock(1e5, 1e5, 0), (15000 * 0.5 / 16).round());
      expect(windParticlesPerBlock(1, 1, 20), 1);
    });

    test('a particle fades in over 20 % of its life and out over 30 %', () {
      final lut = windAlphaLut();
      expect(lut, hasLength(128));
      expect(lut.first, 0);
      expect(lut[26], 1, reason: 'fully in after round(0.2 · 128) frames');
      // The fade-out spans round(0.3 · 128) = 38 frames and starts at 1.
      expect(lut[90], 1);
      expect(lut[91], lessThan(1));
      expect(lut.last, greaterThan(0));
      for (var i = 1; i < 26; i++) {
        expect(lut[i], greaterThan(lut[i - 1]), reason: 'rising at $i');
      }
    });

    test(
      'the trail fade is 0.97, and the lift hides what 8 bits cannot fade',
      () {
        expect(kWindFade, 0.97);
        // The darkest value an 8-bit multiply by 0.97 can no longer reduce.
        var stuck = 255;
        while ((stuck * kWindFade).round() < stuck) {
          stuck--;
        }
        expect(
          stuck / 255 * kWindCompositeGain + kWindCompositeLift,
          lessThan(0),
        );
      },
    );
  });

  group('the speed curve', () {
    test('(speed / 30)^0.7 of full speed', () {
      expect(windSpeedCurve(30), 1);
      expect(windSpeedCurve(10), closeTo(math.pow(1 / 3, 0.7), 1e-12));
    });

    test('a breeze moves at no less than 1.5 m/s would', () {
      expect(windSpeedCurve(0.2), closeTo(1.5 / 30, 1e-12));
    });

    test('dead calm does not move at all', () {
      expect(windSpeedCurve(0), 0);
    });

    test('a typhoon core is capped, not overflowed', () {
      expect(windSpeedCurve(55), 1);
    });
  });

  group('direction', () {
    const north = _taipei;
    final east = _with(_taipei, bearing: 90);

    test('north-up: east is right, north is up', () {
      expect(windToScreen(north, 10, 0), _near(const Offset(10, 0)));
      expect(windToScreen(north, 0, 10), _near(const Offset(0, 10)));
    });

    test('bearing 90: east is up, north is left', () {
      expect(windToScreen(east, 10, 0), _near(const Offset(0, 10)));
      expect(windToScreen(east, 0, 10), _near(const Offset(-10, 0)));
    });

    test('agrees with where the map puts those directions', () {
      for (final cam in [north, east, _with(_taipei, bearing: 237)]) {
        final here = projectLatLng(cam, cam.centerLat, cam.centerLng);
        final eastward = projectLatLng(cam, cam.centerLat, cam.centerLng + 0.1);
        final northward = projectLatLng(
          cam,
          cam.centerLat + 0.1,
          cam.centerLng,
        );
        // Screen y is down; particle space is up.
        Offset up(Offset d) => Offset(d.dx, -d.dy) / d.distance;
        expect(
          windToScreen(cam, 1, 0),
          _near(up(eastward - here), 1e-3),
          reason: 'east at bearing ${cam.bearing}',
        );
        expect(
          windToScreen(cam, 0, 1),
          _near(up(northward - here), 1e-3),
          reason: 'north at bearing ${cam.bearing}',
        );
      }
    });
  });

  group('the velocity texel', () {
    test('calm is exactly byte 128 and decodes to exactly zero', () {
      expect(encodeWindTexel(_taipei, 0, 0), (128, 128));
      expect(decodeWindTexel(128, 128), Offset.zero);
    });

    test('round-trips the curve within a byte', () {
      final (r, g) = encodeWindTexel(_taipei, 10, 0);
      final back = decodeWindTexel(r, g);
      expect(back.dx, closeTo(windSpeedCurve(10), 1 / 127));
      expect(back.dy, 0);
    });

    test('full strength stays inside a byte, in every direction', () {
      for (var deg = 0; deg < 360; deg += 15) {
        final a = deg * math.pi / 180;
        final (r, g) = encodeWindTexel(
          _taipei,
          60 * math.cos(a),
          60 * math.sin(a),
        );
        final back = decodeWindTexel(r, g);
        expect(back.distance, closeTo(1, 0.02), reason: '$deg°');
        expect(
          math.atan2(back.dy, back.dx),
          closeTo(math.atan2(math.sin(a), math.cos(a)), 0.02),
          reason: 'direction kept at $deg°',
        );
      }
    });
  });

  group('the grid sample', () {
    const grid = (
      lat0: 90.0,
      lon0: 180.0,
      dLat: -0.25,
      width: 1440,
      height: 721,
    );

    Offset uv(double lat, double lng) => windFieldUv(
      lat: lat,
      lng: lng,
      lat0: grid.lat0,
      lon0: grid.lon0,
      dLat: grid.dLat,
      width: grid.width,
      height: grid.height,
    );

    test('a grid node lands on its texel centre', () {
      // Node (10, 20): lon 180 + 2.5, lat 90 − 5.
      final at = uv(85, 182.5);
      expect(at.dx * grid.width, closeTo(10.5, 1e-6));
      expect(at.dy * grid.height, closeTo(20.5, 1e-6));
    });

    test('a grid that starts at 180 wraps like one that starts at 0', () {
      expect(uv(0, -177.5).dx, closeTo(uv(0, 182.5).dx, 1e-9));
    });
  });

  group('the trails follow the map', () {
    test('at rest the reference viewport is the screen', () {
      expect(
        referenceToClip(_taipei, _taipei, Offset.zero),
        _near(const Offset(-1, -1)),
      );
      expect(
        referenceToClip(_taipei, _taipei, const Offset(1, 1)),
        _near(const Offset(1, 1)),
      );
    });

    test('a point of the trails moves exactly as the map under it', () {
      final ref = _with(_taipei, bearing: 30);
      final cams = [
        _with(ref, lat: 26, lng: 123), // pan
        _with(ref, zoom: 6.3), // pinch
        _with(ref, bearing: 75), // rotate
        _with(ref, lat: 22, lng: 119, zoom: 4.2, bearing: 300),
      ];
      for (final cam in cams) {
        for (final p in const [
          Offset(0.1, 0.2),
          Offset(0.5, 0.5),
          Offset(0.9, 0.7),
        ]) {
          final ll = particleToLatLng(ref, p);
          expect(
            _clipToScreen(cam, referenceToClip(ref, cam, p)),
            _near(projectLatLng(cam, ll.lat, ll.lng), 1e-6),
            reason: '$p under $cam',
          );
        }
      }
    });

    test('a pan across the antimeridian keeps the trails on screen', () {
      final ref = _with(_taipei, lng: 179.9);
      final cam = _with(_taipei, lng: -179.9);
      final centre = referenceToClip(ref, cam, const Offset(0.5, 0.5));
      expect(centre.dx.abs(), lessThan(0.1));
    });
  });

  group('settling', () {
    test('no move, no change', () {
      expect(
        windSettle(_taipei, _taipei, trailWidth: 800, trailHeight: 1700),
        isA<WindStay>(),
      );
    });

    test('a pan shifts by whole texels, the way the map moved', () {
      // 0.5° east puts the old view's origin to the left of the new one.
      final cam = _with(_taipei, lng: _taipei.centerLng + 0.5);
      final settle = windSettle(
        _taipei,
        cam,
        trailWidth: 800,
        trailHeight: 1700,
      );
      expect(settle, isA<WindShift>());
      final shift = (settle as WindShift).shift;
      expect(shift.dx, lessThan(0));
      expect(shift.dy, 0);
      expect(shift.dx * 800, closeTo((shift.dx * 800).roundToDouble(), 1e-9));
      final exact = referenceToClip(_taipei, cam, Offset.zero);
      expect(shift.dx, closeTo((exact.dx + 1) / 2, 1 / 800));
    });

    test('a zoom or a rotation clears', () {
      for (final cam in [
        _with(_taipei, zoom: 5.5),
        _with(_taipei, bearing: 10),
      ]) {
        expect(
          windSettle(_taipei, cam, trailWidth: 800, trailHeight: 1700),
          isA<WindClear>(),
        );
      }
    });
  });
}
