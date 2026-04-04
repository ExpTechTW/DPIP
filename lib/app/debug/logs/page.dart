/// The debug logs page, displaying in-app Talker log output.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Renders the full Talker log screen for in-app debugging.
///
/// Theming is derived from the current [BuildContext] color scheme so the
/// screen respects light/dark mode automatically.
class AppDebugLogsPage extends StatelessWidget {
  /// Creates an [AppDebugLogsPage].
  const AppDebugLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(
      talker: TalkerManager.instance,
      appBarTitle: 'App 日誌'.i18n,
      theme: TalkerScreenTheme(
        backgroundColor: context.colors.surface,
        textColor: context.colors.onSurface,
        cardColor: context.colors.surfaceContainer,
      ),
    );
  }
}
