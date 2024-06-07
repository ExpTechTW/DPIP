import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openLocationSettings() async {
  const urlIOS = 'app-settings:';

  if (Platform.isAndroid) {
    LocationPermission permission = await Geolocator.checkPermission();
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
  } else if (Platform.isIOS) {
    final uriIOS = Uri.parse(urlIOS);
    if (await canLaunchUrl(uriIOS)) {
      await launchUrl(uriIOS);
      return true;
    } else {
      throw 'Could not launch $urlIOS';
    }
  }

  return false;
}
