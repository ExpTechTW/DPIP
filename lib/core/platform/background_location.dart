/// Starts and stops native, autonomous background device-location reporting.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Hands the platform everything it needs to POST `updateDeviceLocation` on its
/// own when the app is backgrounded or terminated — the Dart isolate isn't
/// running then, so the foreground [DeviceLocationReporter] can't. Native issues
/// the report autonomously: iOS via **Significant Location Change** (survives
/// termination), Android via a self-rescheduling **alarm whose interval adapts
/// to movement** (short when moving, backing off to an hour when still) — far
/// gentler on the battery than a continuous foreground service. Platform
/// ([platform]: 1 iOS / 0 Android) and app [version] are fixed at construction;
/// only the push token varies per call.
///
/// Android caveats the caller must respect: the alarm can only fetch a fix with
/// **background ("Always") location** granted (gate [start] on it — the alarm
/// can't prompt), and Doze throttles the cadence to a ~9-minute floor, so the
/// short "moving" interval is best-effort. iOS requests Always from its plugin.
///
/// Best-effort: a platform failure is logged, never thrown, so it can't block
/// launch, and a missing channel (e.g. in tests / unsupported platform) is a
/// no-op.
class BackgroundLocationService {
  BackgroundLocationService({
    required this._platform,
    required this._version,
    MethodChannel? channel,
  }) : _channel =
           channel ??
           const MethodChannel('com.exptech.dpip/background_location');

  final int _platform;
  final String _version;
  final MethodChannel _channel;

  /// Enables background reporting bound to the device push [token].
  Future<void> start(String token) async {
    try {
      await _channel.invokeMethod<void>('start', {
        'platform': _platform,
        'token': token,
        'version': _version,
      });
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background location start');
    } on MissingPluginException {
      // Unsupported platform / test harness — nothing to start.
    }
  }

  /// Disables background reporting.
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background location stop');
    } on MissingPluginException {
      // No-op where unavailable.
    }
  }
}
