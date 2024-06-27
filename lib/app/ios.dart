import 'package:dpip/app/home/ios.dart';
import 'package:dpip/app/monitor/ios.dart';
import 'package:dpip/app/report/ios.dart';
import 'package:flutter/cupertino.dart';

class AndroidApp extends StatefulWidget {
  const AndroidApp({super.key});

  @override
  State<AndroidApp> createState() => _AndroidAppState();
}

class _AndroidAppState extends State<AndroidApp> {
  int currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          CupertinoHomeView.navigation,
          CupertinoMonitorView.navigation,
          CupertinoReportView.navigation,
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return [
              const CupertinoHomeView(),
              const CupertinoMonitorView(),
              const CupertinoReportView(),
            ][index];
          },
        );
      },
    );
  }
}
