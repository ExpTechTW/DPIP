/// Developer diagnostics: platform, device, app, and push-token details for
/// support and debugging. The app-bar copies a redacted dump (no device
/// identifier / push tokens); on-screen values stay visible for inspection.
///
/// **Deliberately English-only.** This page exists to be screenshotted into a
/// bug report or pasted to a maintainer, so a fixed vocabulary is worth more
/// than a localized one — and the values beside the labels (`arm64`, `release`,
/// an APNs token) never translate anyway.
library;

import 'dart:io';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/build_info.g.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/features/settings/presentation/widgets/network_usage_chart.dart';
import 'package:dpip/features/settings/presentation/widgets/storage_breakdown.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// One labelled diagnostic value.
typedef _Field = ({String label, String? value});

/// Shared by the row, the dialog title, and its confirm button.
const String _clearCacheTitle = 'Clear cache';

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
  final outcome = ok ? 'ok' : 'failed';
  final suffix = code is int && code > 0 ? ' ($code)' : '';
  return '${_age(age)} ago · $outcome$suffix';
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

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  List<({String title, List<_Field> fields})>? _sections;
  List<HourUsage>? _usageHistory;
  List<HourUsage>? _usageWeek;
  StorageScan? _storage;
  List<TableStat>? _tables;
  bool _clearing = false;

  /// Version-row taps toward the experimental unlock. Deliberately not
  /// persisted — a fresh app start re-arms the easter egg.
  static const int _unlockVersionTaps = 10;
  int _versionTaps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    // Capture provided services before any await.
    final notifications = context.read<NotificationService>();
    final etagCache = context.read<EtagCacheStore?>();
    final networkUsage = context.read<NetworkUsageStore?>();
    final database = context.read<AppDatabase>();
    final backgroundLocation = context.read<BackgroundLocationService>();

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
    // Track the build by the git commit it was built from (kGitCommit is kept
    // current by the .githooks generator — see tool/setup.sh), falling back to
    // the platform build number outside a repo.
    final buildRef = kGitCommit == 'unknown' ? info.buildNumber : kGitCommit;
    // Show the platform's own push token: FCM on Android, APNs on iOS.
    final fcmToken = Platform.isAndroid
        ? (notifications.token ?? await _fcmToken())
        : null;
    final apnsToken = Platform.isIOS ? await _apnsToken() : null;

    final sections = <({String title, List<_Field> fields})>[
      (
        title: 'App',
        fields: [
          (label: 'Version', value: info.version),
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
          (label: 'Spine', value: bgLocation['spine'] as String?),
          (label: 'Push token held', value: _yesNo(bgLocation['hasToken'])),
          (label: 'Last report', value: _lastReport(bgLocation)),
          (label: 'Centred on', value: _centre(bgLocation)),
          (label: 'Detail', value: bgLocation['detail'] as String?),
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
    if (mounted) {
      setState(() {
        _sections = sections;
        _usageHistory = usageHistory;
        _usageWeek = usageWeek;
        _storage = storage;
        _tables = tables;
      });
    }
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

  /// Empties the cache **and** the accounting that describes it.
  ///
  /// Both, always: leaving a 92% hit rate next to an empty store would describe
  /// a cache that no longer exists, and the numbers are the reason to press
  /// this in the first place.
  ///
  /// Confirmed first — nothing is lost permanently, but everything the map
  /// shows has to be downloaded again, and that is the user's data allowance.
  Future<void> _confirmClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(_clearCacheTitle),
        content: const Text(
          'Stored map tiles and API responses will be deleted and downloaded '
          'again next time they are needed. The database file is compacted '
          'and the OS-level HTTP cache is cleared as well. Traffic and '
          'hit-rate figures reset to zero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(_clearCacheTitle),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final etagCache = context.read<EtagCacheStore?>();
    final networkUsage = context.read<NetworkUsageStore?>();
    final tiles = context.read<MapTileCache?>();
    setState(() => _clearing = true);
    try {
      await etagCache?.clear();
      // SQLite keeps free pages after a delete, so the file stays fat until
      // compacted — the user asked to reclaim space, not just to empty rows.
      await etagCache?.compact();
      await networkUsage?.clear();
      // The mirror would otherwise keep serving bytes the store no longer has,
      // so "cleared" would not look cleared until the app restarted.
      await tiles?.evict(const []);
      // MapLibre's own ambient DB is separate — poisoned immutable tiles
      // (e.g. bad Content-Encoding) survive SQLite clears otherwise.
      await clearAmbientCache();
      // The OS-level HTTP cache is invisible to every clear above — iOS
      // NSURLCache keeps its own copy of responses behind the app's back.
      await const StorageScanner().clearSystemHttpCache();
      // iOS tmp is where transient native work (MapLibre tile handling,
      // aborted snapshot writes) accumulates — nothing the app owns lives
      // there, so it can be dropped wholesale.
      await const StorageScanner().clearTmp();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'dev: clear cache');
    }
    if (!mounted) return;
    setState(() => _clearing = false);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Cache cleared')));
  }

  /// Labels omitted from the clipboard dump (still shown on screen).
  static const _redactedCopyLabels = {'Identifier', 'FCM token', 'APNs token'};

  /// Labels that get their own copy button — long push tokens are the one
  /// case worth lifting out of a diagnostics screenshot on their own; every
  /// other row is still covered by "Copy all".
  static const _individuallyCopyableLabels = {'FCM token', 'APNs token'};

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  /// Version-row taps: count to [_unlockVersionTaps], then unlock the
  /// experimental-features menu (see `ExperimentalSettings.unlock`). Shows the
  /// remaining count so the easter egg is discoverable, and confirms once it
  /// flips.
  void _onVersionTap() {
    final settings = context.read<ExperimentalSettings>();
    if (settings.unlocked) {
      _showHint('Experimental features are already unlocked');
      return;
    }
    _versionTaps++;
    final remaining = _unlockVersionTaps - _versionTaps;
    if (remaining > 0) {
      _showHint(
        '$remaining more tap${remaining == 1 ? '' : 's'} to unlock '
        'experimental features',
      );
      return;
    }
    _versionTaps = 0;
    settings.unlock();
    _showHint('Experimental features unlocked');
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _copyAll() {
    final sections = _sections;
    if (sections == null) return;
    final buffer = StringBuffer('DPIP diagnostics');
    for (final section in sections) {
      final fields = [
        for (final field in section.fields)
          if (!_redactedCopyLabels.contains(field.label)) field,
      ];
      if (fields.isEmpty) continue;
      buffer.writeln('\n[${section.title}]');
      for (final field in fields) {
        buffer.writeln('${field.label}: ${field.value ?? '—'}');
      }
    }
    _copy(buffer.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer'),
        actions: [
          if (sections != null)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Copy all',
              onPressed: _copyAll,
            ),
        ],
      ),
      body: sections == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  SectionHeader(sections[i].title),
                  for (final field in sections[i].fields)
                    _DiagRow(
                      field: field,
                      onTap: field.label == 'Version' ? _onVersionTap : null,
                      onCopy: _individuallyCopyableLabels.contains(field.label)
                          ? _copy
                          : null,
                    ),
                  if (sections[i].title == 'Network usage' &&
                      _usageHistory != null &&
                      _usageWeek != null)
                    NetworkUsageChart(
                      history: _usageHistory!,
                      week: _usageWeek!,
                    ),
                  if (sections[i].title == 'Storage' && _storage != null)
                    StorageBreakdown(
                      slices: storageBreakdown(_storage!),
                      total: _storage!.totalBytes,
                    ),
                  if (sections[i].title == 'SQLite tables' && _tables != null)
                    _TableBreakdown(tables: _tables!),
                ],
                const SectionHeader('Maintenance'),
                ListTile(
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    _clearCacheTitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Removes stored tiles, API responses, and usage stats',
                  ),
                  trailing: _clearing ? const InlineLoading(size: 18) : null,
                  onTap: _clearing ? null : _confirmClearCache,
                ),
              ],
            ),
    );
  }
}

/// A diagnostic row: label + value. Most rows are read-only (covered by the
/// app-bar's "Copy all"); [onCopy] adds a per-row copy button for the few that
/// are worth lifting out on their own (see [_DeveloperPageState._individuallyCopyableLabels]).
class _DiagRow extends StatelessWidget {
  const _DiagRow({required this.field, this.onCopy, this.onTap});

  final _Field field;
  final ValueChanged<String>? onCopy;

  /// Tap handler — used by the version row to arm the experimental unlock.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = field.value;
    final hasValue = value != null && value.isNotEmpty;
    return ListTile(
      onTap: onTap,
      title: Text(field.label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        hasValue ? value : '—',
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: hasValue
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.outline,
        ),
      ),
      trailing: hasValue && onCopy != null
          ? IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy',
              onPressed: () => onCopy!(value),
            )
          : null,
    );
  }
}

/// Per-table rows and bytes, biggest first.
///
/// A bar each rather than a number each: the question this answers is "what is
/// taking the space", and that is a comparison, not a set of readings.
class _TableBreakdown extends StatelessWidget {
  const _TableBreakdown({required this.tables});

  final List<TableStat> tables;

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final largest = tables.first.bytes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final table in tables) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      table.table,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    // l10n-ignore: developer diagnostics
                    '${table.rows} · ${formatBytes(table.bytes)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: AppRadius.small,
              child: LinearProgressIndicator(
                // Against the largest table, not the total: the point is which
                // one dominates, and against a total the small ones vanish.
                value: largest == 0 ? 0 : table.bytes / largest,
                minHeight: 4,
                backgroundColor: colors.surfaceContainerHighest,
                // The durable file is the one the user cannot get back; the
                // cache file the OS may empty on its own.
                color: table.file == 'dpip.db'
                    ? colors.primary
                    : colors.tertiary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            // l10n-ignore: developer diagnostics
            'blue = dpip.db (durable) · amber = http_cache.db (re-fetchable)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
