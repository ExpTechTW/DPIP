import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/route/settings/settings.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/util/list_icon.dart';
import 'package:dpip/widget/home/forecast_weather_card.dart';
import 'package:dpip/util/weather_icon.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/util/need_location.dart';

typedef PositionUpdateCallback = void Function();

class HomePage extends StatefulWidget {
  final Function()? onPositionUpdate;

  const HomePage({Key? key, this.onPositionUpdate}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();

  static PositionUpdateCallback? _activeCallback;

  static void setActiveCallback(PositionUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updatePosition() {
    _activeCallback?.call();
  }
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<History> realtimeList = [];
  Map<String, dynamic> weatherData = {};
  List<Widget> weatherCard = [];
  bool init = false;
  String city = "";
  String town = "";
  String region = "";
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

  @override
  void initState() {
    super.initState();
    start();
    HomePage.setActiveCallback(sendpositionUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserLocation();
    });
  }

  @override
  void dispose() {
    HomePage.clearActiveCallback();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> refreshRealtimeList() async {
    final data = await ExpTech().getRealtimeRegion(region);
    setState(() {
      init = true;
      realtimeList = data.reversed.toList();
    });
  }

  String formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}日${dateTime.hour.toString().padLeft(2, '0')}時';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  List<Map<String, dynamic>> getNextHours(List<dynamic> days) {
    final now = DateTime.now();
    final currentHour = now.hour;
    List<Map<String, dynamic>> nextHours = [];
    for (var day in days) {
      for (var hour in day["hours"]) {
        final hourTime = DateTime.parse(hour["time"]);
        if (hourTime.isAfter(now) || (hourTime.hour == currentHour && hourTime.day == now.day)) {
          nextHours.add(hour);
          if (nextHours.length == 25) {
            return nextHours;
          }
        }
      }
    }
    return nextHours;
  }

  Future<void> refreshWeatherAll() async {
    final data = await ExpTech().getWeatherAll(region);
    final next15Hours = getNextHours(data["forecast"]["day"]);

    for (var hour in next15Hours) {
      weatherCard.add(
        ForecastWeatherCard(
          time: formatDateTime(hour["time"]),
          minTemperature: (hour["temp"]?["c"]).round(),
          maxTemperature: (hour["heat"]?["c"]).round(),
          rain: hour["chance"]?["rain"],
          icon: WeatherIcons.getWeatherIcon(hour["condition"].toString() ?? "", hour["is_day"] ?? 1),
        ),
      );
    }
    setState(() {
      weatherData = data;
    });
  }

  void _initUserLocation() async {
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    if (!isUserLocationValid && !(Global.preference.getBool("auto-location") ?? false)) {
      await showLocationDialog(context);
    }
  }

  void start() {
    city = Global.preference.getString("location-city") ?? "";
    town = Global.preference.getString("location-town") ?? "";
    region = "";
    Global.location.forEach((key, data) {
      if (data.city == city && data.town == town) {
        region = key;
      }
    });
    weatherData = {};
    realtimeList = [];
    weatherCard = [];
    if (region != "") {
      refreshWeatherAll();
      refreshRealtimeList();
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
    setState(() {});
  }

  void sendpositionUpdate() {
    if (mounted) {
      start();
      widget.onPositionUpdate?.call();
    }
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
            onRefresh: refreshRealtimeList,
            child: ListView(
              padding: EdgeInsets.only(bottom: context.padding.bottom),
              controller: scrollController,
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Container(
                    padding: EdgeInsets.only(top: context.padding.top),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.colors.primary.withOpacity(0.2),
                          context.colors.primaryContainer.withOpacity(0.16),
                          Colors.transparent
                        ],
                        stops: const [0.16, 0.6, 1],
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      settings: const RouteSettings(name: "/settings"),
                                      builder: (context) => const SettingsRoute(
                                        initialRoute: '/location',
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Symbols.pin_drop_rounded, color: context.colors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        (region != "") ? "$city$town" : "服務區域外",
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
                                        "${weatherData["realtime"]?["temp"]?["c"].round() ?? "--"}°",
                                        style: TextStyle(
                                          fontSize: 68,
                                          fontWeight: FontWeight.w500,
                                          color: context.colors.onPrimaryContainer.withOpacity(0.85),
                                          height: 1,
                                        ),
                                      ),
                                      Icon(
                                        WeatherIcons.getWeatherIcon(
                                            weatherData["realtime"]?["condition"].toString() ?? "",
                                            weatherData["realtime"]?["is_day"] ?? 1),
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
                                        "最高 ${weatherData["forecast"]?["day"]?[0]?["weather"]?["temp"]?["c"]?["max"].round() ?? "--"}°",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: context.colors.onSecondaryContainer.withOpacity(0.75),
                                        ),
                                      ),
                                      Text(
                                        "最低 ${weatherData["forecast"]?["day"]?[0]?["weather"]?["temp"]?["c"]?["min"].round() ?? "--"}°",
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
                                WeatherIcons.getWeatherContent(
                                    context, weatherData["realtime"]?["condition"].toString() ?? ""),
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
                                "體感溫度: ${weatherData["realtime"]?["feel"]?["c"].round() ?? "--"}°",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.onSurfaceVariant.withOpacity(0.75),
                                ),
                              ),
                              Text(
                                "相對濕度: ${weatherData["realtime"]?["humidity"] ?? "- -"}%",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.onSurfaceVariant.withOpacity(0.75),
                                ),
                              ),
                              Text(
                                "紫外線指數: ${weatherData["realtime"]?["uv"] ?? "- -"}",
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
                  padding: const EdgeInsets.fromLTRB(16, 32, 0, 8),
                  child: Text(
                    context.i18n.hourly_forecast,
                    style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [...weatherCard],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 0, 8),
                  child: Text(
                    context.i18n.current_events,
                    style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
                  ),
                ),
                Builder(
                  builder: (context) {
                    if (realtimeList.isEmpty) {
                      if (region != "") {
                        if (init) {
                          return Center(child: Text(context.i18n.no_events));
                        }
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        return Center(child: Text(context.i18n.out_of_service_only_taiwan));
                      }
                    }

                    List<Widget> children = [];

                    for (var i = 0, n = realtimeList.length; i < n; i++) {
                      final current = realtimeList[i];
                      var showDate = false;

                      if (i != 0) {
                        final prev = realtimeList[i - 1];
                        if (current.time.send.day != prev.time.send.day) {
                          showDate = true;
                        }
                      } else {
                        showDate = true;
                      }

                      final item = TimeLineTile(
                        time: current.time.send,
                        icon: Icon(ListIcons.getListIcon(current.type)),
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
}
