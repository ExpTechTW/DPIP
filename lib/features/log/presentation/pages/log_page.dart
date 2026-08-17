import 'dart:async';

import 'package:flutter/material.dart';

import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';

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
    final stored = await store.recent(limit: logMaxRows);
    for (final entry in stored.reversed) {
      if (oldestInMemory != null && !entry.time.isBefore(oldestInMemory)) {
        continue;
      }
      Log.talker.logCustom(PersistedLog(entry));
    }
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
        cardColor: colors.surfaceContainer,
      ),
      // Collapsed: a log this screen exists to scan is read by its summaries,
      // and an expanded card is mostly stack trace.
      isLogsExpanded: false,
    );
  }
}

/// A line read back out of the `logs` table.
///
/// Its level is carried across, not invented. Talker colours a card and the
/// level filter narrows by `logLevel`, so a replayed line that arrives without
/// one is uncoloured and unfilterable — the two things the log screen is read
/// with. The stored string is a [LogLevel] name, written by `Log.persistTo`.
class PersistedLog extends TalkerLog {
  PersistedLog(StoredLog entry)
    : super(
        entry.error == null
            ? entry.message
            : '${entry.message}\n${entry.error}',
        time: entry.time,
        logLevel: _level(entry.level),
        stackTrace: null,
      );

  /// Unknown names fall to `info` rather than being dropped: a line whose
  /// level cannot be read is still a line somebody needs to see.
  static LogLevel _level(String name) => LogLevel.values.firstWhere(
    (level) => level.name == name,
    orElse: () => LogLevel.info,
  );
}
