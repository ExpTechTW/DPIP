import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/utils/geojson.dart';

/// Extension on [LatLng] that provides convenient utilities for GeoJSON conversion and geographic operations.
///
/// This extension adds helpful methods and getters to simplify GeoJSON formatting, coordinate validation,
/// and distance calculations for geographic coordinates.
extension GeoJsonLatLng on LatLng {
  /// Checks whether this coordinate is valid.
  ///
  /// Returns `true` if both latitude and longitude are non-zero, `false` otherwise.
  /// This is useful for filtering out invalid or uninitialized coordinates.
  bool get isValid => latitude != 0 && longitude != 0;

  /// Converts this coordinate to a GeoJSON coordinate array.
  ///
  /// Returns a list in the format `[longitude, latitude]` as required by the GeoJSON specification.
  List<double> get asGeoJsonCooridnate => [longitude, latitude];

  /// Converts this coordinate to a GeoJSON feature builder.
  ///
  /// Returns a [GeoJsonFeatureBuilder] configured as a Point feature with this coordinate's geometry.
  /// The builder can be further customized with properties before building the final GeoJSON feature.
  GeoJsonFeatureBuilder toGeoJsonFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)..setGeometry(asGeoJsonCooridnate);
  }

  /// Converts this coordinate to a GeoJSON builder.
  ///
  /// Returns a [GeoJsonBuilder] containing a single Point feature representing this coordinate.
  /// The builder can be used to add additional features or build a complete GeoJSON FeatureCollection.
  GeoJsonBuilder toGeoJsonBuilder() {
    return GeoJsonBuilder()..addFeature(toGeoJsonFeatureBuilder());
  }

  /// Converts this coordinate to a GeoJSON map.
  ///
  /// Returns a complete GeoJSON FeatureCollection map containing a single Point feature representing
  /// this coordinate. The map is ready to be serialized to JSON.
  Map<String, dynamic> toGeoJsonMap() {
    return toGeoJsonBuilder().build();
  }

  /// Calculates the distance between this coordinate and [other] in meters.
  ///
  /// The distance is calculated using the Haversine formula, which accounts for the Earth's
  /// spherical shape to provide accurate distance measurements between two geographic coordinates.
  ///
  /// See also:
  /// - https://en.wikipedia.org/wiki/Haversine_formula for details on the Haversine formula
  ///
  /// Example:
  /// ```dart
  /// final point1 = LatLng(25.0330, 121.5654);
  /// final point2 = LatLng(24.1477, 120.6736);
  /// final distance = point1.to(point2);
  /// ```
  double to(LatLng other) => Geolocator.distanceBetween(latitude, longitude, other.latitude, other.longitude);
}
