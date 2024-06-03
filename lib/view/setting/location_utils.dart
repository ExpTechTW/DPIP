import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:geolocator/geolocator.dart';

Future<bool> openLocationSettings() async {
  if (Platform.isAndroid || Platform.isIOS) {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          AppSettings.openAppSettings();
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
  }
  return false;
}
