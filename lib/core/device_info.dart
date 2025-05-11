import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

mixin DeviceInfo {
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
      final String machineCode = info.utsname.machine;
      model = _iphoneModelMap(machineCode);
      serial = info.identifierForVendor;
      version = info.systemVersion;
    }
  }

  static String _iphoneModelMap(String code) {
    const Map<String, String> iphoneModelMap = {
      'iPhone8,1': 'iPhone 6s',
      'iPhone8,2': 'iPhone 6s Plus',
      'iPhone9,1': 'iPhone 7',
      'iPhone9,2': 'iPhone 7 Plus',
      'iPhone10,1': 'iPhone 8',
      'iPhone10,2': 'iPhone 8 Plus',
      'iPhone10,3': 'iPhone X',
      'iPhone10,4': 'iPhone 8',
      'iPhone10,5': 'iPhone 8 Plus',
      'iPhone10,6': 'iPhone X',
      'iPhone11,2': 'iPhone XS',
      'iPhone11,4': 'iPhone XS Max',
      'iPhone11,6': 'iPhone XS Max',
      'iPhone11,8': 'iPhone XR',
      'iPhone12,1': 'iPhone 11',
      'iPhone12,3': 'iPhone 11 Pro',
      'iPhone12,5': 'iPhone 11 Pro Max',
      'iPhone12,8': 'iPhone SE (2nd Gen)',
      'iPhone13,1': 'iPhone 12 mini',
      'iPhone13,2': 'iPhone 12',
      'iPhone13,3': 'iPhone 12 Pro',
      'iPhone13,4': 'iPhone 12 Pro Max',
      'iPhone14,4': 'iPhone 13 mini',
      'iPhone14,5': 'iPhone 13',
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,6': 'iPhone SE (3rd Gen)',
      'iPhone14,7': 'iPhone 14',
      'iPhone14,8': 'iPhone 14 Plus',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone15,3': 'iPhone 14 Pro Max',
      'iPhone15,4': 'iPhone 14',
      'iPhone15,5': 'iPhone 14 Plus',
      'iPhone16,1': 'iPhone 15',
      'iPhone16,2': 'iPhone 15 Plus',
      'iPhone16,3': 'iPhone 15 Pro',
      'iPhone16,4': 'iPhone 15 Pro Max',
      'iPhone17,3': 'iPhone 16',
      'iPhone17,4': 'iPhone 16 Plus',
      'iPhone17,1': 'iPhone 16 Pro',
      'iPhone17,2': 'iPhone 16 Pro Max',
      'iPhone17,5': 'iPhone 16e',
    };
    return iphoneModelMap[code] ?? code;
  }
}
