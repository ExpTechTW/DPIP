/// Which builds send diagnostics off the device, and the switch that does it.
library;

import 'dart:io';

import 'package:dpip/core/diagnostics/crash_reporting.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/platform/install_source.dart';
import 'package:dpip/core/platform/render_tier.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:flutter/foundation.dart';

/// Stamped by `.github/workflows/release.yml`: `true` for a snapshot, `false`
/// for a tag. Empty everywhere else.
const String _definedPrerelease = String.fromEnvironment('DPIP_PRERELEASE');

/// Whether this build may send diagnostics: a debug or profile build, or a
/// release build CI marked as a snapshot.
///
/// Positive evidence only. A release-mode build without the mark — a tag, a
/// local `tool/dev/build.sh`, a pull request's CI artifact — is treated as
/// production, because sending from a build that turns out to be production
/// is the failure that cannot be taken back. The label is deliberately not
/// consulted: a local release build is labelled like a snapshot
/// (`lib/core/build_info.g.dart`) without being one.
///
/// The parameters are seams for tests; production callers pass nothing.
bool isPrereleaseBuild({
  bool releaseMode = kReleaseMode,
  String defined = _definedPrerelease,
}) => !releaseMode || defined == 'true';

/// Turns crash reporting on for a prerelease build, and off for every other.
abstract final class PrereleaseDiagnostics {
  static CrashReporter? _reporter;

  /// The reporter, once [start] found this build a prerelease. Null in
  /// production, and before [start] has run.
  static CrashReporter? get reporter => _reporter;

  /// Call once, after Firebase is initialized.
  ///
  /// Production is not a no-op. The SDK persists the collection switch across
  /// launches, so a device that once ran a snapshot keeps sending from the
  /// production build installed over it until something says otherwise —
  /// every launch has to say it. Reports recorded while collection was off are
  /// deleted for the same reason: turning collection on later, by installing a
  /// snapshot, would otherwise upload what was recorded under production.
  ///
  /// The platform's own default is off on both sides (the
  /// `firebase_crashlytics_collection_enabled` meta-data in
  /// AndroidManifest.xml, `FirebaseCrashlyticsCollectionEnabled` in
  /// Info.plist), so nothing is sent before this runs either.
  static Future<void> start({
    required CrashReporter reporter,
    required bool prerelease,
    Future<DeviceDetails?> Function()? device,
  }) async {
    try {
      await reporter.setCollectionEnabled(prerelease);
      if (!prerelease) {
        await reporter.deleteUnsentReports();
        return;
      }
      _reporter = reporter;
      Log.crashSink = ReportingCrashSink(reporter);
      Log.info('crash reports: on (prerelease build)');
      await _describe(reporter, await (device ?? _loadDevice)());
    } catch (error) {
      // Not `Log.handle`: the sink may already be set, and a failure to set up
      // crash reporting reported through crash reporting is how a loop starts.
      Log.warning('crash reports: setup failed: $error');
    }
  }

  /// What a report needs to say about the build and the hardware, set once.
  ///
  /// Crashlytics already records the model and OS version. RAM and the render
  /// tier are what decide which code path a cheap phone took, and they are not
  /// in a report unless put there.
  static Future<void> _describe(
    CrashReporter reporter,
    DeviceDetails? device,
  ) async {
    await AppBuild.ensureLoaded();
    final source = await InstallSourceService.load();
    final keys = <String, Object>{
      'build_label': AppBuild.label,
      'build_code': AppBuild.code,
      'build_mode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
      'install_source': source.name,
      'ram_mb': ?device?.totalMemoryMb,
      'android_sdk': ?device?.sdkInt,
      if (device != null) 'render_tier': renderTierFor(device).name,
    };
    for (final MapEntry(:key, :value) in keys.entries) {
      await reporter.setKey(key, value);
    }
  }

  static Future<DeviceDetails?> _loadDevice() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    try {
      return await DeviceInfoService.load();
    } on Object {
      return null;
    }
  }

  /// Test seam.
  @visibleForTesting
  static void debugReset() => _reporter = null;
}
