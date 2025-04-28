import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  static late String model;
  static late String version;
  static String? serial;

  static Future init() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      model = info.model;
      serial = info.serialNumber;
      version = info.version.sdkInt.toString();
    }
    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      model = info.model;
      serial = info.identifierForVendor;
      version = info.systemVersion;
    }
  }
}
