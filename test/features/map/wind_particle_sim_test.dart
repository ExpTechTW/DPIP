import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 2×2 global grid; [uValue] / [vValue] set every cell's quantised plane
/// (so all cells carry the same wind), or -1 for a full eastward gradient.
WindField _field({int uValue = 128, int vValue = 128, double lon0 = 0}) =>
    WindField(
      width: 2,
      height: 2,
      lat0: 90,
      lon0: lon0,
      dLat: -90,
      dLon: 180,
      uMin: -1,
      uMax: 1,
      vMin: -1,
      vMax: 1,
      timeMs: 0,
      model: 'gfs',
      u: Uint8List.fromList([uValue, uValue, uValue, uValue]),
      v: Uint8List.fromList([vValue, vValue, vValue, vValue]),
    );

/// A wind field whose every cell blows due east at ~1 m/s.
WindField _eastField() => _field(uValue: 255, vValue: 128);

const _camera = WindCamera(centerLat: 25, centerLng: 121, zoom: 5, bearing: 0);
const _size = Size(1000, 1000);

void main() {
  group('projectLatLng', () {
    test('the camera target lands on the viewport centre', () {
      final p = projectLatLng(_camera, 25, 121, _size);
      expect(p.dx, closeTo(500, 0.001));
      expect(p.dy, closeTo(500, 0.001));
    });

    test('a point north of the target sits above it', () {
      final p = projectLatLng(_camera, 25.1, 121, _size);
      expect(p.dy, lessThan(500));
      expect(p.dx, closeTo(500, 0.001));
    });

    test('bearing 90 rotates north to the right of the viewport', () {
      final cam = WindCamera(centerLat: 0, centerLng: 0, zoom: 2, bearing: 90);
      final north = projectLatLng(cam, 1, 0, _size);
      expect(north.dx, greaterThan(500));
      expect(north.dy, closeTo(500, 0.001));
    });

    test('a longitude expressed past 180 lands where its wrap does', () {
      // Particle longitudes are `lon0 + x · 360`, so a grid whose first column
      // is at 180 — ECMWF's — never produces one inside [-180, 180].
      final home = projectLatLng(_camera, 25, 121, _size);
      for (final turns in [-2.0, -1.0, 1.0, 2.0]) {
        final p = projectLatLng(_camera, 25, 121 + 360 * turns, _size);
        expect(p.dx, closeTo(home.dx, 1e-6), reason: '121° + $turns turns');
        expect(p.dy, closeTo(home.dy, 1e-6), reason: '121° + $turns turns');
      }
    });

    test('a point past the antimeridian projects onto the near edge', () {
      // Seen from 121°E, 175°W is 64° east, not 296° west.
      final cam = WindCamera(centerLat: 0, centerLng: 121, zoom: 2, bearing: 0);
      final p = projectLatLng(cam, 0, -175, _size);
      final world = 512 * 4.0;
      expect(p.dx - 500, closeTo(64 / 360 * world, 1e-6));
    });
  });

  group('viewportBounds', () {
    test('an unbearing zoom-0 512×512 view shows the whole world', () {
      final cam = WindCamera(centerLat: 0, centerLng: 0, zoom: 0, bearing: 0);
      final vp = viewportBounds(cam, const Size(512, 512));
      expect(vp.westLng, closeTo(-180, 1e-9));
      expect(vp.eastLng, closeTo(180, 1e-9));
      expect(vp.northLat, closeTo(85.05, 0.01));
      expect(vp.southLat, closeTo(-85.05, 0.01));
    });

    test('shrinks with the size and zoom', () {
      final cam = WindCamera(
        centerLat: 25,
        centerLng: 121,
        zoom: 8,
        bearing: 0,
      );
      final vp = viewportBounds(cam, const Size(1000, 1000));
      // world is 512·2⁸ = 131072 px wide; 500 px is 1.373° of longitude.
      expect(vp.eastLng - vp.westLng, closeTo(1000 / 131072 * 360, 1e-9));
    });
  });

  group('WindParticleSim', () {
    test('near-calm air barely moves a particle but leaves trails', () {
      final sim = WindParticleSim(_field(), count: 20, random: math.Random(7));
      sim.step(_camera, _size);
      final x0 = sim.particles.first.x;
      final y0 = sim.particles.first.y;
      for (var i = 0; i < 10; i++) {
        sim.step(_camera, _size);
      }
      expect(sim.particles.first.x - x0, lessThan(1e-3));
      expect(sim.particles.first.y - y0, lessThan(1e-3));
      expect(
        sim.particles.every((p) => p.visible),
        isTrue,
        reason: 'every seeded particle sits in the viewport, so all stamp',
      );
    });

    test('an eastward field advects particles east', () {
      final sim = WindParticleSim(
        _eastField(),
        count: 40,
        random: math.Random(7),
      );
      sim.step(_camera, _size); // seeds the viewport
      final x0 = [for (final p in sim.particles) p.x];
      sim.step(_camera, _size); // one advection frame
      // The median, not the mean: a recycled particle jumps anywhere in the
      // viewport, and at the web's drop rate a few dozen of them do so every
      // frame — enough to swamp the sub-pixel drift of everyone else.
      final drift = <double>[];
      for (var i = 0; i < sim.particles.length; i++) {
        var dx = sim.particles[i].x - x0[i];
        if (dx > 0.5) dx -= 1; // unwind a wrap past longitude 0
        if (dx < -0.5) dx += 1;
        drift.add(dx);
      }
      drift.sort();
      expect(drift[drift.length ~/ 2], greaterThan(0));
    });

    test('a particle drifting off the field respawns into the viewport', () {
      final sim = WindParticleSim(_field(), count: 1, random: math.Random(3));
      sim.step(_camera, _size);
      final out = sim.particles.first
        ..y = -1.5; // above the field's north edge, off the grid
      sim.step(_camera, _size);
      expect(
        out.visible,
        isFalse,
        reason: 'off the grid is nothing to stamp, whatever happens next',
      );
      // Recycling is rejection-sampled, so a candidate in still air is turned
      // down nine times in ten and the particle waits where it is for the next
      // frame — exactly what the web renderer does. Give it those frames.
      for (var i = 0; i < 100; i++) {
        sim.step(_camera, _size);
      }
      expect(out.y, inInclusiveRange(0, 1));
      // The respawned position lies inside the current viewport's field rect.
      final vp = viewportBounds(_camera, _size);
      final east = ((vp.eastLng - 0) / 360) % 1.0;
      final west = ((vp.westLng - 0) / 360) % 1.0;
      expect(
        out.x,
        inInclusiveRange(math.min(west, east), math.max(west, east)),
      );
    });

    test('a grid whose first column is at 180 streaks like one at 0', () {
      // ECMWF ships its global grid starting at longitude 180 where GFS starts
      // at 0. Nothing else about the two differs, so the same view must draw
      // the same number of streaks — it once drew none at all, because every
      // ECMWF particle projected tens of thousands of pixels off screen and was
      // recycled before it could trace anything.
      int streaks(double lon0) {
        final sim = WindParticleSim(
          _field(uValue: 255, vValue: 128, lon0: lon0),
          count: 40,
          random: math.Random(7),
        );
        for (var i = 0; i < 5; i++) {
          sim.step(_camera, _size);
        }
        return sim.particles.where((p) => p.visible).length;
      }

      expect(streaks(180), streaks(0));
      expect(streaks(180), greaterThan(30));
    });

    test('a viewport straddling the grid seam seeds inside itself', () {
      // The seam is at lon0, which for ECMWF is the antimeridian. Wrapping the
      // two edges into [0,1) independently would leave west > east and seed the
      // complement of the view — everywhere the viewer is not looking.
      final cam = WindCamera(centerLat: 0, centerLng: 179, zoom: 4, bearing: 0);
      final sim = WindParticleSim(
        _field(lon0: 180),
        count: 200,
        random: math.Random(11),
      );
      sim.step(cam, _size);
      final vp = viewportBounds(cam, _size);
      for (final p in sim.particles) {
        var lng = 180 + p.x * 360;
        lng -= 360 * ((lng - vp.westLng) / 360).floorToDouble();
        expect(lng, lessThanOrEqualTo(vp.eastLng + 1e-9));
      }
    });

    test('on-screen pace stays put as the map zooms in', () {
      // A field-space step covers twice the pixels for every zoom level in, so
      // holding it fixed made particles 23× too fast at z7 — the "flying
      // everywhere" that a fixed step always ends in.
      double pixelsPerFrame(double zoom) {
        final sim = WindParticleSim(_eastField(), random: math.Random(5));
        final cam = WindCamera(
          centerLat: 25,
          centerLng: 121,
          zoom: zoom,
          bearing: 0,
        );
        sim.step(cam, _size); // seeds
        Offset at(WindParticle p) =>
            projectLatLng(cam, 90 + p.y * -180, p.x * 360, _size);
        final before = [for (final p in sim.particles) at(p)];
        sim.step(cam, _size);
        // Median again: the handful recycled this frame moved by a respawn,
        // not by the wind.
        final moved = [
          for (var i = 0; i < sim.particles.length; i++)
            (at(sim.particles[i]) - before[i]).distance,
        ]..sort();
        return moved[moved.length ~/ 2];
      }

      final slow = pixelsPerFrame(3);
      for (final zoom in [4.0, 5.0, 6.0, 7.0]) {
        expect(
          pixelsPerFrame(zoom),
          closeTo(slow, slow * 0.6),
          reason: 'z$zoom should read at much the same pace as z3',
        );
      }
      // Past the tuned stops the web holds its values flat rather than
      // extrapolating — "outside the stops there is no judgement behind the
      // number, only arithmetic" — so the pace does climb again out there. The
      // wind layer caps the map at z7, so nobody sees it; asserted only so the
      // clamp is not mistaken for a bug next time someone measures z10.
      expect(pixelsPerFrame(10), greaterThan(slow * 4));
    });
  });
}
