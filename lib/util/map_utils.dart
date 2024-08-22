import 'dart:math';

import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

List<double> expandBounds(List<double> bounds, LatLng point) {
  // [南西,北東]
  //南
  if (bounds[0] > point.latitude) {
    bounds[0] = point.latitude;
  }
  //西
  if (bounds[1] > point.longitude) {
    bounds[1] = point.longitude;
  }
  //北
  if (bounds[2] < point.latitude) {
    bounds[2] = point.latitude;
  }
  //東
  if (bounds[3] < point.longitude) {
    bounds[3] = point.longitude;
  }

  return bounds;
}

Future<void> loadIntensityImage(MapLibreMapController controller, [bool dark = false]) async {
  for (var i = 1; i < 10; i++) {
    final path = "assets/map/icons/intensity-$i${dark ? "" : "-dark"}.png";

    await controller.addImage("intensity-$i", Uint8List.sublistView(await rootBundle.load(path)));
  }
}

Future<void> loadCrossImage(MapLibreMapController controller) async {
  await controller.addImage("cross", Uint8List.sublistView(await rootBundle.load("assets/map/icons/cross.png")));
}

Future<void> loadGPSImage(MapLibreMapController controller) async {
  await controller.addImage("gps", Uint8List.sublistView(await rootBundle.load("assets/map/icons/gps.png")));
}

Future<void> loadWindImage(MapLibreMapController controller) async {
  await controller.addImage("wind-1", Uint8List.sublistView(await rootBundle.load("assets/map/icons/wind-1.png")));
  await controller.addImage("wind-2", Uint8List.sublistView(await rootBundle.load("assets/map/icons/wind-2.png")));
  await controller.addImage("wind-3", Uint8List.sublistView(await rootBundle.load("assets/map/icons/wind-3.png")));
  await controller.addImage("wind-4", Uint8List.sublistView(await rootBundle.load("assets/map/icons/wind-4.png")));
  await controller.addImage("wind-5", Uint8List.sublistView(await rootBundle.load("assets/map/icons/wind-5.png")));
}

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

/// Converts an angle in degrees to radians
double degreesToRadians(double degrees) {
  final radians = degrees % 360;
  return (radians * pi) / 180;
}

/// Converts an angle in radians to degrees
double radiansToDegrees(double radians) {
  final degrees = radians % (2 * pi);
  return (degrees * 180) / pi;
}

/// Convert a distance measurement (assuming a spherical Earth) from a real-world unit into radians
/// Valid units: miles, nauticalmiles, inches, yards, meters, metres, kilometers, centimeters, feet
double lengthToRadians(double distance, {Units units = Units.kilometers}) {
  final factor = factors[units];
  if (factor == null) {
    throw "$units units is invalid";
  }
  return distance / factor;
}

/// Takes a [LatLng] and calculates the location of a destination point given a distance in
/// degrees, radians, miles, or kilometers; and bearing in degrees.
/// This uses the [Haversine formula](http://en.wikipedia.org/wiki/Haversine_formula) to account for global curvature.
LatLng destination(LatLng origin, double distance, double bearing, {Units units = Units.kilometers}) {
  // Handle input
  final longitude1 = degreesToRadians(origin.longitude);
  final latitude1 = degreesToRadians(origin.latitude);
  final bearingRad = degreesToRadians(bearing);
  final radians = lengthToRadians(distance, units: units);

  // Main
  final latitude2 = asin(sin(latitude1) * cos(radians) + cos(latitude1) * sin(radians) * cos(bearingRad));
  final longitude2 = longitude1 +
      atan2(sin(bearingRad) * sin(radians) * cos(latitude1), cos(radians) - sin(latitude1) * sin(latitude2));
  final lng = radiansToDegrees(longitude2);
  final lat = radiansToDegrees(latitude2);

  return LatLng(lat, lng);
}

/// Takes a [LatLng] and calculates the circle polygon given a radius in
/// degrees, radians, miles, or kilometers; and steps for precision.
Map<String, dynamic> circle(LatLng center, double radius, {int steps = 64, Units units = Units.kilometers}) {
  // main
  final coordinates = [];

  for (var i = 0; i < steps; i++) {
    final point = destination(center, radius, (i * -360) / steps, units: units);
    coordinates.add(point.toGeoJsonCoordinates());
  }

  coordinates.add(coordinates[0]);

  return {
    "type": "Feature",
    "properties": {},
    "geometry": {
      "coordinates": [coordinates],
      "type": "Polygon",
    }
  };
}
