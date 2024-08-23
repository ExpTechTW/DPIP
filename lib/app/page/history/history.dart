import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../global.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  List<History> historyList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  Map<String, dynamic> weatherData = {};
  List<Widget> weatherCard = [];
  bool init = false;
  String city = Global.preference.getString("location-city") ?? "";
  String town = Global.preference.getString("location-town") ?? "";
  String region = "";

  late final backgroundColor = Color.lerp(context.colors.surface, context.colors.surfaceTint, 0.08);

  late final decorationTween = DecorationTween(
    begin: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      boxShadow: kElevationToShadow[4],
      color: backgroundColor,
    ),
    end: BoxDecoration(
      borderRadius: BorderRadius.zero,
      boxShadow: kElevationToShadow[4],
      color: backgroundColor,
    ),
  ).chain(CurveTween(curve: Curves.linear));

  final opacityTween = Tween(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.linear));

  final scrollController = ScrollController();
  late final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  double headerHeight = 360;
  bool isAppBarVisible = false;

  Future<void> refreshHistoryList() async {
    final data = await ExpTech().getHistoryRegion(region);
    setState(() {
      init = true;
      historyList = data.reversed.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    Global.location.forEach((key, data) {
      if (data.city == city && data.town == town) {
        region = key;
      }
    });
    if (region != "") {
      refreshHistoryList();
    }
    double headerScrollHeight = headerHeight / 5 * 3;
    scrollController.addListener(() {
      if (scrollController.offset > 1e-5) {
        if (!isAppBarVisible) {
          setState(() => isAppBarVisible = true);
        }
      } else {
        if (isAppBarVisible) {
          setState(() => isAppBarVisible = false);
        }
      }

      if (scrollController.offset < headerScrollHeight) {
        animController.animateTo(scrollController.offset / headerScrollHeight, duration: Duration.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      elevation: 4,
      title: Text(context.i18n.history),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: refreshHistoryList,
              child: ListView(
                padding: EdgeInsets.only(bottom: context.padding.bottom),
                controller: scrollController,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 0, 8),
                    child: Text(context.i18n.historical_events,
                      style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      if (historyList.isEmpty) {
                        if (init) {
                          return Center(child: Text(context.i18n.no_historical_events));
                        }
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<Widget> children = [];

                      for (var i = 0, n = historyList.length; i < n; i++) {
                        final current = historyList[i];
                        var showDate = false;

                        if (i != 0) {
                          final prev = historyList[i - 1];
                          if (current.time.send.day != prev.time.send.day) {
                            showDate = true;
                          }
                        } else {
                          showDate = true;
                        }

                        final item = TimeLineTile(
                          time: current.time.send,
                          icon: const Icon(Symbols.thunderstorm_rounded),
                          height: 100,
                          first: i == 0,
                          showDate: showDate,
                          color: context.theme.extendedColors.blueContainer,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(current.text.content["all"]!.subtitle, style: context.theme.textTheme.titleMedium),
                              Text(current.text.description["all"]!),
                            ],
                          ),
                          onTap: () {},
                        );

                        children.add(item);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: children,
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Visibility(
                visible: isAppBarVisible,
                child: FadeTransition(
                  opacity: animController.drive(opacityTween),
                  child: appBar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
