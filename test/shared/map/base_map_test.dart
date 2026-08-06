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
  '三貂角 (east)': LatLng(25.008, 122.007),
  // The nationwide view must also frame Kinmen, far west of the main island.
  '金門本島 (west)': LatLng(24.449, 118.318),
  '烈嶼/小金門 (west)': LatLng(24.432, 118.240),
  // Penghu sits inside the Taiwan–Kinmen span and so is framed for free.
  '澎湖 (mid-strait)': LatLng(23.566, 119.579),
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

    test('reaches west far enough for Kinmen but no further', () {
      // Lieyu is the westernmost point that must be framed (~118.24°E); going
      // much past it only adds mainland-China coast and open sea.
      expect(bounds.southwest.longitude, lessThan(118.24));
      expect(bounds.southwest.longitude, greaterThan(117.9));
    });

    test('does not pad the box with open sea', () {
      // Margin beyond each extreme, in degrees — enough for breathing room,
      // tight enough that land still dominates the frame.
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
