import 'package:dpip/app/home/android.dart';
import 'package:dpip/app/monitor/android.dart';
import 'package:dpip/app/report/android.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AndroidDPIP extends StatefulWidget {
  const AndroidDPIP({super.key});

  @override
  State<AndroidDPIP> createState() => _AndroidDPIPState();
}

class _AndroidDPIPState extends State<AndroidDPIP> {
  int currentTabIndex = 0;
  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    context.setLocale(Locale('zh', 'Hant'));
    print(context.locale.toString());
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
