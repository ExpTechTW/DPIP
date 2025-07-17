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
    const groupedModels = <List<String>, String>{
      ['iPhone8,1']: 'iPhone 6s',
      ['iPhone8,2']: 'iPhone 6s Plus',
      ['iPhone8,4']: 'iPhone SE\n(1st Gen)',
      ['iPhone9,1', 'iPhone9,3']: 'iPhone 7',
      ['iPhone9,2', 'iPhone9,4']: 'iPhone 7 Plus',
      ['iPhone10,1', 'iPhone10,4']: 'iPhone 8',
      ['iPhone10,2', 'iPhone10,5']: 'iPhone 8 Plus',
      ['iPhone10,3', 'iPhone10,6']: 'iPhone X',
      ['iPhone11,2']: 'iPhone XS',
      ['iPhone11,4', 'iPhone11,6']: 'iPhone XS Max',
      ['iPhone11,8']: 'iPhone XR',
      ['iPhone12,1']: 'iPhone 11',
      ['iPhone12,3']: 'iPhone 11 Pro',
      ['iPhone12,5']: 'iPhone 11 Pro Max',
      ['iPhone12,8']: 'iPhone SE\n(2nd Gen)',
      ['iPhone13,2']: 'iPhone 12',
      ['iPhone13,1']: 'iPhone 12 mini',
      ['iPhone13,3']: 'iPhone 12 Pro',
      ['iPhone13,4']: 'iPhone 12 Pro Max',
      ['iPhone14,5']: 'iPhone 13',
      ['iPhone14,4']: 'iPhone 13 mini',
      ['iPhone14,2']: 'iPhone 13 Pro',
      ['iPhone14,3']: 'iPhone 13 Pro Max',
      ['iPhone14,6']: 'iPhone SE\n(3rd Gen)',
      ['iPhone14,7']: 'iPhone 14',
      ['iPhone14,8']: 'iPhone 14 Plus',
      ['iPhone15,2']: 'iPhone 14 Pro',
      ['iPhone15,3']: 'iPhone 14 Pro Max',
      ['iPhone15,4']: 'iPhone 15',
      ['iPhone15,5']: 'iPhone 15 Plus',
      ['iPhone16,1']: 'iPhone 15 Pro',
      ['iPhone16,2']: 'iPhone 15 Pro Max',
      ['iPhone17,3']: 'iPhone 16',
      ['iPhone17,4']: 'iPhone 16 Plus',
      ['iPhone17,1']: 'iPhone 16 Pro',
      ['iPhone17,2']: 'iPhone 16 Pro Max',
      ['iPhone17,5']: 'iPhone 16e',

      // iPad
      ['iPad6,11', 'iPad6,12']: 'iPad 5',
      ['iPad7,5', 'iPad7,6']: 'iPad 6',
      ['iPad7,11', 'iPad7,12']: 'iPad 7',
      ['iPad11,6', 'iPad11,7']: 'iPad 8',
      ['iPad12,1', 'iPad12,2']: 'iPad 9',
      ['iPad13,18', 'iPad13,19']: 'iPad 10',
      ['iPad15,7', 'iPad15,8']: 'iPad 11',
      // iPad Air
      ['iPad5,3', 'iPad5,4']: 'iPad Air 2',
      ['iPad11,3', 'iPad11,4']: 'iPad Air 3',
      ['iPad13,1', 'iPad13,2']: 'iPad Air 4',
      ['iPad13,16', 'iPad13,17']: 'iPad Air 5',
      ['iPad14,8', 'iPad14,9']: 'iPad Air 11-Inch M2',
      ['iPad14,10', 'iPad14,11']: 'iPad Air 13-Inch M2',
      ['iPad15,3', 'iPad15,4']: 'iPad Air 11-Inch M3',
      ['iPad15,5', 'iPad15,6']: 'iPad Air 13-Inch M3',
      // iPad Mini
      ['iPad5,1', 'iPad5,2']: 'iPad Mini 4',
      ['iPad11,1', 'iPad11,2']: 'iPad Mini 5',
      ['iPad14,1', 'iPad14,2']: 'iPad Mini 6',
      ['iPad16,1', 'iPad16,2']: 'iPad Mini 7',
      // iPad Pro
      ['iPad6,3', 'iPad6,4']: 'iPad Pro 9-Inch',
      ['iPad7,3', 'iPad7,4']: 'iPad Pro 10-Inch',
      ['iPad8,1', 'iPad8,2', 'iPad8,3', 'iPad8,4']: 'iPad Pro 11-Inch',
      ['iPad8,9', 'iPad8,10']: 'iPad Pro 11-Inch 2',
      ['iPad13,4', 'iPad13,5', 'iPad13,6', 'iPad13,7']: 'iPad Pro 11-Inch 3',
      ['iPad14,3', 'iPad14,4']: 'iPad Pro 11-Inch 4',
      ['iPad16,3', 'iPad16,4']: 'iPad Pro 11-Inch (M4)',
      ['iPad6,7', 'iPad6,8']: 'iPad Pro 12-Inch',
      ['iPad7,1', 'iPad7,2']: 'iPad Pro 12-Inch 2',
      ['iPad8,5', 'iPad8,6', 'iPad8,7', 'iPad8,8']: 'iPad Pro 12-Inch 3',
      ['iPad8,11', 'iPad8,12']: 'iPad Pro 12-Inch 4',
      ['iPad13,8', 'iPad13,9', 'iPad13,10', 'iPad13,11']: 'iPad Pro 12-Inch 5',
      ['iPad14,5', 'iPad14,6']: 'iPad Pro 12-Inch 6',
      ['iPad16,5', 'iPad16,6']: 'iPad Pro 13-Inch (M4)',
    };
    for (final entry in groupedModels.entries) {
      if (entry.key.contains(code)) {
        return entry.value;
      }
    }
    return code;
  }
}
