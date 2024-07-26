import 'package:dpip/app/page/me/me.dart';
import 'package:dpip/app/page/monitor/monitor.dart';
import 'package:dpip/app/page/report_list/report_list.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Dpip extends StatefulWidget {
  const Dpip({super.key});

  @override
  State<Dpip> createState() => _DpipState();
}

class _DpipState extends State<Dpip> {
  PageController controller = PageController();
  int currentActivePage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentActivePage,
        destinations: [
          // NavigationDestination(
          //   icon: const Icon(Symbols.home),
          //   selectedIcon: const Icon(Symbols.home, fill: 1),
          //   label: context.i18n.home,
          // ),
          NavigationDestination(
            icon: const Icon(Symbols.monitor_heart),
            selectedIcon: const Icon(Symbols.monitor_heart, fill: 1),
            label: context.i18n.monitor,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.summarize),
            selectedIcon: const Icon(Symbols.summarize, fill: 1),
            label: context.i18n.report,
          ),
          // NavigationDestination(
          //   icon: const Icon(Symbols.map),
          //   selectedIcon: const Icon(Symbols.map, fill: 1),
          //   label: context.i18n.map,
          // ),
          NavigationDestination(
            icon: const Icon(Symbols.person),
            selectedIcon: const Icon(Symbols.person, fill: 1),
            label: context.i18n.me,
          ),
        ],
        onDestinationSelected: (value) {
          setState(() {
            currentActivePage = value;
          });

          controller.jumpToPage(currentActivePage);
        },
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          // HomePage(),
          MonitorPage(data: 0),
          ReportListPage(),
          // MapPage(),
          MePage(),
        ],
      ),
    );
  }
}
