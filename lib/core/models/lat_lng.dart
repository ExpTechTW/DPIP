import 'dart:math' as math;

import 'package:dpip/core/geo/geo_math.dart';

/// An immutable WGS84 geographic coordinate.
///
/// Deliberately dependency-free so domain logic (EEW estimation, geofencing)
/// never pulls in the map-rendering package. Convert to the map library's own
/// coordinate type only at the presentation boundary.
class LatLng {
  const LatLng(this.latitude, this.longitude);

  /// Latitude in degrees.
  final double latitude;

  /// Longitude in degrees.
  final double longitude;

  /// Great-circle distance to [other] in metres.
  ///
  /// Uses the Haversine formula with the WGS84 equatorial radius — identical to
  /// the `geolocator` reference implementation the app previously relied on, so
  /// seismic distance calculations produce the same results.
  double distanceTo(LatLng other) {
    const earthRadius = 6378137.0;
    final dLat = degToRad(other.latitude - latitude);
    final dLng = degToRad(other.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(degToRad(latitude)) *
            math.cos(degToRad(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// The point [distance] metres from this one along initial compass
  /// [bearing] degrees (0 = north, clockwise) — the forward geodesic problem,
  /// via the same spherical-earth model [distanceTo] uses (so a round trip
  /// through both is self-consistent). Used to plot a geo circle (e.g. an EEW
  /// wavefront) as a polygon of points around a centre.
  LatLng destinationPoint(double bearing, double distance) {
    const earthRadius = 6378137.0;
    final delta = distance / earthRadius;
    final theta = degToRad(bearing);
    final lat1 = degToRad(latitude);
    final lon1 = degToRad(longitude);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(delta) +
          math.cos(lat1) * math.sin(delta) * math.cos(theta),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(theta) * math.sin(delta) * math.cos(lat1),
          math.cos(delta) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(_toDegrees(lat2), _toDegrees(lon2));
  }

  static double _toDegrees(double radians) => radians * 180.0 / math.pi;

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
