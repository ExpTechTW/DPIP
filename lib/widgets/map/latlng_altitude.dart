import 'package:maplibre_gl/maplibre_gl.dart';

/// A geographical location specified in degrees [latitude] and [longitude] with
/// an altitude in meters above sea level.
///
/// This class extends [LatLng].
class LatLngAltitude extends LatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude] with an altitude in meters above sea level.
  ///
  /// The latitude is clamped to the inclusive interval from -90.0 to +90.0.
  ///
  /// The longitude is normalized to the half-open interval from -180.0
  /// (inclusive) to +180.0 (exclusive)
  const LatLngAltitude(super.latitude, super.longitude, this.altitude);

  /// The altitude in meters above sea level.
  final double altitude;

  @override
  List<double> toGeoJsonCoordinates() => [latitude, longitude, altitude];

  @override
  String toString() => 'LatLngAltitude($latitude, $longitude, $altitude)';

  @override
  bool operator ==(Object other) {
    return other is LatLngAltitude &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, altitude);
}
