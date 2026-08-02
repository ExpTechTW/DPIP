import 'package:dpip/shared/map/base_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The main island's real extreme points. The nationwide framing is derived
/// from [BaseMap.taiwanBounds], so if the box stops short of any of these the
/// map silently crops part of the country — which is exactly what happened when
/// the east edge sat at 121.05°E, inside the island.
const _extremes = <String, LatLng>{
  '富貴角 (north)': LatLng(25.298, 121.536),
  '鵝鑾鼻 (south)': LatLng(21.896, 120.851),
  '國聖港燈塔 (west)': LatLng(23.111, 120.035),
  '三貂角 (east)': LatLng(25.008, 122.007),
};

void main() {
  group('BaseMap.taiwanBounds', () {
    final bounds = BaseMap.taiwanBounds;

    test('contains every extreme point of the main island', () {
      _extremes.forEach((name, point) {
        expect(
          point.latitude,
          inInclusiveRange(
            bounds.southwest.latitude,
            bounds.northeast.latitude,
          ),
          reason: '$name latitude falls outside taiwanBounds',
        );
        expect(
          point.longitude,
          inInclusiveRange(
            bounds.southwest.longitude,
            bounds.northeast.longitude,
          ),
          reason: '$name longitude falls outside taiwanBounds',
        );
      });
    });

    test('is centred on the island, not out in the strait', () {
      final centreLng =
          (bounds.southwest.longitude + bounds.northeast.longitude) / 2;
      // The island spans roughly 120.0–122.0°E, so its centre is near 121.0.
      // The old box centred on 120.02, pushing Taiwan to the screen edge.
      expect(centreLng, closeTo(121.0, 0.2));
    });

    test('does not pad the box with open sea', () {
      // Margin beyond each extreme, in degrees. Generous enough for breathing
      // room, tight enough that the island still dominates the frame.
      expect(bounds.southwest.longitude, greaterThan(119.8));
      expect(bounds.northeast.longitude, lessThan(122.3));
      expect(bounds.southwest.latitude, greaterThan(21.6));
      expect(bounds.northeast.latitude, lessThan(25.6));
    });

    test('taiwanCenter stays derived from the bounds', () {
      expect(
        BaseMap.taiwanCenter.latitude,
        closeTo(
          (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
          1e-9,
        ),
      );
      expect(
        BaseMap.taiwanCenter.longitude,
        closeTo(
          (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
          1e-9,
        ),
      );
    });
  });
}
