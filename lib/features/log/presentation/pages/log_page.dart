import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// In-app log viewer, backed by the shared [Log] history. Reachable from the
/// More tab; pushed as a full-screen route.
class LogPage extends StatelessWidget {
  const LogPage({super.key});

  /// Route path.
  static const String path = '/log';

  /// Route name.
  static const String name = 'log';

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
