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
    final sinHalfLat = math.sin(dLat / 2);
    final sinHalfLng = math.sin(dLng / 2);
    final a =
        sinHalfLat * sinHalfLat +
        math.cos(degToRad(latitude)) *
            math.cos(degToRad(other.latitude)) *
            sinHalfLng *
            sinHalfLng;
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
    final sinLat1 = math.sin(lat1);
    final cosLat1 = math.cos(lat1);
    final sinDelta = math.sin(delta);
    final cosDelta = math.cos(delta);

    final lat2 = math.asin(
      sinLat1 * cosDelta + cosLat1 * sinDelta * math.cos(theta),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(theta) * sinDelta * cosLat1,
          cosDelta - sinLat1 * math.sin(lat2),
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

/// `origin.distanceTo(point) <= metres`, with the origin terms computed once.
///
/// [contains] evaluates the same haversine `a` as [LatLng.distanceTo] and
/// compares it with `sin²(metres / 2R)`. That drops the per-point `sqrt` and
/// `atan2` that only exist to turn `a` back into metres. A radius of at least
/// half the earth's circumference contains every point — [LatLng.distanceTo]
/// cannot return more than that either. On the exact boundary the two can
/// disagree by a fraction of a nanometre, and only by reporting "just
/// outside".
final class DistanceWithin {
  DistanceWithin(LatLng origin, double metres)
    : latitude = origin.latitude,
      _longitude = origin.longitude,
      _cosLat = math.cos(degToRad(origin.latitude)),
      _none = metres < 0,
      _all = metres >= _halfCircumference,
      _limit = _chordLimit(metres);

  static const double _earthRadius = 6378137.0;

  /// The most [LatLng.distanceTo] can return: half a turn of the sphere.
  static const double _halfCircumference = _earthRadius * math.pi;

  final double latitude;
  final double _longitude;
  final double _cosLat;
  final bool _none;
  final bool _all;
  final double _limit;

  static double _chordLimit(double metres) {
    if (metres < 0 || metres >= _halfCircumference) return 0;
    final s = math.sin(metres / (2 * _earthRadius));
    return s * s;
  }

  bool contains(double pointLat, double pointLng) {
    if (_none) return false;
    if (_all) return true;
    final dLat = degToRad(pointLat - latitude);
    final dLng = degToRad(pointLng - _longitude);
    final sinHalfLat = math.sin(dLat / 2);
    final sinHalfLng = math.sin(dLng / 2);
    final a =
        sinHalfLat * sinHalfLat +
        _cosLat * math.cos(degToRad(pointLat)) * sinHalfLng * sinHalfLng;
    return a <= _limit;
  }
}

/// Maps a single GeoJSON `[lng, lat]` pair to a [LatLng] (mind the axis order).
LatLng latLngFromPair(List<dynamic> pair) =>
    LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());

/// Maps a GeoJSON `[[lng, lat], …]` list to [LatLng]s; absent/empty in → empty
/// out.
List<LatLng> latLngsFromPairs(Object? raw) => [
  for (final p in (raw as List? ?? const [])) latLngFromPair(p as List),
];
