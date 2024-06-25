import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openLocationSettings(bool init) async {
  if (Platform.isAndroid) {
    LocationPermission permission = await Geolocator.checkPermission();
    if (init) {
      if (permission == LocationPermission.always) {
        return true;
      }
    } else {
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.deniedForever) {
          Geolocator.openAppSettings();
        }

        if (permission == LocationPermission.whileInUse) {
          Geolocator.openAppSettings();
        }

        if (permission == LocationPermission.always) {
          return true;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Geolocator.openAppSettings();
      }

      if (permission == LocationPermission.whileInUse) {
        Geolocator.openAppSettings();
      }

      if (permission == LocationPermission.always) {
        return true;
      }
    }
  } else if (Platform.isIOS) {
    const urlIOS = 'app-settings:';
    final uriIOS = Uri.parse(urlIOS);
    if (await canLaunchUrl(uriIOS)) {
      await launchUrl(uriIOS);
      return true;
    }
  }
  return false;
}
