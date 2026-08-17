/// Developer diagnostics: platform, device, app, and push-token details for
/// support and debugging. The app-bar copies a redacted dump (no device
/// identifier / push tokens); on-screen values stay visible for inspection.
///
/// **Deliberately English-only.** This page exists to be screenshotted into a
/// bug report or pasted to a maintainer, so a fixed vocabulary is worth more
/// than a localized one — and the values beside the labels (`arm64`, `release`,
/// an APNs token) never translate anyway.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/diagnostics/diagnostics_report.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/features/settings/presentation/widgets/network_usage_chart.dart';
import 'package:dpip/features/settings/presentation/widgets/storage_breakdown.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// One labelled diagnostic value.
typedef _Field = ({String label, String? value});

/// Shared by the row, the dialog title, and its confirm button.
const String _clearCacheTitle = 'Clear cache';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  List<DiagnosticsSection>? _sections;
  List<HourUsage>? _usageHistory;
  List<HourUsage>? _usageWeek;
  StorageScan? _storage;
  List<TableStat>? _tables;
  bool _clearing = false;

  /// Version-row taps toward the experimental unlock. Deliberately not
  /// persisted — a fresh app start re-arms the easter egg.
  static const int _unlockVersionTaps = 10;
  int _versionTaps = 0;

  Future<void> _load() async {
    // Services read before the first await, while the element is certainly
    // still mounted.
    final collector = DiagnosticsCollector(
      notifications: context.read<NotificationService>(),
      database: context.read<AppDatabase>(),
      backgroundLocation: context.read<BackgroundLocationService>(),
      etagCache: context.read<EtagCacheStore?>(),
      networkUsage: context.read<NetworkUsageStore?>(),
    );
    final report = await collector.collect();
    if (!mounted) return;
    setState(() {
      _sections = report.sections;
      _usageHistory = report.usageHistory;
      _usageWeek = report.usageWeek;
      _storage = report.storage;
      _tables = report.tables;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  Future<void> _reportNow() async {
    final backgroundLocation = context.read<BackgroundLocationService>();
    final messenger = ScaffoldMessenger.of(context);
    await backgroundLocation.reportNow();
    await _load();
    if (!mounted) return;
    messenger.showSnackBar(
      // l10n-ignore: developer-only page, deliberately untranslated
      const SnackBar(content: Text('Reported — see Last report above')),
    );
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
    final text = _diagnosticsText();
    if (text != null) _copy(text);
  }

  /// The diagnostics as one block — what `Copy all` copies and what a dump
  /// carries above the log.
  /// The redacted dump, or null before the first read has landed.
  String? _diagnosticsText() {
    final sections = _sections;
    if (sections == null) return null;
    return diagnosticsText(sections, redacted: diagnosticsRedactedLabels);
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
                // Runs the background report path by hand, on the same code an
                // OS wake runs. Waiting for a real geofence crossing means
                // driving 200 m and hoping, with no way to tell a wake that
                // never came from one that came and bailed — this reproduces
                // the second half on demand, and the rows above then say what
                // it did.
                ListTile(
                  leading: const Icon(Icons.my_location_outlined),
                  title: const Text('Report location now'),
                  subtitle: const Text(
                    'Runs the background report path and refreshes the rows above',
                  ),
                  onTap: _reportNow,
                ),
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
