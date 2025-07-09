import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';

Future<void> updateInfoToServer() async {
  if (Preference.notifyToken != '' &&
      DateTime.now().millisecondsSinceEpoch - (Preference.lastUpdateToServerTime ?? 0) > 86400 * 1 * 1000) {
    final random = Random();

    final int rand = random.nextInt(2);

    if (rand != 0) return;

    ExpTech().updateDeviceLocation(
      token: Preference.notifyToken,
      lat: Preference.locationLatitude.toString(),
      lng: Preference.locationLongitude.toString(),
    );
  }
}
