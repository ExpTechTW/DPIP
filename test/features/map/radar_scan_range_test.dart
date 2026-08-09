import 'dart:math' as math;

import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:flutter_test/flutter_test.dart';

/// Great-circle distance in km, the unsimplified form the coverage test is
/// derived from. Used here to check the simplification, not by the app.
double _haversineKm(double lon1, double lat1, double lon2, double lat2) {
  const deg = math.pi / 180.0;
  final dPhi = (lat2 - lat1) * deg;
  final dLam = (lon2 - lon1) * deg;
  final a =
      math.pow(math.sin(dPhi / 2), 2) +
      math.cos(lat1 * deg) *
          math.cos(lat2 * deg) *
          math.pow(math.sin(dLam / 2), 2);
  return 2 * RadarScanRange.earthRadiusKm * math.asin(math.sqrt(a));
}

/// Whether a point is within some radar's range, computed the long way.
bool _coveredByHaversine(double lon, double lat) {
  for (final s in RadarScanRange.sites) {
    if (_haversineKm(lon, lat, s.lon, s.lat) <= s.radiusKm) return true;
  }
  return false;
}

void main() {
  test('the simplified test agrees with raw haversine across the grid', () {
    // `sin²(·/2Rₑ)` is applied to both sides of the distance condition, which
    // is order-preserving on [0, π/2] — so the two must agree everywhere, not
    // merely nearby. Anything else means the algebra is wrong.
    var checked = 0;
    for (var lat = 18.0; lat <= 29.0; lat += 0.05) {
      for (var lon = 115.0; lon <= 126.5; lon += 0.05) {
        final fast = RadarScanRange.covered(lon, lat);
        final slow = _coveredByHaversine(lon, lat);
        // Points within a metre of a circle's rim can land either side of the
        // comparison in floating point; ignore that band.
        var onRim = false;
        for (final s in RadarScanRange.sites) {
          if ((_haversineKm(lon, lat, s.lon, s.lat) - s.radiusKm).abs() <
              0.001) {
            onRim = true;
          }
        }
        if (onRim) continue;
        expect(fast, slow, reason: 'at $lon, $lat');
        checked++;
      }
    }
    expect(checked, greaterThan(50000));
  });

  test('coverage is the union of the circles, not any single one', () {
    // A point only Ishigaki can see — the nearest Taiwanese radar is 126 km
    // beyond its own range. If the union collapsed to the three domestic sites
    // this whole south-east corner would read as unobserved.
    const lon = 126.5;
    const lat = 21.6;
    expect(RadarScanRange.covered(lon, lat), isTrue);
    for (var i = 0; i < RadarScanRange.domesticSiteCount; i++) {
      final s = RadarScanRange.sites[i];
      expect(
        _haversineKm(lon, lat, s.lon, s.lat),
        greaterThan(s.radiusKm),
        reason: 'site $i',
      );
    }
  });

  test('coverage is clipped to the declared grid', () {
    // Kenting reaches well south of 18°N, but the composite has no rows there.
    expect(_coveredByHaversine(120.85, 17.95), isTrue);
    expect(RadarScanRange.covered(120.85, 17.95), isFalse);
    expect(RadarScanRange.covered(120.85, 18.05), isTrue);
  });

  test('the grid corners are outside coverage', () {
    // The whole point of the outline: most of the declared box is never
    // sampled, so a blank corner is "not observed", not "no rain".
    for (final corner in [
      [115.0, 18.0],
      [126.5, 18.0],
      [115.0, 29.0],
      [126.5, 29.0],
    ]) {
      expect(
        RadarScanRange.covered(corner[0], corner[1]),
        isFalse,
        reason: 'corner $corner',
      );
    }
  });

  test('the ring is a closed polygon that stays inside the grid', () {
    final ring = RadarScanRange.ring();
    expect(ring.length, greaterThan(100));
    expect(ring.first, ring.last, reason: 'an exterior ring must close');
    for (final p in ring) {
      expect(p[0], inInclusiveRange(RadarScanRange.west, RadarScanRange.east));
      expect(
        p[1],
        inInclusiveRange(RadarScanRange.south, RadarScanRange.north),
      );
    }
  });

  test('the ring is wound counter-clockwise', () {
    // GeoJSON's rule for an exterior ring. Shoelace > 0 is CCW in lon/lat.
    final ring = RadarScanRange.ring();
    var twiceArea = 0.0;
    for (var i = 0; i < ring.length - 1; i++) {
      twiceArea += ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1];
    }
    expect(twiceArea, greaterThan(0));
  });

  test('every ring vertex sits on the coverage boundary', () {
    // The edge is the closed-form inverse of the same condition, so each vertex
    // must be covered just inside and uncovered just outside.
    final ring = RadarScanRange.ring();
    for (var i = 0; i < ring.length - 1; i += 37) {
      final lon = ring[i][0];
      final lat = ring[i][1];
      // Skip vertices clamped to the grid edge — there the boundary is the box.
      if (lon <= RadarScanRange.west + 1e-6 ||
          lon >= RadarScanRange.east - 1e-6) {
        continue;
      }
      final inward = RadarScanRange.covered(
        lon + (lon > 121 ? -0.02 : 0.02),
        lat,
      );
      expect(inward, isTrue, reason: 'inside of vertex $i ($lon, $lat)');
    }
  });

  test('the outline is a polygon feature, decoded not encoded', () {
    final geo = RadarScanRange.geoJson();
    // Handing `addSource` a string aborts the process on iOS.
    expect(geo, isA<Map<String, dynamic>>());
    final feature = (geo['features']! as List).first as Map<String, dynamic>;
    final geometry = feature['geometry']! as Map<String, dynamic>;
    expect(geometry['type'], 'Polygon');
    expect((geometry['coordinates']! as List).first, isA<List<dynamic>>());
  });

  test('a coarser step still produces a valid ring', () {
    final coarse = RadarScanRange.ring(step: 0.1);
    expect(coarse.first, coarse.last);
    expect(coarse.length, lessThan(RadarScanRange.ring().length));
  });
}
