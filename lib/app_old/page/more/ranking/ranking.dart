import 'package:dpip/app_old/page/more/ranking/tabs/precipitation.dart';
import 'package:dpip/app_old/page/more/ranking/tabs/temperature.dart';
import 'package:dpip/app_old/page/more/ranking/tabs/wind.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with TickerProviderStateMixin {
  late final controller = TabController(length: 3, vsync: this);
  final scroll = GlobalKey<NestedScrollViewState>();
  bool showFAB = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      final innerController = scroll.currentState?.innerController;
      if (innerController == null) return;
      innerController.addListener(() {
        if (controller.indexIsChanging) return;

        if (innerController.offset == innerController.position.minScrollExtent) {
          if (showFAB) setState(() => showFAB = false);
        } else {
          if (!showFAB) setState(() => showFAB = true);
        }
      });
    });
    controller.addListener(() {
      if (!controller.indexIsChanging) return;
      scroll.currentState?.outerController.animateTo(0, duration: Durations.long2, curve: Easing.standard);
      setState(() => showFAB = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      key: scroll,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            title: const Text('排行榜'),
            bottom: TabBar(
              controller: controller,
              isScrollable: true,
              tabs: const [Tab(text: '降水'), Tab(text: '氣溫'), Tab(text: '風向/風速')],
            ),
          ),
        ];
      },
      body: Stack(
        children: [
          TabBarView(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            children: const [RankingPrecipitationTab(), RankingTemperatureTab(), RankingWindTab()],
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: AnimatedScale(
              scale: showFAB ? 1 : 0,
              duration: Durations.short4,
              curve: Easing.standard,
              child: FloatingActionButton.small(
                child: const Icon(Symbols.vertical_align_top_rounded),
                onPressed: () {
                  scroll.currentState?.innerController.animateTo(
                    0,
                    duration: Durations.medium1,
                    curve: Easing.standard,
                  );
                  scroll.currentState?.outerController.animateTo(0, duration: Durations.long2, curve: Easing.standard);
                },
              ),
            ),
          ),
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
