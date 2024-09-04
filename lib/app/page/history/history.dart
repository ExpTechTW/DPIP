import 'package:dpip/app/page/history/tabs/country.dart';
import 'package:dpip/app/page/history/tabs/location.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HistoryPage extends StatefulWidget {
  final Function()? onPositionUpdate;

  const HistoryPage({super.key, this.onPositionUpdate});

  @override
  State<HistoryPage> createState() => _HistoryPageState();

  static void updatePosition() => _activeCallback?.call();

  static void setActiveCallback(VoidCallback callback) => _activeCallback = callback;

  static void clearActiveCallback() => _activeCallback = null;

  static VoidCallback? _activeCallback;
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  late final controller = TabController(length: 2, vsync: this);

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
                  text: context.i18n.home_area,
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
    HistoryPage.clearActiveCallback();
    controller.dispose();
    super.dispose();
  }
}
