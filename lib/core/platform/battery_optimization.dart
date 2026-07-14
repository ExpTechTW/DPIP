/// Android battery-optimization (Doze) exemption — the "省電白名單" onboarding step.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Lets the user exempt DPIP from Android's battery optimization so background
/// disaster reporting keeps running under Doze / OEM battery managers. Android
/// only — a no-op elsewhere (treated as already exempt).
class BatteryOptimization {
  BatteryOptimization([MethodChannel? channel])
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/battery_optimization');

  final MethodChannel _channel;

  /// Whether the app is currently exempt (true on non-Android, where it's n/a).
  Future<bool> isIgnoring() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoring') ?? false;
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'battery isIgnoring');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the system exemption prompt. Re-check [isIgnoring] afterwards (e.g. on
  /// app resume) — the user acts in a system dialog we can't await.
  Future<void> request() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('request');
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'battery request');
    } on MissingPluginException {
      // Unsupported platform / test harness — nothing to do.
    }
  }
}
