import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:permission_handler/permission_handler.dart';

Future<void> openLocationSettings() async {
  const urlIOS = 'app-settings:';

  if (Platform.isAndroid) {
    var status = await Permission.location.status;
    if (status.isDenied) {
      Permission.location.request();
    }

    status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      Permission.locationWhenInUse.request();
    }

    status = await Permission.locationAlways.status;
    if (status.isDenied) {
      Permission.locationAlways.request();
    } else {
      openAppSettings();
    }
  } else if (Platform.isIOS) {
    final uriIOS = Uri.parse(urlIOS);
    if (await canLaunchUrl(uriIOS)) {
      await launchUrl(uriIOS);
    } else {
      throw 'Could not launch $urlIOS';
    }
  }
}
