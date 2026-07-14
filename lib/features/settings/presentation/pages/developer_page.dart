/// Developer diagnostics: platform, device, app, and push-token details for
/// support and debugging. Every value is copyable.
library;

import 'dart:io';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/build_info.g.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// One labelled diagnostic value.
typedef _Field = ({String label, String? value});

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

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  List<({String title, List<_Field> fields})>? _sections;

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
          (label: 'Name', value: info.appName),
          (label: 'Package', value: info.packageName),
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
          (
            label: 'Hit rate',
            value: usage == null
                ? '—'
                : '${(usage.hitRate * 100).toStringAsFixed(0)}% '
                      '(${usage.hits}/${usage.total})',
          ),
          (
            label: 'Traffic saved (total)',
            value: usage == null ? '—' : _formatBytes(usage.savedBytes),
          ),
        ],
      ),
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
        ],
      ),
    ];
    if (mounted) setState(() => _sections = sections);
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

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.developerCopied)));
  }

  void _copyAll() {
    final sections = _sections;
    if (sections == null) return;
    final buffer = StringBuffer('DPIP diagnostics');
    for (final section in sections) {
      buffer.writeln('\n[${section.title}]');
      for (final field in section.fields) {
        buffer.writeln('${field.label}: ${field.value ?? '—'}');
      }
    }
    _copy(buffer.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = _sections;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moreDeveloper),
        actions: [
          if (sections != null)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: l10n.developerCopyAll,
              onPressed: _copyAll,
            ),
        ],
      ),
      body: sections == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                for (final section in sections) ...[
                  SectionHeader(section.title),
                  for (final field in section.fields)
                    _DiagRow(field: field, onCopy: _copy),
                ],
              ],
            ),
    );
  }
}

/// A diagnostic row: label + value; tap (or the copy icon) copies the value.
class _DiagRow extends StatelessWidget {
  const _DiagRow({required this.field, required this.onCopy});

  final _Field field;
  final Future<void> Function(String value) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = field.value;
    final hasValue = value != null && value.isNotEmpty;
    return ListTile(
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
      trailing: hasValue
          ? Icon(
              Icons.copy_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: hasValue ? () => onCopy(value) : null,
    );
  }
}
