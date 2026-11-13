/// Whether the OS will still run this app's background work at all.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// A snapshot of the OS-level throttling that sits *below* permissions.
class BackgroundExecutionStatus {
  const BackgroundExecutionStatus({
    this.restricted = false,
    this.lockedByPolicy = false,
    this.standbyBucket,
    this.manufacturer,
    this.vendorManaged = false,
    this.canOpenSettings = true,
    this.known = false,
  });

  /// Reads the shape both platforms answer with. In one place so the key names
  /// are pinned by a test instead of by two native implementations agreeing.
  factory BackgroundExecutionStatus.fromMap(Map<String, Object?> map) =>
      BackgroundExecutionStatus(
        restricted: map['restricted'] as bool? ?? false,
        lockedByPolicy: map['lockedByPolicy'] as bool? ?? false,
        standbyBucket: map['standbyBucket'] as String?,
        manufacturer: map['manufacturer'] as String?,
        vendorManaged: map['vendorManaged'] as bool? ?? false,
        canOpenSettings: map['canOpenSettings'] as bool? ?? true,
        known: true,
      );

  /// The OS is actively refusing to run this app in the background.
  ///
  /// Android: the user set the app to "Restricted" in battery settings.
  /// iOS: Background App Refresh is off, which stops significant-change and
  /// region events being delivered *at all* — foreground included.
  final bool restricted;

  /// [restricted] because a device-management or parental-control profile says
  /// so, not because the user chose it. There is nothing for them to change, so
  /// the fix button must not be offered.
  final bool lockedByPolicy;

  /// Android's app-standby bucket (`active` … `restricted`), or the iOS
  /// background-refresh state. Diagnosis only — not directly settable, so it is
  /// never presented as something to fix.
  final String? standbyBucket;

  final String? manufacturer;

  /// This manufacturer runs its own battery manager on top of Android, with no
  /// query API and no exemption intent (Samsung, Xiaomi, Huawei, OPPO, vivo …).
  /// Nothing here can measure it; the row exists to tell the user it is there.
  final bool vendorManaged;

  /// Whether this device has a screen that could change the state at all.
  ///
  /// Android's "Restricted" state does not exist below API 28, and a device can
  /// ship without the Settings activity that exposes it (kiosk images, ROMs
  /// that replace Settings). The row's button opens that screen, so where it
  /// cannot be opened the row is a dead end and must not be shown.
  ///
  /// True when the platform did not say otherwise, so an older native build or
  /// a test harness keeps the row rather than silently losing it.
  final bool canOpenSettings;

  /// Whether the platform actually answered. False leaves every field at its
  /// optimistic default, so an unsupported platform or a failed call can never
  /// raise a warning about a state nobody can see.
  final bool known;
}

/// Reads the background-execution state, and opens the screen that governs it.
///
/// This is the layer that makes a device look healthy and report nothing: every
/// permission is granted, the spine says `armed`, and the OS quietly runs none
/// of it. Neither platform raises an event when it changes, so — like the
/// permissions — it is re-read when the app returns to the foreground.
///
/// **Nothing here is a permission.** There is no prompt to await on either
/// platform, only a settings screen, so every caller re-reads on resume rather
/// than trusting a return value.
class BackgroundExecutionService {
  BackgroundExecutionService([MethodChannel? channel])
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/background_execution');

  final MethodChannel _channel;

  Future<BackgroundExecutionStatus> status() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const BackgroundExecutionStatus();
    }
    try {
      final map = await _channel.invokeMapMethod<String, Object?>('status');
      if (map == null) return const BackgroundExecutionStatus();
      return BackgroundExecutionStatus.fromMap(map);
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background execution status');
      return const BackgroundExecutionStatus();
    } on MissingPluginException {
      // Older build without the plugin, or a test harness.
      return const BackgroundExecutionStatus();
    }
  }

  /// Opens the page for the platform's own background-execution switch.
  ///
  /// iOS already exposes that page through the older `openOemSettings` method;
  /// keep using it so an Android-only routing refinement cannot strand iOS.
  Future<String> openSystemSettings() =>
      _open(Platform.isIOS ? 'openOemSettings' : 'openSystemSettings');

  /// Opens the vendor's battery screen where one exists, else app details.
  Future<String> openOemSettings() => _open('openOemSettings');

  Future<String> _open(String method) async {
    if (!Platform.isAndroid && !Platform.isIOS) return 'none';
    try {
      return await _channel.invokeMethod<String>(method) ?? 'none';
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'background execution $method');
      return 'none';
    } on MissingPluginException {
      return 'none';
    }
  }
}
