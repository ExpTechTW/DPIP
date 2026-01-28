import 'dart:async';
import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Future<void> updateInfoToServer() async {
  final latitude = Preference.locationLatitude;
  final longitude = Preference.locationLongitude;

  try {
    if (latitude == null || longitude == null) return;
    if (Preference.notifyToken != '' &&
        DateTime.now().millisecondsSinceEpoch -
                (Preference.lastUpdateToServerTime ?? 0) >
            86400 * 1 * 1000) {
      final random = Random();
      final int rand = random.nextInt(2);

      if (rand != 0) return;

      ExpTech().updateDeviceLocation(
        token: Preference.notifyToken,
        coordinates: LatLng(latitude, longitude),
      );
    }
  } catch (e) {
    print('Network info update failed: $e');
  }
}
