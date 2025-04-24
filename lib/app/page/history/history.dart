import 'package:dpip/app/page/history/tabs/country.dart';
import 'package:dpip/app/page/history/tabs/location.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  late final controller = TabController(length: 2, vsync: this, initialIndex: 1);

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (!mounted || !controller.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            title: Text(context.i18n.history),
            bottom: TabBar(
              controller: controller,
              tabs: [
                Tab(
                  icon: Icon(Symbols.globe_asia_rounded, fill: controller.index == 0 ? 1 : 0),
                  text: context.i18n.history_nationwide,
                ),
                Tab(
                  icon: Icon(Symbols.home_rounded, fill: controller.index == 1 ? 1 : 0),
                  text: context.i18n.settings_location,
                ),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [HistoryCountryTab(), HistoryLocationTab()],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
