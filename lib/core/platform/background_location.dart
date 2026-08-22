/// Starts and stops native, autonomous background device-location reporting.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Hands the platform everything it needs to POST `updateDeviceLocation` on its
/// own when the app is backgrounded or terminated — the Dart isolate isn't
/// running then, so the foreground [DeviceLocationReporter] can't. Native issues
/// the report autonomously, **event-driven** (only on real moves, so a parked
/// device costs nothing):
///   • iOS — **Significant Location Change** + a self-re-centering exit region +
///     visit monitoring (survives termination).
///   • Android — a low-power **EXIT geofence** via the Fused Location Provider,
///     monitored by Google Play services so it survives our process being killed
///     by an OEM battery manager; an independent 10–30 minute alarm repairs
///     silent geofence loss and covers devices without Play services. A durable
///     WorkManager watchdog repairs the alarm path only after it goes overdue.
/// Platform ([platform]: 1 iOS / 0 Android) and app [version] are fixed at
/// construction; only the push token varies per call.
///
/// Caveat the caller must respect: background delivery needs **"Always"
/// location** granted (gate [start] on it — the geofence/SLC can't prompt); iOS
/// requests Always from its plugin.
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

  /// A snapshot of whether background reporting is actually working, for the
  /// developer page. Empty where the channel isn't available.
  ///
  /// Both platforms answer with the same keys, so one UI renders both:
  /// `enabled` (the app asked for it), `authorization` (always / whenInUse /
  /// denied / restricted / notDetermined), `armed` (something is monitoring
  /// **now**), `spine` (which mechanism), `hasToken`, report-attempt/success
  /// timestamps and outcomes, `centreLat` / `centreLng` (where the fence or
  /// region sits) and a free-text `detail` line of platform specifics. Android
  /// additionally exposes throttle skips, the next alarm, and live WorkManager
  /// watchdog state.
  ///
  /// `armed` is the one that matters: every other value can look healthy on a
  /// device that is silently reporting nothing.
  Future<Map<String, Object?>> diagnostics() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'diagnostics',
      );
      return raw ?? const {};
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background location diagnostics');
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  /// Disables background reporting.
  /// Writes everything the native background path recorded into the app's own
  /// log, and clears it.
  ///
  /// A background wake runs in a `BroadcastReceiver` (Android) with no Flutter
  /// isolate, so nothing it does can reach [Log] as it happens — and
  /// `android.util.Log` is logcat, which nobody can read from their own phone.
  /// The Android background path was invisible in the one diagnostic a user is
  /// able to send. Called once at bootstrap, so each line is reported once.
  Future<void> drainBreadcrumbs() async {
    try {
      final lines =
          await _channel.invokeListMethod<String>('drainBreadcrumbs') ??
          const <String>[];
      for (final line in lines) {
        final tab = line.indexOf('\t');
        if (tab < 0) {
          Log.info('background location (native): $line');
          continue;
        }
        final at = int.tryParse(line.substring(0, tab));
        final when = at == null
            ? ''
            : ' at ${DateTime.fromMillisecondsSinceEpoch(at).toIso8601String()}';
        Log.info(
          'background location (native)$when: ${line.substring(tab + 1)}',
        );
      }
    } on MissingPluginException {
      // Unsupported platform / test harness — nothing to drain.
    } on Object catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background location breadcrumbs');
    }
  }

  /// Runs the native report path now, with whatever fix the OS last had.
  ///
  /// Exists so the background path can be exercised without waiting for a
  /// geofence crossing — the wait that made every previous attempt at this bug
  /// untestable.
  Future<void> reportNow() async {
    try {
      await _channel.invokeMethod<void>('reportNow');
    } on Object catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background location reportNow');
    }
  }

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
