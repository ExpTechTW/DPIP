import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/api/exptech.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<History> historyList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

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
    final data = await ExpTech().getHistory();
    setState(() => historyList = data);
  }

  @override
  void initState() {
    super.initState();
    refreshHistoryList();
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
      title: Text(context.i18n.home),
    );

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: refreshHistoryList,
            child: ListView(
              padding: EdgeInsets.only(bottom: context.padding.bottom),
              controller: scrollController,
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Container(
                    padding: EdgeInsets.only(top: context.padding.top),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color.fromARGB(137, 14, 52, 96), Color.fromARGB(61, 39, 58, 81), Colors.transparent],
                        stops: [0.16, 0.6, 1],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Symbols.pin_drop_rounded, color: context.colors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        "臺南市歸仁區",
                                        style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "27°",
                                        style: TextStyle(
                                          fontSize: 68,
                                          fontWeight: FontWeight.w500,
                                          color: context.colors.onPrimaryContainer.withOpacity(0.85),
                                          height: 1,
                                        ),
                                      ),
                                      Icon(
                                        Symbols.partly_cloudy_day_rounded,
                                        fill: 1,
                                        size: 48,
                                        color: context.colors.onPrimaryContainer.withOpacity(0.75),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "最高 30°",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: context.colors.onSecondaryContainer.withOpacity(0.75),
                                        ),
                                      ),
                                      Text(
                                        "最低 24°",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: context.colors.onSecondaryContainer.withOpacity(0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                "晴時多雲",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 0, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "體感溫度: ˇ30°",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.onSurfaceVariant.withOpacity(0.75),
                                ),
                              ),
                              Text(
                                "降雨機率: 20%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.onSurfaceVariant.withOpacity(0.75),
                                ),
                              ),
                              Text(
                                "相對濕度: 42%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.onSurfaceVariant.withOpacity(0.75),
                                ),
                              ),
                              Text(
                                "紫外線指數: 6（高量級）",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.onSurfaceVariant.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                  child: Text(
                    "一小時預報",
                    style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Card(
                        elevation: 4,
                        surfaceTintColor: context.colors.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "9:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "30°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "/27°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "30%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.theme.extendedColors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Symbols.partly_cloudy_day_rounded,
                                fill: 1,
                                size: 36,
                                color: context.colors.onPrimaryContainer.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        surfaceTintColor: context.colors.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "10:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "30°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "/28°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "30%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.theme.extendedColors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Symbols.partly_cloudy_day_rounded,
                                fill: 1,
                                size: 36,
                                color: context.colors.onPrimaryContainer.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        surfaceTintColor: context.colors.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "11:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "31°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "/28°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "35%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.theme.extendedColors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Symbols.sunny_rounded,
                                fill: 1,
                                size: 36,
                                color: context.colors.onPrimaryContainer.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        surfaceTintColor: context.colors.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "12:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "32°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "/29°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "40%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.theme.extendedColors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Symbols.sunny_rounded,
                                fill: 1,
                                size: 36,
                                color: context.colors.onPrimaryContainer.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        surfaceTintColor: context.colors.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "13:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "32°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "/29°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "50%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.theme.extendedColors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Symbols.partly_cloudy_day_rounded,
                                fill: 1,
                                size: 36,
                                color: context.colors.onPrimaryContainer.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        surfaceTintColor: context.colors.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "14:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "32°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "/28°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "65%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.theme.extendedColors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Symbols.cloudy_rounded,
                                fill: 1,
                                size: 36,
                                color: context.colors.onPrimaryContainer.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        surfaceTintColor: context.colors.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "15:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "30°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "/26°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "80%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.theme.extendedColors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Symbols.rainy_rounded,
                                fill: 1,
                                size: 36,
                                color: context.colors.onPrimaryContainer.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                  child: Text(
                    "目前的天氣資訊",
                    style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
                  ),
                ),
                Builder(
                  builder: (context) {
                    if (historyList.isEmpty) {
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
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
