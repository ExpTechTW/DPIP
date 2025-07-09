import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app_old/page/history/widgets/date_timeline_item.dart';
import 'package:dpip/app_old/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/time_convert.dart';
import 'package:dpip/utils/weather_icon.dart';
import 'package:dpip/widgets/error/region_out_of_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timezone/timezone.dart';

typedef PositionUpdateCallback = void Function();

class HomePage extends StatefulWidget {
  final Function()? onPositionUpdate;

  const HomePage({super.key, this.onPositionUpdate});

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
  late final locale = Localizations.localeOf(context).toString();
  List<History> realtimeList = [];
  RealtimeWeather? weatherData;
  bool country = false;
  String city = '';
  String town = '';
  bool isLoading = true;
  String? region;
  final scrollController = ScrollController();
  late final animController = AnimationController(vsync: this, duration: Duration.zero);
  bool isAppBarVisible = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initData();
    _setupScrollListener();
    HomePage.setActiveCallback(_handlePositionUpdate);
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    HomePage.clearActiveCallback();
    scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handlePositionUpdate() {
    if (mounted) {
      _initData();
      widget.onPositionUpdate?.call();
    }
  }

  Future<void> _initData() async {
    if (Platform.isIOS && (Global.preference.getBool('auto-location') ?? false)) {
      await getSavedLocation();
    }
    final int code = Global.preference.getInt('user-code') ?? -1;
    city = Global.location[code.toString()]?.city ?? '';
    town = Global.location[code.toString()]?.town ?? '';
    region = code == -1 ? null : code.toString();
    await _refreshWeatherData();
    await refreshRealtimeList();
  }

  Future<void> _refreshWeatherData() async {
    if (region == null) return;
    final data = await ExpTech().getWeatherRealtime(region!);
    setState(() => weatherData = data);
  }

  Future<void> refreshRealtimeList() async {
    if (region == null && !country) return;
    setState(() => isLoading = true);
    try {
      final data = country ? await ExpTech().getRealtime() : await ExpTech().getRealtimeRegion(region!);
      if (mounted) {
        setState(() {
          realtimeList = data.reversed.toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      setState(() => isAppBarVisible = scrollController.offset > 1e-4);

      if (scrollController.offset < 240) {
        animController.animateTo(scrollController.offset / 240);
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        country = _tabController.index == 0;
        refreshRealtimeList();
      });
    }
  }

  Widget _buildLocationButton() {
    return Builder(
      builder: (context) {
        return Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              context.push('/settings');
              context.push('/settings/location');
            },
            icon: const Icon(Symbols.pin_drop_rounded),
            label: Text(region != null ? '$city$town' : '點擊設定所在地', style: const TextStyle(fontSize: 20)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [_buildMainContent(), _buildAppBar()]));
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshWeatherData();
        await refreshRealtimeList();
      },
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildWeatherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('目前的事件資訊', style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant)),
                ),
                _buildLocationToggle(),
              ],
            ),
          ),
          _buildHomeList(isCountryView: country),
        ],
      ),
    );
  }

  Widget _buildLocationToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(icon: Icon(Symbols.public_rounded), tooltip: '全國', value: true),
          ButtonSegment(icon: Icon(Symbols.home_rounded), tooltip: '所在地', value: false),
        ],
        selected: {country},
        onSelectionChanged:
            (p0) => setState(() {
              country = p0.first;
              refreshRealtimeList();
            }),
      ),
    );
  }

  Widget _buildHomeList({required bool isCountryView}) {
    if (region == null && !country) {
      return const RegionOutOfService();
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (realtimeList.isEmpty) {
      return const Center(child: Text('一切平安，無事件發生。'));
    }

    final grouped = groupBy(realtimeList, (e) => DateFormat('yyyy/MM/dd (EEEE)', locale).format(e.time.send));

    return Column(
      children:
          grouped.entries.map((entry) {
            final date = entry.key;
            final historyGroup = entry.value;
            return Column(
              children: [
                DateTimelineItem(date),
                ...historyGroup.map((history) {
                  final int? expireTimestamp = history.time.expires['all'];
                  final TZDateTime expireTimeUTC = convertToTZDateTime(expireTimestamp ?? 0);
                  final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
                  return HistoryTimelineItem(expired: isExpired, history: history, last: history == realtimeList.last);
                }),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildWeatherHeader() {
    return Container(
      height: 360,
      padding: EdgeInsets.only(top: context.padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withValues(alpha: 0.12),
            context.colors.primaryContainer.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.16, 0.6, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildLocationButton(), _buildTemperatureDisplay(), _buildWeatherDetails()],
      ),
    );
  }

  Widget _buildTemperatureDisplay() {
    final tempParts = (weatherData?.weather.data.air.temperature ?? '--').toString().split('.');
    final weatherCode = weatherData?.weather.data.weatherCode ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: tempParts[0],
                        style: TextStyle(
                          fontSize: 68,
                          fontWeight: FontWeight.w500,
                          color: context.colors.onPrimaryContainer.withValues(alpha: 0.85),
                        ),
                      ),
                      TextSpan(
                        text:
                            tempParts[0] == '--'
                                ? '.-°C'
                                : tempParts.length > 1
                                ? '.${tempParts[1]}°C'
                                : '.0°C',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          color: context.colors.onPrimaryContainer.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  WeatherIcons.getWeatherContent(context, weatherCode),
                  style: TextStyle(fontSize: 18, color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(WeatherIcons.getWeatherIcon(weatherCode, true), size: 80, color: context.colors.primary),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherDetailItem('降水量', '${weatherData?.rain.data.oneHour ?? '- -'} mm/h'),
          _buildWeatherDetailItem('濕度', '${weatherData?.weather.data.air.relativeHumidity ?? '- -'} %'),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailItem(String label, String value) {
    return Text(
      '$label   $value',
      style: TextStyle(fontSize: 18, color: context.colors.onSurfaceVariant.withValues(alpha: 0.75)),
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Visibility(
        visible: isAppBarVisible,
        child: FadeTransition(
          opacity: animController.drive(Tween(begin: 0.0, end: 1.0)),
          child: AppBar(elevation: 4, title: const Text('首頁')),
        ),
      ),
    );
  }
}
