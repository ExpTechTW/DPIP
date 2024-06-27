import 'package:dpip/app/home/ios.dart';
import 'package:dpip/app/monitor/ios.dart';
import 'package:dpip/app/report/ios.dart';
import 'package:flutter/cupertino.dart';

class CupertinoDPIP extends StatefulWidget {
  const CupertinoDPIP({super.key});

  @override
  State<CupertinoDPIP> createState() => _CupertinoDPIPState();
}

class _CupertinoDPIPState extends State<CupertinoDPIP> {
  int currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoTabScaffold(
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
      ),
    );
  }
}
