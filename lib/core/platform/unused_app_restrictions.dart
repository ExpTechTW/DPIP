/// Android's unused-app restrictions — permission auto-reset and hibernation.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// What Android will do to DPIP if the user stops opening it.
enum UnusedAppRestrictions {
  /// The user has turned restrictions off for this app. Background reporting
  /// survives however long they leave it alone.
  exempt,

  /// Restrictions are on: Android will revoke the runtime permissions after a
  /// few months of no interaction, and from Android 12 force-stop the package
  /// as well.
  restricted,

  /// This device cannot say — not Android, too old, no Play services to
  /// back-port it, or the query failed. Must be presented as "nothing to do
  /// here", never as a problem: it is not one the user could act on.
  unavailable,
}

/// The Android-version-specific control the official intent opens near.
enum UnusedAppSettingsGuide { pause, freeSpace, revoke, playProtect }

/// Reports and opens Android's unused-app-restrictions setting.
///
/// This is the failure mode that hits exactly the users background reporting
/// exists for: someone installs DPIP, grants "Allow all the time", and never
/// opens it again because no disaster has happened. Months later Android
/// revokes the location permission and — from Android 12 — force-stops the
/// package. Neither the geofence nor the fallback alarm survives that, and a
/// force-stopped package receives no broadcasts at all until the user launches
/// it by hand, so not even the boot re-arm brings it back.
///
/// It is **not** a permission and cannot be requested: the exemption is a
/// system toggle, so all this can do is report the state and open the page.
/// Distinct from the battery-optimization exemption, which covers Doze and does
/// nothing about this.
class UnusedAppRestrictionsService {
  UnusedAppRestrictionsService([MethodChannel? channel])
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/unused_app_restrictions');

  final MethodChannel _channel;

  /// The current state. Anything other than Android is [unavailable] — iOS has
  /// no equivalent, and its background location survives an unused app.
  Future<UnusedAppRestrictions> status() async {
    if (!Platform.isAndroid) return UnusedAppRestrictions.unavailable;
    try {
      final value = await _channel.invokeMethod<String>('status');
      return switch (value) {
        'exempt' => UnusedAppRestrictions.exempt,
        'restricted' => UnusedAppRestrictions.restricted,
        _ => UnusedAppRestrictions.unavailable,
      };
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'unused app restrictions status');
      return UnusedAppRestrictions.unavailable;
    } on MissingPluginException {
      return UnusedAppRestrictions.unavailable;
    }
  }

  Future<UnusedAppSettingsGuide> guide() async {
    if (!Platform.isAndroid) return UnusedAppSettingsGuide.pause;
    try {
      return switch (await _channel.invokeMethod<String>('guide')) {
        'freeSpace' => UnusedAppSettingsGuide.freeSpace,
        'revoke' => UnusedAppSettingsGuide.revoke,
        'playProtect' => UnusedAppSettingsGuide.playProtect,
        _ => UnusedAppSettingsGuide.pause,
      };
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'unused app restrictions guide');
      return UnusedAppSettingsGuide.pause;
    } on MissingPluginException {
      return UnusedAppSettingsGuide.pause;
    }
  }

  /// Opens the system page where the exemption lives. Re-check [status] on
  /// resume — the user acts in a settings screen we can't await.
  Future<bool> openSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openSettings') ?? false;
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'unused app restrictions openSettings');
      return false;
    } on MissingPluginException {
      // Unsupported platform / test harness — nothing to open.
      return false;
    }
  }
}
