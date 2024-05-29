import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:permission_handler/permission_handler.dart';

Future<bool> openLocationSettings() async {
  const urlIOS = 'app-settings:';

  if (Platform.isAndroid) {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      if (await Permission.locationWhenInUse.request().isDenied) {
        return false;
      } else {
        status = await Permission.locationAlways.status;
        if (status.isDenied) {
          if (await Permission.locationAlways.request().isDenied) {
            return false;
          } else {
            return true;
          }
        }
      }
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
