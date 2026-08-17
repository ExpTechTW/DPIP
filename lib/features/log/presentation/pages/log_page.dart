import 'dart:async';

import 'package:dpip/app/theme/app_spacing.dart';
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
///
/// These lines are our own layout, not `TalkerScreen`. Talker's screen ships a
/// `SliverAppBar` whose expanded header is taller than its initial
/// `expandedHeight`, so the first frame overflows — and because an overflow is
/// routed through `Log.handle` into the very stream this page listens to, the
/// layout fault re-triggers on every rebuild: a log-flooding loop that ends in
/// a hang. A plain `AppBar` and a fixed toolbar cannot overflow.
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  String _query = '';

  /// The history, refreshed on a timer rather than per line.
  ///
  /// `TalkerBuilder` rebuilds on every entry, and this screen is the one place
  /// where that closes a circle: a fault raised while rendering it is logged,
  /// which rebuilds it, which raises the fault again. `Log` now refuses the
  /// repeat, so the loop terminates — but a screen that rebuilds once per line
  /// is still the wrong shape while something is logging hard, and the user
  /// cannot scroll a list that rebuilds under them. A tick decouples the two.
  static const _refreshInterval = Duration(milliseconds: 400);
  Timer? _refresh;
  List<TalkerData> _entries = const [];

  @override
  void initState() {
    super.initState();
    _entries = Log.talker.history.toList();
    _refresh = Timer.periodic(_refreshInterval, (_) => _pull());
    unawaited(_replayPersisted());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  void _pull() {
    final history = Log.talker.history;
    if (history.length == _entries.length) return;
    if (mounted) setState(() => _entries = history.toList());
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
    _pull();
  }

  /// The raw history, filtered to lines whose rendered text contains [_query].
  List<TalkerData> _filtered(List<TalkerData> data) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return data;
    return [
      for (final item in data)
        if (item.generateTextMessage().toLowerCase().contains(query)) item,
    ];
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
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: Text(l10n.appLogs)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: l10n.appLogsSearch,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final items = _filtered(_entries);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? l10n.appLogsEmpty
                            : l10n.appLogsNoMatch,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.lg,
                    ),
                    itemCount: items.length,
                    // Newest first, like the old talker view.
                    itemBuilder: (context, i) {
                      final item = items[items.length - 1 - i];
                      return TalkerDataCard(
                        data: item,
                        backgroundColor: theme.cardColor,
                        color: item.getFlutterColor(theme),
                        expanded: false,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
