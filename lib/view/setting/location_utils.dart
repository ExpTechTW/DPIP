import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openLocationSettings() async {
  if (Platform.isAndroid) {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always) {
      return true;
    } else {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always) {
        return true;
      } else {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always) {
          return true;
        } else {
          return false;
        }
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
