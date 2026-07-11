import 'dart:io';

import 'package:flutter/services.dart';

/// Immutable snapshot of the host device.
class DeviceDetails {
  const DeviceDetails({
    required this.model,
    required this.osVersion,
    this.identifier,
  });

  /// Marketing model name (iOS) or `Build.MODEL` (Android).
  final String model;

  /// OS version string (iOS `systemVersion`, Android SDK int as string).
  final String osVersion;

  /// Vendor identifier (iOS `identifierForVendor`) or Android ID; may be null.
  final String? identifier;
}

/// Native device-info accessor backed by a platform [MethodChannel], replacing
/// the `device_info_plus` package.
///
/// The native side returns raw values only; the iOS machine-code → marketing
/// name lookup lives here in Dart so it can be updated without a native
/// rebuild.
abstract final class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/device_info',
  );

  /// Reads the current device details from the platform.
  static Future<DeviceDetails> load() async {
    final raw =
        await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo') ??
        const <String, dynamic>{};
    final model = (raw['model'] as String?) ?? 'Unknown';
    final osVersion = (raw['osVersion'] as String?) ?? '';
    final identifier = raw['identifier'] as String?;

    return DeviceDetails(
      model: Platform.isIOS ? (_iPhoneNames[model] ?? model) : model,
      osVersion: osVersion,
      identifier: identifier,
    );
  }

  /// Maps an iOS `utsname.machine` identifier to its marketing name.
  static const Map<String, String> _iPhoneNames = {
    // iPhone
    'iPhone8,1': 'iPhone 6s',
    'iPhone8,2': 'iPhone 6s Plus',
    'iPhone8,4': 'iPhone SE (1st Gen)',
    'iPhone9,1': 'iPhone 7',
    'iPhone9,3': 'iPhone 7',
    'iPhone9,2': 'iPhone 7 Plus',
    'iPhone9,4': 'iPhone 7 Plus',
    'iPhone10,1': 'iPhone 8',
    'iPhone10,4': 'iPhone 8',
    'iPhone10,2': 'iPhone 8 Plus',
    'iPhone10,5': 'iPhone 8 Plus',
    'iPhone10,3': 'iPhone X',
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
    'iPhone15,4': 'iPhone 15',
    'iPhone15,5': 'iPhone 15 Plus',
    'iPhone16,1': 'iPhone 15 Pro',
    'iPhone16,2': 'iPhone 15 Pro Max',
    'iPhone17,3': 'iPhone 16',
    'iPhone17,4': 'iPhone 16 Plus',
    'iPhone17,1': 'iPhone 16 Pro',
    'iPhone17,2': 'iPhone 16 Pro Max',
    'iPhone17,5': 'iPhone 16e',
  };
}
