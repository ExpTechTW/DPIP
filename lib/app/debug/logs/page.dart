import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppDebugLogsPage extends StatelessWidget {
  const AppDebugLogsPage({super.key});

  static const route = '/debug/logs';

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
