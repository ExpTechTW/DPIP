import 'dart:io';


import 'package:url_launcher/url_launcher.dart';

Future<void> openLocationSettings() async {
  const urlAndroid = 'package:com.android.settings';
  const urlIOS = 'app-settings:';

  if (Platform.isAndroid) {
    if (await canLaunchUrl(Uri.parse(urlAndroid))) {
      await launchUrl(Uri.parse(urlAndroid));
    } else {
      throw 'Could not launch $urlAndroid';
    }
  } else if (Platform.isIOS) {
    if (await canLaunchUrl(Uri.parse(urlIOS))) {
      await launchUrl(Uri.parse(urlIOS));
    } else {
      throw 'Could not launch $urlIOS';
    }
  }
}
