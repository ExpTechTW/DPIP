/// The one-tap diagnostics dump, shared by every screen that offers it.
library;

import 'package:dpip/core/diagnostics/debug_dump.dart';
import 'package:dpip/core/diagnostics/diagnostics_report.dart';
import 'package:dpip/core/diagnostics/dump_uploader.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/dump_link_dialog.dart';
import 'package:dpip/shared/widgets/dump_upload_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Collects the diagnostics and the tail of the log, uploads them, copies the
/// link, and shows it.
///
/// The two halves answer different questions and a report needs both: the
/// diagnostics say what this build and this device are, the log says what they
/// just did. Pasting tens of thousands of characters into a chat buries the
/// conversation they are part of, so they go to a paste and only the link
/// comes back.
///
/// Returns true when a link was produced. Failures are reported to the user
/// here and logged; the caller only has to stop showing its spinner.
Future<bool> runDiagnosticsDump(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final includeSensitive = await showDumpUploadDialog(context);
  if (includeSensitive == null || !context.mounted) return false;
  final uploader = context.read<DumpUploader>();
  final collector = DiagnosticsCollector(
    notifications: context.read<NotificationService>(),
    database: context.read<AppDatabase>(),
    backgroundLocation: context.read<BackgroundLocationService>(),
    etagCache: context.read<EtagCacheStore?>(),
    networkUsage: context.read<NetworkUsageStore?>(),
  );

  void fail() => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.dumpUploadFailed)));

  try {
    final report = await collector.collect();
    // Newest first, which is the order the budget spends from.
    final lines = [
      for (final entry in Log.talker.history.reversed)
        logLine(
          tag: entry.title ?? 'log',
          time: entry.time,
          message: entry.displayMessage,
        ),
    ];
    final dump = buildDump(
      diagnostics: diagnosticsText(
        report.sections,
        nulled: includeSensitive ? const {} : diagnosticsSensitiveLabels,
      ),
      logLines: lines,
    );
    final url = await uploader.upload(
      includeSensitive ? dump : redactSensitiveDump(dump),
    );
    if (url == null) {
      fail();
      return false;
    }
    // Copied before it is shown. The dialog can be dismissed by a tap past it,
    // and the link is the whole point of having pressed the button — losing it
    // to a stray tap would mean uploading again.
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return true;
    await showDumpLinkDialog(context, url);
    return true;
  } on Object catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'diagnostics dump');
    fail();
    return false;
  }
}
