/// A coordinate that cannot round-trip through distance and bearing draws an
/// EEW wavefront in the wrong place, and a swapped GeoJSON axis puts the
/// epicentre in the sea.
library;

import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('destination and distance agree, and equality is by value', () {
    const taipei = LatLng(25.033, 121.565);
    final moved = taipei.destinationPoint(90, 1000);
    expect(taipei.distanceTo(moved), closeTo(1000, 1));
    expect(moved.longitude, greaterThan(taipei.longitude));
    expect(LatLng(moved.latitude, moved.longitude), moved);
    expect(moved.hashCode, LatLng(moved.latitude, moved.longitude).hashCode);
    expect(moved == taipei, isFalse);
    expect(moved.toString(), contains('LatLng('));
  });

  test('a fixed-origin disc matches distanceTo except on the boundary', () {
    const origin = LatLng(23.5, 121.5);
    final random = math.Random(1);
    for (var i = 0; i < 200; i++) {
      final point = LatLng(
        origin.latitude + random.nextDouble() * 8 - 4,
        origin.longitude + random.nextDouble() * 8 - 4,
      );
      final metres = origin.distanceTo(point);
      // A millimetre either side of the radius is far past the nanometre
      // the chord test can drift by, and well inside a map pixel.
      expect(
        DistanceWithin(
          origin,
          metres + 0.001,
        ).contains(point.latitude, point.longitude),
        isTrue,
      );
      expect(
        DistanceWithin(
          origin,
          metres - 0.001,
        ).contains(point.latitude, point.longitude),
        isFalse,
      );
    }
    expect(
      DistanceWithin(origin, -1).contains(origin.latitude, origin.longitude),
      isFalse,
    );
    expect(
      DistanceWithin(origin, 0).contains(origin.latitude, origin.longitude),
      isTrue,
    );
    // Half the earth's circumference is the most distanceTo can return, so
    // anything at least that large contains every point.
    expect(DistanceWithin(origin, 6378137 * math.pi).contains(0, 0), isTrue);
  });

  test('GeoJSON pairs are longitude first, and a missing ring is empty', () {
    expect(latLngFromPair([121.5, 24.0]), const LatLng(24.0, 121.5));
    expect(latLngsFromPairs(null), isEmpty);
    expect(
      latLngsFromPairs([
        [121.0, 23.0],
        [122.0, 24.5],
      ]).map((p) => p.latitude),
      [23.0, 24.5],
    );
  });
}
