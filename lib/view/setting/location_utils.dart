import 'dart:async';

import 'package:geolocator/geolocator.dart';

Future<bool> openLocationSettings() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      return false;
    }
  }
  return true;
}
