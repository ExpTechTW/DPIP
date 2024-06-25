import 'dart:async';

import 'package:geolocator/geolocator.dart';

Future<bool> openLocationSettings() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission != LocationPermission.always) {
    await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      await Geolocator.requestPermission();
      permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        await Geolocator.requestPermission();
        permission = await Geolocator.checkPermission();
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
