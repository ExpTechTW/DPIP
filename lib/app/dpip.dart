import 'package:dpip/app/page/me/me.dart';
import 'package:dpip/app/page/monitor/monitor.dart';
import 'package:dpip/app/page/report_list/report_list.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/screen_size.dart';
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

  late final _pageStack = PageView(
    controller: controller,
    physics: const NeverScrollableScrollPhysics(),
    children: const [
      // HomePage(),
      MonitorPage(data: 0),
      ReportListPage(),
      // MapPage(),
      MePage(),
    ],
  );

  onDestinationSelected(int value) {
    setState(() {
      currentActivePage = value;
    });

    controller.jumpToPage(currentActivePage);
  }

  @override
  Widget build(BuildContext context) {
    bool useTabs = MediaQuery.of(context).size.width < FormFactor.tablet;

    return Scaffold(
      bottomNavigationBar: useTabs
          ? NavigationBar(
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
              onDestinationSelected: onDestinationSelected,
            )
          : null,
      body: Stack(
        children: [
          if (useTabs) ...[
            _pageStack,
          ] else ...[
            Row(
              children: [
                NavigationRail(
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: 0,
                  destinations: [
                    // NavigationDestination(
                    //   icon: const Icon(Symbols.home),
                    //   selectedIcon: const Icon(Symbols.home, fill: 1),
                    //   label: context.i18n.home,
                    // ),
                    NavigationRailDestination(
                      icon: const Icon(Symbols.monitor_heart),
                      selectedIcon: const Icon(Symbols.monitor_heart, fill: 1),
                      label: Text(context.i18n.monitor),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Symbols.summarize),
                      selectedIcon: const Icon(Symbols.summarize, fill: 1),
                      label: Text(context.i18n.report),
                    ),
                    // NavigationDestination(
                    //   icon: const Icon(Symbols.map),
                    //   selectedIcon: const Icon(Symbols.map, fill: 1),
                    //   label: context.i18n.map,
                    // ),
                    NavigationRailDestination(
                      icon: const Icon(Symbols.person),
                      selectedIcon: const Icon(Symbols.person, fill: 1),
                      label: Text(context.i18n.me),
                    ),
                  ],
                  selectedIndex: currentActivePage,
                  onDestinationSelected: onDestinationSelected,
                ),
                Expanded(
                  child: _pageStack,
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
