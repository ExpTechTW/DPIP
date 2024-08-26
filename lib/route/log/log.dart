import 'package:dpip/util/log.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TalkerScreen(
        talker: TalkerManager.instance,
        appBarTitle: 'App 日誌',
        theme: const TalkerScreenTheme(),
      ),
    );
  }
}
