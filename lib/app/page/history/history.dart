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
                  icon: const Icon(Symbols.public_rounded),
                  text: context.i18n.history_nationwide,
                ),
                Tab(
                  icon: const Icon(Symbols.home_rounded),
                  text: context.i18n.settings_location,
                ),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: controller,
        children: const [
          HistoryCountryTab(),
          HistoryLocationTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
