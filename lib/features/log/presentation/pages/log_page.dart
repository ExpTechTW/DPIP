import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// In-app log viewer, backed by the shared [Log] history. Reachable from the
/// More tab; pushed as a full-screen route.
///
/// Applies a 7-day retention window on open: the in-memory history isn't
/// persisted across launches and is otherwise bounded only by count, so opening
/// the screen drops anything older than a week.
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  @override
  void initState() {
    super.initState();
    Log.pruneOlderThan(const Duration(days: 7));
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
