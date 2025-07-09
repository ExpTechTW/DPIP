import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';

Future<void> updateInfoToServer() async {
  final int now = DateTime.now().millisecondsSinceEpoch;

  if (Preference.notifyToken != '' && now - (Preference.lastUpdateToServerTime ?? 0) > 86400 * 1 * 1000) {
    final random = Random();

    final int rand = random.nextInt(3);

    if (rand != 0) return;

    ExpTech().updateDeviceLocation(
      token: Preference.notifyToken,
      lat: Preference.locationLatitude.toString(),
      lng: Preference.locationLongitude.toString(),
    );
    Preference.lastUpdateToServerTime = now;
  }
}
