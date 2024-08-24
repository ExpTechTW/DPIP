import "package:dpip/app/page/more/report_list/report_list.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final controller = PageController();
  int currentIndex = 0;

  late final destinations = [
    NavigationDrawerDestination(
      icon: const Icon(Symbols.summarize),
      selectedIcon: const Icon(Symbols.summarize, fill: 1),
      label: Text(context.i18n.report),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: destinations[currentIndex].label,
      ),
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        children: [
          ListTileGroupHeader(title: "更多功能列表"),
          ...destinations,
        ],
        onDestinationSelected: (value) {
          setState(() => currentIndex = value);
          controller.jumpToPage(value);
          Navigator.pop(context);
        },
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [ReportListPage()],
      ),
    );
  }
}
