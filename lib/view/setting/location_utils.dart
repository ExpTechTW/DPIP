import 'dart:async';

import 'package:geolocator/geolocator.dart';

Future<bool> openLocationSettings() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission != LocationPermission.always) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          return false;
        } else {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
  } else {
    return true;
  }
}
