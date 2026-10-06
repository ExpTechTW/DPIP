/// A coordinate that cannot round-trip through distance and bearing draws an
/// EEW wavefront in the wrong place, and a swapped GeoJSON axis puts the
/// epicentre in the sea.
library;

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
