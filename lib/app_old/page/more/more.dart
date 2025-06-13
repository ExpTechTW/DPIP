import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/app_old/page/more/ranking/ranking.dart';
import 'package:dpip/app_old/page/more/report_list/report_list.dart';
import 'package:dpip/widgets/list/tile_group_header.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final controller = PageController();
  int currentIndex = 0;

  late final destinations = [
    const NavigationDrawerDestination(
      icon: Icon(Symbols.summarize),
      selectedIcon: Icon(Symbols.summarize, fill: 1),
      label: Text('地震報告'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.leaderboard_rounded),
      selectedIcon: Icon(Symbols.leaderboard_rounded, fill: 1),
      label: Text('排行榜'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        children: [const ListTileGroupHeader(title: '更多功能列表'), ...destinations],
        onDestinationSelected: (value) {
          setState(() => currentIndex = value);
          controller.jumpToPage(value);
          Navigator.pop(context);
        },
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [ReportListPage(), RankingPage()],
      ),
    );
  }
}
