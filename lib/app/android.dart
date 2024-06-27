import 'package:dpip/app/home/android.dart';
import 'package:dpip/app/monitor/android.dart';
import 'package:dpip/app/report/android.dart';
import 'package:flutter/material.dart';

class AndroidApp extends StatefulWidget {
  const AndroidApp({super.key});

  @override
  State<AndroidApp> createState() => _AndroidAppState();
}

class _AndroidAppState extends State<AndroidApp> {
  int currentTabIndex = 0;
  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            AndroidHomeView(),
            AndroidMonitorView(),
            AndroidReportView(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentTabIndex,
          destinations: [
            AndroidHomeView.navigation,
            AndroidMonitorView.navigation,
            AndroidReportView.navigation,
          ],
          onDestinationSelected: (value) {
            setState(() {
              currentTabIndex = value;
            });
            pageController.jumpToPage(currentTabIndex);
          },
        ),
      ),
    );
  }
}
