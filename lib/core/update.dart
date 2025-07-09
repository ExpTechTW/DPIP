import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';

Future<void> updateInfoToServer() async {
  int now = DateTime.now().millisecondsSinceEpoch;
  if (Preference.notifyToken != '' && now - (Preference.lastUpdateToServerTime ?? 0) > 86400 * 3 * 1000) {
    ExpTech().updateDeviceLocation(
      token: Preference.notifyToken,
      lat: Preference.locationLatitude.toString(),
      lng: Preference.locationLongitude.toString(),
    );
    Preference.lastUpdateToServerTime = now;
  }
}
