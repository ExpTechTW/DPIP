import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

Future<void> openLocationSettings() async {
  const urlAndroid = 'intent://#Intent;action=android.settings.LOCATION_SOURCE_SETTINGS;end';
  const urlIOS = 'app-settings:';

  if (Platform.isAndroid) {
    final uriAndroid = Uri.parse(urlAndroid);
    if (await canLaunchUrl(uriAndroid)) {
      await launchUrl(uriAndroid, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $urlAndroid';
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
