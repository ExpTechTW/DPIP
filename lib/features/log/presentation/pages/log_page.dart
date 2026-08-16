import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// In-app log viewer. Reachable from the More tab; pushed as a full-screen
/// route.
///
/// Shows Talker's live view of *this* session, and on open replays the last 24
/// hours from the `logs` table into it — so the screen covers the launch that
/// crashed, not just the one you are looking at. The replay happens once per
/// visit and is skipped when the history already reaches back that far, which
/// is the common case for a session that has been running a while.
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_replayPersisted());
  }

  /// Pulls the persisted log into Talker's history, oldest first, so the
  /// screen reads in the order things happened.
  ///
  /// Anything already in memory is skipped by timestamp: a session that has
  /// been open all day would otherwise show every line twice.
  Future<void> _replayPersisted() async {
    final store = Log.store;
    if (store == null) return;
    // Flush first, or the newest lines — the ones the user came to read — are
    // still sitting in the write buffer.
    await store.flush();
    final oldestInMemory = Log.talker.history.isEmpty
        ? null
        : Log.talker.history.first.time;
    final stored = await store.recent(limit: 2000);
    for (final entry in stored.reversed) {
      if (oldestInMemory != null && !entry.time.isBefore(oldestInMemory)) {
        continue;
      }
      Log.talker.logCustom(_PersistedLog(entry));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TalkerScreen(
      talker: Log.talker,
      appBarTitle: AppLocalizations.of(context).appLogs,
      theme: TalkerScreenTheme(
        backgroundColor: colors.surface,
        textColor: colors.onSurface,
        cardColor: colors.surfaceContainerHighest,
      ),
    );
  }
}

/// A replayed line, tagged so it is visibly from an earlier session rather
/// than something that just happened.
class _PersistedLog extends TalkerLog {
  _PersistedLog(this.entry)
    : super(entry.message, time: entry.time, stackTrace: null);

  final StoredLog entry;

  @override
  String get title => entry.level;

  @override
  AnsiPen get pen => switch (entry.level) {
    'error' || 'critical' => AnsiPen()..red(),
    'warning' => AnsiPen()..yellow(),
    'debug' => AnsiPen()..gray(),
    _ => AnsiPen()..blue(),
  };

  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    return [
      '[${entry.level}] ${entry.time.toIso8601String()}',
      entry.message,
      ?entry.error,
      ?entry.stackTrace,
    ].join('\n');
  }
}
