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

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/build_info.g.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/features/settings/presentation/widgets/network_usage_chart.dart';
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

/// Formats a byte count as a compact human string (B / KB / MB / GB).
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unit]}';
}

/// Formats a cache hit rate as `NN% (hits/total)`, or a dash when the window
/// saw no cacheable request at all — 0% would read as "the cache is failing".
String _formatRate(double rate, int hits, int total) =>
    total == 0 ? '—' : '${(rate * 100).toStringAsFixed(0)}% ($hits/$total)';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  List<({String title, List<_Field> fields})>? _sections;
  List<HourUsage>? _usageHistory;
  List<HourUsage>? _usageWeek;
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

    final info = await PackageInfo.fromPlatform();
    final cacheStats = await etagCache?.stats();
    final usage = await networkUsage?.stats();
    final usageHistory = await networkUsage?.history();
    final usageWeek = await networkUsage?.history(
      hours: 24 * 7,
      bucketHours: 6,
    );
    final device = await DeviceInfoService.load();
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
      (
        title: 'ETag cache',
        fields: [
          (
            label: 'Entries',
            value: cacheStats == null ? '—' : '${cacheStats.rows}',
          ),
          (
            label: 'Size on disk',
            value: cacheStats == null ? '—' : _formatBytes(cacheStats.bytes),
          ),
        ],
      ),
      // Every figure here is the same pair of trailing windows, so they can be
      // read against each other.
      (
        title: 'Network usage',
        fields: [
          (
            label: 'Downloaded · last 24h',
            value: usage == null ? '—' : _formatBytes(usage.last24h),
          ),
          (
            label: 'Downloaded · last 7d',
            value: usage == null ? '—' : _formatBytes(usage.last7d),
          ),
          (
            label: 'Traffic saved · last 24h',
            value: usage == null ? '—' : _formatBytes(usage.saved24h),
          ),
          (
            label: 'Traffic saved · last 7d',
            value: usage == null ? '—' : _formatBytes(usage.saved7d),
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
          'again next time they are needed. Traffic and hit-rate figures reset '
          'to zero.',
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
      await networkUsage?.clear();
      // The mirror would otherwise keep serving bytes the store no longer has,
      // so "cleared" would not look cleared until the app restarted.
      await tiles?.evict(const []);
      // MapLibre's own ambient DB is separate — poisoned immutable tiles
      // (e.g. bad Content-Encoding) survive SQLite clears otherwise.
      await clearAmbientCache();
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
