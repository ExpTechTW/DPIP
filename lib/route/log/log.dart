import 'package:flutter/material.dart';

import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';

class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TalkerScreen(
        talker: TalkerManager.instance,
        appBarTitle: 'App 日誌',
        theme: TalkerScreenTheme(
          backgroundColor: context.colors.surface,
          textColor: context.colors.onSurface,
          cardColor: context.colors.surfaceContainer,
        ),
      ),
    );
  }
}
