/// Android battery-optimization (Doze) exemption — the "省電白名單" onboarding step.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Where a [BatteryOptimization.request] ended up. Named rather than reduced to
/// a bool so the log says which screen the user was actually shown.
enum BatteryScreen {
  /// The package-scoped grant dialog.
  dialog,

  /// The system's list of apps exempt from optimization.
  list,

  /// The app's own settings page — a fallback, not a place that holds the
  /// exemption itself.
  appDetails,

  /// Nothing could be opened.
  none,
}

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

  /// Whether this device has a screen that can actually change the exemption.
  ///
  /// Both the grant dialog and the exemption list count; the app's settings page
  /// does not, because the setting is not there. True where the platform did not
  /// answer, so an older native build keeps the row instead of silently losing
  /// it.
  Future<bool> canOpen() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('canOpen') ?? true;
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'battery canOpen');
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// Opens the narrowest screen that exists and says which one it was.
  ///
  /// Re-check [isIgnoring] afterwards (e.g. on app resume) — the user acts in a
  /// system screen we can't await.
  Future<BatteryScreen> request() async {
    if (!Platform.isAndroid) return BatteryScreen.none;
    try {
      final screen = await _channel.invokeMethod<String>('request');
      return switch (screen) {
        'dialog' => BatteryScreen.dialog,
        'list' => BatteryScreen.list,
        'appDetails' => BatteryScreen.appDetails,
        _ => BatteryScreen.none,
      };
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'battery request');
      return BatteryScreen.none;
    } on MissingPluginException {
      // Unsupported platform / test harness — nothing to do.
      return BatteryScreen.none;
    }
  }
}
