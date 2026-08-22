/// Opens this app's page in the system settings.
///
/// One implementation, because the alternatives are not equivalent and one of
/// them does not work. `awesome_notifications`' own settings page silently did
/// nothing on iOS — the call returned, logged, and no navigation happened —
/// which turned the "Open Settings" button into the second dead end in the
/// same flow. `permission_handler` is the canonical cross-platform route
/// (`UIApplication.openSettingsURLString` on iOS, the app-details intent on
/// Android) and is already a dependency.
///
/// Every permission surface routes through here, so the button either works
/// everywhere or fails everywhere — never one row silently.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Android destinations and labels that the cross-platform permission plugin
/// cannot express. Public for a narrow MethodChannel test seam.
class AndroidPermissionSettings {
  AndroidPermissionSettings([MethodChannel? channel])
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/permission_settings');

  final MethodChannel _channel;

  /// The device-localized Settings choice for background access (Android 11+).
  Future<String?> backgroundLocationOptionLabel() async {
    try {
      return await _channel.invokeMethod<String>(
        'backgroundLocationOptionLabel',
      );
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background location option label');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens DPIP's own notification switch rather than generic app details.
  Future<String> openNotificationSettings() async {
    try {
      return await _channel.invokeMethod<String>('openNotificationSettings') ??
          'none';
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'notification settings');
      return 'none';
    } on MissingPluginException {
      return 'none';
    }
  }
}

final AndroidPermissionSettings _androidSettings = AndroidPermissionSettings();

/// Returns whether the settings page was actually opened, which is the part
/// worth logging: a `false` here is the difference between "the user chose not
/// to grant it" and "the button does nothing".
Future<bool> openAppSettingsPage() async {
  try {
    final opened = await ph.openAppSettings();
    Log.info('permission: openAppSettings -> $opened');
    return opened;
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'openAppSettings');
    return false;
  }
}

/// Opens the narrowest notification destination available on each platform.
Future<bool> openNotificationSettingsPage() async {
  if (!Platform.isAndroid) return openAppSettingsPage();
  final destination = await _androidSettings.openNotificationSettings();
  if (destination != 'none') {
    Log.info('permission: notification settings -> $destination');
    return true;
  }
  return openAppSettingsPage();
}

/// Returns Android's own localized background-location choice when available.
Future<String?> backgroundLocationOptionLabel() => Platform.isAndroid
    ? _androidSettings.backgroundLocationOptionLabel()
    : Future<String?>.value();
