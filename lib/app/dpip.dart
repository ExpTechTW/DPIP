import 'package:dpip/app/page/history/history.dart';
import 'package:dpip/app/page/map/map.dart';
import 'package:dpip/app/page/me/me.dart';
import 'package:dpip/app/page/more/more.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/update_required/update_required.dart';
import 'package:dpip/route/welcome/about.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Global.preference.getBool("welcome-1.0.0") != null) return;
      Global.preference.setBool("welcome-1.0.0", true);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AboutPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentActivePage,
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.home),
            selectedIcon: const Icon(Symbols.home, fill: 1),
            label: context.i18n.home,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.clock_loader_10_rounded),
            selectedIcon: const Icon(Symbols.clock_loader_10_rounded, fill: 1),
            label: context.i18n.history,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.map),
            selectedIcon: const Icon(Symbols.map, fill: 1),
            label: context.i18n.map,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.note_stack_add_rounded),
            selectedIcon: const Icon(Symbols.note_stack_add_rounded, fill: 1),
            label: "更多",
          ),
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
          UpdateRequiredPage(),
          // ChangelogPage(),
          // HomePage(),
          HistoryPage(),
          MapPage(),
          MorePage(),
          MePage(),
        ],
      ),
    );
  }
}
