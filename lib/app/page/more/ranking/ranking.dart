import 'package:dpip/app/page/more/ranking/tabs/precipitation.dart';
import 'package:dpip/app/page/more/ranking/tabs/temperature.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with TickerProviderStateMixin {
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
            title: Text("排行榜"),
            bottom: TabBar(
              controller: controller,
              tabs: [
                Tab(
                  text: context.i18n.precipitation_monitor,
                ),
                Tab(
                  text: context.i18n.temperature_monitor,
                ),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          RankingPrecipitationTab(),
          RankingTemperatureTab(),
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
