/// The diagnostics half of a debug dump: what this build, this device and this
/// install currently are.
///
/// **Deliberately English-only.** The labels here are pasted into bug reports
/// and read by maintainers, so a fixed vocabulary is worth more than a
/// localized one — and the values beside them (`arm64`, `release`, an APNs
/// token) never translate anyway.
///
/// It sits in core rather than on the Developer page because two screens ask
/// for it now: the page that renders it row by row, and the More menu's one-tap
/// dump. A second copy would drift, and the copy that drifts is the one being
/// pasted into the bug report.
library;

import 'dart:io';

import 'package:dpip/core/build_info.g.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_execution.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/platform/unused_app_restrictions.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// One labelled diagnostic value. A null value renders as a dash — the field
/// was asked for and the platform had no answer, which is itself information.
typedef DiagnosticsField = ({String label, String? value});

/// A titled group of fields: one card on the Developer page, one `[Heading]`
/// block in a pasted dump.
typedef DiagnosticsSection = ({String title, List<DiagnosticsField> fields});

/// Everything one [DiagnosticsCollector.collect] pass gathered.
///
/// The last four are raw readings the sections already summarise in words; the
/// Developer page draws its charts from them rather than scanning twice.
typedef DiagnosticsReport = ({
  List<DiagnosticsSection> sections,
  List<HourUsage>? usageHistory,
  List<HourUsage>? usageWeek,
  StorageScan storage,
  List<TableStat> tables,
});

/// Labels that never leave the device.
///
/// Dropped rather than starred out: these are the values in the dump that
/// identify a person or authorise a push to them, and a dump is pasted into
/// places its author does not control. One list, because a second copy is a
/// list that drifts — and the copy that drifts is the one that leaks.
const Set<String> diagnosticsRedactedLabels = {
  'Identifier',
  'FCM token',
  'APNs token',
};

/// The sections as the text that gets pasted.
///
/// Labels in [redacted] are dropped entirely rather than starred out: a device
/// identifier and a push token are the two values in here that identify a
/// person, and a dump is pasted into places its author does not control.
String diagnosticsText(
  List<DiagnosticsSection> sections, {
  Set<String> redacted = const {},
}) {
  final buffer = StringBuffer('DPIP diagnostics');
  for (final section in sections) {
    final fields = [
      for (final field in section.fields)
        if (!redacted.contains(field.label)) field,
    ];
    if (fields.isEmpty) continue;
    buffer.writeln('\n[${section.title}]');
    for (final field in fields) {
      buffer.writeln('${field.label}: ${field.value ?? '—'}');
    }
  }
  return buffer.toString().trim();
}

/// Formats a cache hit rate as `NN% (hits/total)`, or a dash when the window
/// saw no cacheable request at all — 0% would read as "the cache is failing".
String _formatRate(double rate, int hits, int total) =>
    total == 0 ? '—' : '${(rate * 100).toStringAsFixed(0)}% ($hits/$total)';

/// A platform bool as text. Null (the platform did not answer, e.g. the channel
/// is absent) is a dash rather than "no": not knowing is not the same as off.
String _yesNo(Object? value) => switch (value) {
  true => 'yes',
  false => 'no',
  _ => '—',
};

/// The last report attempt as `<age> ago · ok (200)`, or why there is none.
///
/// The age matters more than the timestamp: "4 minutes ago" and "6 days ago"
/// are the difference between working and dead, and the failed case is worth
/// showing rather than hiding — a device that fires and gets a 500 needs a
/// different fix from one that never fires.
String _lastReport(Map<String, Object?> d) {
  final at = d['lastReportAt'];
  if (at is! int) return 'never';
  final when = DateTime.fromMillisecondsSinceEpoch(at);
  final age = DateTime.now().difference(when);
  final ok = d['lastReportOk'] == true;
  final code = d['lastReportCode'];
  return '${_age(age)} ago · ${_outcome(ok, code)}';
}

/// A negative code is a reason the request was never made, not an HTTP status.
/// It has to read as one: `failed (-2)` sends whoever pastes it looking for a
/// network fault that never happened.
String _outcome(bool ok, Object? code) => switch (code) {
  -2 => 'no push token',
  -3 => 'no app version',
  -1 => 'could not reach the server',
  final int c when c > 0 => ok ? 'ok ($c)' : 'failed ($c)',
  _ => ok ? 'ok' : 'failed',
};

/// How many times the OS woke the background path, by which spine woke it.
///
/// This is the row that separates the two failures a single `Last report:
/// never` collapses into: the OS never called us, or it called and every call
/// bailed out. They need opposite fixes.
String _wakes(Map<String, Object?> d) {
  final parts = <String>[
    for (final (label, key) in const [
      ('geofence', 'wakeGeofence'),
      ('alarm', 'wakeAlarm'),
      ('boot', 'wakeBoot'),
    ])
      if (d[key] case final int n when n > 0) '$label $n',
  ];
  return parts.isEmpty ? 'never woken' : parts.join(' · ');
}

String _age(Duration d) {
  if (d.inMinutes < 1) return 'moments';
  if (d.inHours < 1) return '${d.inMinutes} min';
  if (d.inDays < 1) return '${d.inHours} h';
  return '${d.inDays} d';
}

/// Where the geofence / region sits, to 4 dp (~11 m — finer than either radius
/// and coarse enough not to be a precise home address in a pasted bug report).
String _centre(Map<String, Object?> d) {
  final lat = d['centreLat'];
  final lng = d['centreLng'];
  if (lat is! double || lng is! double) return '—';
  return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

String get _osName => Platform.isIOS
    ? 'iOS'
    : Platform.isAndroid
    ? 'Android'
    : Platform.operatingSystem;

String get _buildMode {
  if (kReleaseMode) return 'release';
  if (kProfileMode) return 'profile';
  return 'debug';
}

/// Android's hibernation state in the dump's own vocabulary. `unavailable` is
/// reported as "n/a" rather than as a problem: a device too old for the API,
/// or without the Play services that back-port it, has nothing to change.
String _keptActive(UnusedAppRestrictions status) => switch (status) {
  UnusedAppRestrictions.exempt => 'yes',
  UnusedAppRestrictions.restricted => 'NO — will be hibernated',
  UnusedAppRestrictions.unavailable => 'n/a',
};

Future<String?> _fcmToken() async {
  try {
    return await FirebaseMessaging.instance.getToken();
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'dev: FCM token');
    return null;
  }
}

Future<String?> _apnsToken() async {
  try {
    return await FirebaseMessaging.instance.getAPNSToken();
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'dev: APNs token');
    return null;
  }
}

/// Reads every subsystem that can explain a support question.
///
/// Takes its services rather than reaching for a locator, so a test can hand it
/// fakes and so the read happens where the caller decides — the page does it
/// once after its first frame, the More menu does it on the tap.
class DiagnosticsCollector {
  const DiagnosticsCollector({
    required this.notifications,
    required this.database,
    required this.backgroundLocation,
    this.etagCache,
    this.networkUsage,
  });

  final NotificationService notifications;
  final AppDatabase database;
  final BackgroundLocationService backgroundLocation;

  /// Null when the cache database could not be opened — the rows it feeds then
  /// read as dashes rather than zeroes.
  final EtagCacheStore? etagCache;
  final NetworkUsageStore? networkUsage;

  /// One pass over every source. Sequential on purpose: these are cheap reads
  /// that each touch a different subsystem, and running them together only
  /// makes a slow one harder to find.
  Future<DiagnosticsReport> collect() async {
    final info = await PackageInfo.fromPlatform();
    final cacheStats = await etagCache?.stats();
    final usage = await networkUsage?.stats();
    final usageHistory = await networkUsage?.history();
    final usageWeek = await networkUsage?.history(
      hours: 24 * 7,
      bucketHours: 6,
    );
    final storage = await const StorageScanner().scan();
    final tables = await database.tableStats();
    final device = await DeviceInfoService.load();
    final bgLocation = await backgroundLocation.diagnostics();
    // The two states that silently end background reporting while every
    // permission above still reads "granted" — and the two that were missing
    // from the dump people paste when asking why they got no alert.
    final execution = await BackgroundExecutionService().status();
    final unusedApp = await UnusedAppRestrictionsService().status();
    // Track the build by the git commit it was built from (kGitCommit is kept
    // current by the .githooks generator — see tool/setup.sh), falling back to
    // the platform build number outside a repo.
    final buildRef = kGitCommit == 'unknown' ? info.buildNumber : kGitCommit;
    // Show the platform's own push token: FCM on Android, APNs on iOS.
    final fcmToken = Platform.isAndroid
        ? (notifications.token ?? await _fcmToken())
        : null;
    final apnsToken = Platform.isIOS ? await _apnsToken() : null;

    final sections = <DiagnosticsSection>[
      (
        title: 'App',
        fields: [
          // The build's own name — `26w33a`, `26.1` — which is the only
          // version a user is ever asked for and the only one that is unique
          // per build. It appears nowhere else: Apple is told the train
          // (`26.1.0`) because it rejects anything with a letter in it, so
          // every snapshot looks identical in TestFlight and in Settings →
          // General → About. This row is where a tester finds out which one
          // they actually have.
          (label: 'Version', value: AppBuild.label),
          // What the platform believes, kept beside it: it is what App Store
          // Connect and Play show, so a support conversation needs both.
          (
            label: 'Store version',
            value: '${info.version} (${info.buildNumber})',
          ),
          (label: 'Build', value: buildRef),
          (label: 'Build mode', value: _buildMode),
        ],
      ),
      (
        title: 'Platform',
        fields: [
          (label: 'OS', value: _osName),
          (label: 'OS version', value: device.osVersion),
          if (device.sdkInt != null)
            (label: 'Android API level', value: '${device.sdkInt}'),
          (label: 'Locale', value: Platform.localeName),
        ],
      ),
      (
        title: 'Device',
        fields: [
          (label: 'Manufacturer', value: device.manufacturer),
          (label: 'Model', value: device.model),
          (label: 'Identifier', value: device.identifier),
        ],
      ),
      (
        title: 'Push',
        fields: [
          if (Platform.isAndroid) (label: 'FCM token', value: fcmToken),
          if (Platform.isIOS) (label: 'APNs token', value: apnsToken),
        ],
      ),
      // Whether the app is still being told where the device is while it is
      // closed — which is what decides whether a disaster alert reaches the
      // right township. Every value here comes from the platform rather than
      // from what Dart believes it asked for: the failure this exists to catch
      // is precisely the one where the app thinks it armed something and the OS
      // is delivering nothing. `Armed` is the answer that matters; the rest
      // says why it is what it is.
      (
        title: 'Background location',
        fields: [
          (label: 'Requested', value: _yesNo(bgLocation['enabled'])),
          (
            label: 'Authorization',
            value: bgLocation['authorization'] as String?,
          ),
          (label: 'Armed', value: _yesNo(bgLocation['armed'])),
          // Why nothing is armed, when that is the answer. Without it the rows
          // above read "Requested: yes / Armed: no" and stop, which is the
          // shape this bug arrived in: a state with no stated cause.
          if (bgLocation['blocked'] != null)
            (label: 'Blocked by', value: bgLocation['blocked'] as String?),
          (label: 'Spine', value: bgLocation['spine'] as String?),
          (label: 'Push token held', value: _yesNo(bgLocation['hasToken'])),
          // Wakes and reports are separate counts on purpose. "Woke 40 times,
          // reported never" and "never woke" are different faults with
          // different fixes, and a single last-report row cannot tell them
          // apart — it says `never` for both.
          (label: 'Wakes', value: _wakes(bgLocation)),
          if (bgLocation['lastGeofenceError'] != null)
            (
              label: 'Geofence error',
              value: bgLocation['lastGeofenceError'] as String?,
            ),
          (label: 'Last report', value: _lastReport(bgLocation)),
          (label: 'Centred on', value: _centre(bgLocation)),
          (label: 'Detail', value: bgLocation['detail'] as String?),
          (
            label: 'Background execution',
            value: !execution.known
                ? 'unknown'
                : execution.restricted
                ? (execution.lockedByPolicy
                      ? 'blocked by policy'
                      : 'RESTRICTED')
                : 'allowed',
          ),
          if (execution.standbyBucket != null)
            (label: 'Standby bucket', value: execution.standbyBucket),
          (label: 'Kept active', value: _keptActive(unusedApp)),
          if (execution.vendorManaged)
            (
              label: 'Vendor power manager',
              value:
                  '${execution.manufacturer} — not detectable, check by hand',
            ),
        ],
      ),
      (
        title: 'ETag cache',
        fields: [
          (
            label: 'Entries',
            value: cacheStats == null ? '—' : '${cacheStats.rows}',
          ),
          (
            label: 'Size on disk',
            value: cacheStats == null ? '—' : formatBytes(cacheStats.bytes),
          ),
        ],
      ),
      // Which table is actually costing the space. "The database is 40 MB" is
      // not something anyone can act on; "mesh_node_metrics is 38 MB across
      // 900,000 rows" names both the table and the retention window that is
      // wrong.
      (
        title: 'SQLite tables',
        fields: [
          (label: 'Tables', value: '${tables.length} across two files'),
          (label: 'Rows', value: '${tables.fold(0, (sum, t) => sum + t.rows)}'),
          (
            label: 'Measured',
            value: tables.isEmpty
                ? '—'
                : tables.first.onDisk
                ? 'on-disk pages (dbstat)'
                // Says so explicitly: the payload sum excludes indexes and
                // page overhead, so it reads lower than the file itself and
                // the difference is not a leak.
                : 'payload only (no dbstat)',
          ),
        ],
      ),
      // What iOS Settings ("文件與資料") and Android Settings report, split
      // into the app's own categories. The SQLite body budget (350 MB) is not
      // the whole story — the DB file carries page overhead and the OS-level
      // caches are separate.
      (
        title: 'Storage',
        fields: [
          (label: 'Total on disk', value: formatBytes(storage.totalBytes)),
          for (final slice in storageBreakdown(storage))
            (
              label: slice.label,
              value:
                  '${formatBytes(slice.bytes)} '
                  '(${(slice.bytes / storage.totalBytes * 100).toStringAsFixed(1)}%)',
            ),
          // Why the total is what it is: the biggest individual files. A
          // runaway in tmp (MapLibre's transient tile work, aborted native
          // writes) shows up here by name long before the pie chart explains
          // anything.
          if (storage.files.isNotEmpty) ...[
            (label: 'Largest files', value: null),
            for (final file in storage.files.take(8))
              (label: file.shortPath, value: formatBytes(file.bytes)),
          ],
        ],
      ),
      // Every figure here is the same pair of trailing windows, so they can be
      // read against each other.
      (
        title: 'Network usage',
        fields: [
          (
            label: 'Downloaded · last 24h',
            value: usage == null ? '—' : formatBytes(usage.last24h),
          ),
          (
            label: 'Downloaded · last 7d',
            value: usage == null ? '—' : formatBytes(usage.last7d),
          ),
          (
            label: 'Traffic saved · last 24h',
            value: usage == null ? '—' : formatBytes(usage.saved24h),
          ),
          (
            label: 'Traffic saved · last 7d',
            value: usage == null ? '—' : formatBytes(usage.saved7d),
          ),
          (
            label: 'Hit rate · last 24h',
            value: usage == null
                ? '—'
                : _formatRate(usage.hitRate24h, usage.hits24h, usage.total24h),
          ),
          (
            label: 'Hit rate · last 7d',
            value: usage == null
                ? '—'
                : _formatRate(usage.hitRate7d, usage.hits7d, usage.total7d),
          ),
        ],
      ),
    ];
    return (
      sections: sections,
      usageHistory: usageHistory,
      usageWeek: usageWeek,
      storage: storage,
      tables: tables,
    );
  }
}
