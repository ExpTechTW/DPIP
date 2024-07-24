import 'dart:typed_data';

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
