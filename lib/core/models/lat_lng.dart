import 'dart:math' as math;

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
    final dLat = _toRadians(other.latitude - latitude);
    final dLng = _toRadians(other.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

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
