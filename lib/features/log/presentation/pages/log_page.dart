import 'dart:async';

import 'package:flutter/material.dart';

import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';

/// In-app log viewer. Reachable from the More tab; pushed as a full-screen
/// route.
///
/// This is Talker's own screen, not a layout of ours. The hand-rolled one grew
/// because `TalkerScreen`'s header could overflow, and an overflow is routed
/// through `Log.handle` into the very stream the screen rebuilds on — a loop
/// that ended in a hang. That loop is now cut where it starts: `Log` reports a
/// repeated fault a few times and then drops it, so a layout fault costs a few
/// lines instead of the app. Rebuilding the screen ourselves bought nothing
/// after that, and cost the search, the level filter, the sharing and the
/// settings that come with the real one.
///
/// What stays ours is the replay: on open, the last 24 hours are pulled out of
/// the `logs` table into Talker's history, so the screen covers the launch that
/// crashed and not only the one you are looking at.
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  late final Future<void> _loaded = _loadPersisted();

  /// Loads the stored log into the screen.
  ///
  /// The table is the whole record, not an addition to what is in memory:
  /// every line is persisted, and the ones from before the database opened
  /// are copied in when it does. So this replaces rather than merges — which
  /// is what removed the ordering and eviction faults that merging kept
  /// producing, and the duplicate a visit used to leave behind.
  Future<void> _loadPersisted() async {
    final store = Log.store;
    if (store == null) return;
    // Flush first, or the newest lines — the ones the user came to read — are
    // still sitting in the write buffer.
    await store.flush();
    final stored = await store.recent(limit: Log.historyLimit);
    Log.reload([for (final entry in stored) PersistedLog(entry)]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final theme = TalkerScreenTheme(
      backgroundColor: colors.surface,
      textColor: colors.onSurface,
      cardColor: colors.surfaceContainer,
    );
    // Built only once the replay is in, because Talker reads its history when
    // the screen builds and writing to it afterwards would not show.
    return FutureBuilder<void>(
      future: _loaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(title: Text(l10n.appLogs)),
            body: const Center(child: InlineLoading()),
          );
        }
        return TalkerScreen(
          talker: Log.talker,
          appBarTitle: l10n.appLogs,
          theme: theme,
          // Collapsed: a log this screen exists to scan is read by its
          // summaries, and an expanded card is mostly stack trace.
          isLogsExpanded: false,
        );
      },
    );
  }
}

/// A line read back out of the `logs` table.
///
/// Its level is carried across, not invented. Talker colours a card and the
/// level filter narrows by `logLevel`, so a replayed line that arrives without
/// one is uncoloured, uncounted, and grouped under `undefined` with every
/// other level — the screen keys its filter chips and its card colours on
/// `TalkerData.key`, not on the level or the title.
class PersistedLog extends TalkerLog {
  PersistedLog(StoredLog entry) : this._(entry, _level(entry.level));

  PersistedLog._(StoredLog entry, LogLevel level)
    : super(
        entry.error == null
            ? entry.message
            : '${entry.message}\n${entry.error}',
        time: entry.time,
        // The screen counts its filter chips by `key` and colours a card by
        // it, so a replayed line needs the same one a live line of that level
        // would have had. `Log.replay` fills in the title and pen from it.
        key: TalkerKey.fromLogLevel(level),
        logLevel: level,
        stackTrace: null,
      );

  /// Unknown names fall to `info` rather than being dropped: a line whose
  /// level cannot be read is still a line somebody needs to see.
  static LogLevel _level(String name) => LogLevel.values.firstWhere(
    (level) => level.name == name,
    orElse: () => LogLevel.info,
  );
}
