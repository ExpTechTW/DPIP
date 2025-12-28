import 'dart:math';

import 'package:geojson_vi/geojson_vi.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/api/model/eew.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';

enum Units {
  meters,
  metres,
  millimeters,
  millimetres,
  centimeters,
  centimetres,
  kilometers,
  kilometres,
  miles,
  nauticalmiles,
  inches,
  yards,
  feet,
  radians,
  degrees,
}

/// Earth Radius used with the Harvesine formula and approximates using a spherical (non-ellipsoid) Earth.
///
/// @memberof helpers
/// @type {number}
const earthRadius = 6371008.8;

/// Unit of measurement factors using a spherical (non-ellipsoid) earth radius.
///
/// Keys are the name of the unit, values are the number of that unit in a single radian
const Map<Units, double> factors = {
  Units.centimeters: earthRadius * 100,
  Units.centimetres: earthRadius * 100,
  Units.degrees: 360 / (2 * pi),
  Units.feet: earthRadius * 3.28084,
  Units.inches: earthRadius * 39.37,
  Units.kilometers: earthRadius / 1000,
  Units.kilometres: earthRadius / 1000,
  Units.meters: earthRadius,
  Units.metres: earthRadius,
  Units.miles: earthRadius / 1609.344,
  Units.millimeters: earthRadius * 1000,
  Units.millimetres: earthRadius * 1000,
  Units.nauticalmiles: earthRadius / 1852,
  Units.radians: 1,
  Units.yards: earthRadius * 1.0936,
};

// Math constants for degree/radian conversion
const _degToRad = pi / 180;
const _radToDeg = 180 / pi;
const _twoPi = 2 * pi;

/// Converts an angle in degrees to radians
double degreesToRadians(double degrees) {
  final radians = degrees % 360;
  return radians * _degToRad;
}

/// Converts an angle in radians to degrees
double radiansToDegrees(double radians) {
  final degrees = radians % _twoPi;
  return degrees * _radToDeg;
}

// Precomputed factor for kilometers (most common unit for EEW)
const _kmToRadiansFactor = 1000 / earthRadius;

/// Convert a distance measurement (assuming a spherical Earth) from a real-world unit into radians
/// Valid units: miles, nauticalmiles, inches, yards, meters, metres, kilometers, centimeters, feet
double lengthToRadians(double distance, {Units units = Units.kilometers}) {
  // Fast path for kilometers (most common for EEW)
  if (units == Units.kilometers) {
    return distance * _kmToRadiansFactor;
  }

  final factor = factors[units];
  if (factor == null) {
    throw '$units units is invalid';
  }
  return distance / factor;
}

/// Takes a [LatLng] and calculates the location of a destination point given a distance in
/// degrees, radians, miles, or kilometers; and bearing in degrees.
/// This uses the [Haversine formula](http://en.wikipedia.org/wiki/Haversine_formula) to account for global curvature.
LatLng destination(
  LatLng origin,
  double distance,
  double bearing, {
  Units units = Units.kilometers,
}) {
  // Handle input
  final longitude1 = degreesToRadians(origin.longitude);
  final latitude1 = degreesToRadians(origin.latitude);
  final bearingRad = degreesToRadians(bearing);
  final radians = lengthToRadians(distance, units: units);

  // Main
  final latitude2 = asin(
    sin(latitude1) * cos(radians) +
        cos(latitude1) * sin(radians) * cos(bearingRad),
  );
  final longitude2 =
      longitude1 +
      atan2(
        sin(bearingRad) * sin(radians) * cos(latitude1),
        cos(radians) - sin(latitude1) * sin(latitude2),
      );
  final lng = radiansToDegrees(longitude2);
  final lat = radiansToDegrees(latitude2);

  return LatLng(lat, lng);
}

/// Takes a [LatLng] and calculates the circle polygon given a radius in
/// degrees, radians, miles, or kilometers; and steps for precision.
@Deprecated('Use circleFeature()')
Map<String, dynamic> circle(
  LatLng center,
  double radius, {
  int steps = 64,
  Units units = Units.kilometers,
}) {
  // main
  final coordinates = [];

  for (var i = 0; i < steps; i++) {
    final point = destination(center, radius, (i * -360) / steps, units: units);
    coordinates.add(point.asGeoJsonCooridnate);
  }

  coordinates.add(coordinates[0]);

  return {
    'type': 'Feature',
    'properties': {},
    'geometry': {
      'coordinates': [coordinates],
      'type': 'Polygon',
    },
  };
}

// Precomputed bearing values for circle generation (32 steps)
final _circleBearings32 = List.generate(
  32,
  (i) => degreesToRadians((i * -360) / 32),
);
final _circleSines32 = _circleBearings32.map((b) => sin(b)).toList();
final _circleCosines32 = _circleBearings32.map((b) => cos(b)).toList();

/// Takes a [LatLng] and calculates the circle polygon given a radius in
/// degrees, radians, miles, or kilometers; and steps for precision.
///
/// Optimized version that precomputes trigonometric values for 32 steps.
GeoJsonFeatureBuilder circleFeature({
  required LatLng center,
  required double radius,
  int steps = 32,
  Units units = Units.kilometers,
}) {
  final polygon = GeoJsonFeatureBuilder(GeoJsonFeatureType.Polygon);
  final List<List<double>> coordinates = [];

  if (steps == 32) {
    // Fast path: use precomputed values
    final longitude1 = degreesToRadians(center.longitude);
    final latitude1 = degreesToRadians(center.latitude);
    final radians = lengthToRadians(radius, units: units);

    final sinLat1 = sin(latitude1);
    final cosLat1 = cos(latitude1);
    final sinRadians = sin(radians);
    final cosRadians = cos(radians);

    // Precompute loop-invariant values
    final sinLat1CosRadians = sinLat1 * cosRadians;
    final cosLat1SinRadians = cosLat1 * sinRadians;

    for (var i = 0; i < 32; i++) {
      final sinBearing = _circleSines32[i];
      final cosBearing = _circleCosines32[i];

      final latitude2 = asin(
        sinLat1CosRadians + cosLat1SinRadians * cosBearing,
      );
      final longitude2 =
          longitude1 +
          atan2(
            sinBearing * cosLat1SinRadians,
            cosRadians - sinLat1 * sin(latitude2),
          );

      coordinates.add([
        radiansToDegrees(longitude2),
        radiansToDegrees(latitude2),
      ]);
    }
  } else {
    // Fallback: original implementation
    for (var i = 0; i < steps; i++) {
      final point = destination(
        center,
        radius,
        (i * -360) / steps,
        units: units,
      );
      coordinates.add(point.asGeoJsonCooridnate);
    }
  }

  coordinates.add(coordinates[0]);

  return polygon.setGeometry(coordinates);
}

bool checkBoxSkip(
  Map<String, Eew> eewLastInfo,
  Map<String, double> eewDist,
  List<List<double>> box,
) {
  bool passed = false;

  for (final eew in eewLastInfo.keys) {
    int skip = 0;
    for (int i = 0; i < 4; i++) {
      final dist = LatLng(
        eewLastInfo[eew]!.info.latitude,
        eewLastInfo[eew]!.info.longitude,
      ).to(LatLng(box[i][1], box[i][0]));

      if (eewDist[eew]! > dist) skip++;
    }
    if (skip >= 4) {
      passed = true;
      break;
    }
  }

  return passed;
}

String? getTownCodeFromCoordinates(LatLng target) {
  final features = Global.townGeojson.features;

  for (final feature in features) {
    if (feature == null) continue;

    final geometry = feature.geometry;
    if (geometry == null) continue;

    bool isInPolygon = false;

    if (geometry is GeoJSONPolygon) {
      final polygon = geometry.coordinates[0];

      bool isInside = false;
      int j = polygon.length - 1;
      for (int i = 0; i < polygon.length; i++) {
        final double xi = polygon[i][0];
        final double yi = polygon[i][1];
        final double xj = polygon[j][0];
        final double yj = polygon[j][1];

        final bool intersect =
            ((yi > target.latitude) != (yj > target.latitude)) &&
            (target.longitude <
                (xj - xi) * (target.latitude - yi) / (yj - yi) + xi);
        if (intersect) isInside = !isInside;

        j = i;
      }
      isInPolygon = isInside;
    }

    if (geometry is GeoJSONMultiPolygon) {
      final multiPolygon = geometry.coordinates;

      for (final polygonCoordinates in multiPolygon) {
        final polygon = polygonCoordinates[0];

        bool isInside = false;
        int j = polygon.length - 1;
        for (int i = 0; i < polygon.length; i++) {
          final double xi = polygon[i][0];
          final double yi = polygon[i][1];
          final double xj = polygon[j][0];
          final double yj = polygon[j][1];

          final bool intersect =
              ((yi > target.latitude) != (yj > target.latitude)) &&
              (target.longitude <
                  (xj - xi) * (target.latitude - yi) / (yj - yi) + xi);
          if (intersect) isInside = !isInside;

          j = i;
        }

        if (isInside) {
          isInPolygon = true;
          break;
        }
      }
    }

    if (isInPolygon) {
      return feature.properties!['CODE']?.toString();
    }
  }

  return null;
}
