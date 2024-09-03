import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/route/settings/settings.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/list_icon.dart';
import 'package:dpip/util/weather_icon.dart';
import 'package:dpip/widget/error/region_out_of_service.dart';
import 'package:dpip/widget/home/event_list_route.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
  List<History> realtimeList = [];
  Map<String, dynamic> weatherData = {};
  bool country = false;
  String city = '';
  String town = '';
  bool isLoading = true;
  String? region;
  final scrollController = ScrollController();
  late final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  bool isAppBarVisible = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initData();
    _setupScrollListener();
    HomePage.setActiveCallback(_handlePositionUpdate);
    _tabController = TabController(length: 2, vsync: this);
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

  void _initData() async {
    _loadLocationData();
    await _refreshWeatherData();
    await refreshRealtimeList();
  }

  void _loadLocationData() {
    int code = Global.preference.getInt("user-code") ?? -1;
    city = Global.location[code.toString()]?.city ?? "";
    town = Global.location[code.toString()]?.town ?? "";
    region = code == -1 ? null : code.toString();
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
      setState(() => isAppBarVisible = scrollController.offset > 1e-5);
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/settings'),
                  builder: (context) => const SettingsRoute(initialRoute: '/location'),
                ),
              );
            },
            icon: const Icon(Symbols.pin_drop_rounded),
            label: Text('$city$town', style: const TextStyle(fontSize: 20)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildMainContent(),
                  _buildAppBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: refreshRealtimeList,
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: scrollController,
        children: [
          _buildWeatherHeader(),
          _buildLocationToggle(),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildWeatherHeader() {
    return Container(
      height: 360,
      padding: EdgeInsets.only(top: context.padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withOpacity(0.12),
            context.colors.primaryContainer.withOpacity(0.08),
            Colors.transparent
          ],
          stops: const [0.16, 0.6, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationButton(),
          _buildTemperatureDisplay(),
          _buildWeatherDetails(),
        ],
      ),
    );
  }

  Widget _buildTemperatureDisplay() {
    final tempParts = (weatherData['weather']?['data']?['air']?['temperature'] ?? '--').toString().split('.');
    final weatherCode = weatherData['weather']?['data']?['weather'] == "-99" ? -99 :
    weatherData['weather']?['data']?['weatherCode'] ?? 100;
    const isDay = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                          color: context.colors.onPrimaryContainer.withOpacity(0.85),
                        ),
                      ),
                      TextSpan(
                        text: tempParts[0] == '--'
                            ? ".-°C"
                            : tempParts.length > 1
                                ? '.${tempParts[1]}°C'
                                : '.0°C',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          color: context.colors.onPrimaryContainer.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  WeatherIcons.getWeatherContent(context, weatherCode.toString()),
                  style: TextStyle(
                    fontSize: 18,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            WeatherIcons.getWeatherIcon(weatherCode, isDay),
            size: 80,
            color: context.colors.primary,
          ),
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
          _buildWeatherDetailItem('降水量', '${weatherData['rain']?['data']?['1h'] ?? '- -'} mm'),
          _buildWeatherDetailItem('濕度', '${weatherData['weather']?['data']?['air']?['relative_humidity'] ?? '- -'} %'),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailItem(String label, String value) {
    return Text(
      '$label   $value',
      style: TextStyle(
        fontSize: 18,
        color: context.colors.onSurfaceVariant.withOpacity(0.75),
      ),
    );
  }

  Widget _buildLocationToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(child: _buildToggleButton(true, Symbols.public_rounded, '全國')),
            Expanded(child: _buildToggleButton(false, Symbols.my_location_rounded, '所在地')),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool isCountry, IconData icon, String label) {
    final isSelected = country == isCountry;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? context.colors.primaryContainer.withOpacity(0.7) : Colors.transparent,
              borderRadius: BorderRadius.horizontal(
                left: isCountry ? const Radius.circular(18) : Radius.zero,
                right: !isCountry ? const Radius.circular(18) : Radius.zero,
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () => setState(() {
            country = isCountry;
            refreshRealtimeList();
          }),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    if (region == null && !country) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: RegionOutOfService(),
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (realtimeList.isEmpty) {
      return Center(child: Text(context.i18n.no_historical_events));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 0, 8),
          child: Text(
            context.i18n.current_events,
            style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
          ),
        ),
        Column(
          children: realtimeList.asMap().entries.map((entry) {
            final index = entry.key;
            final current = entry.value;
            final showDate = index == 0 || current.time.send.day != realtimeList[index - 1].time.send.day;

            return TimeLineTile(
              time: current.time.send,
              icon: Icon(ListIcons.getListIcon(current.icon)),
              height: 140,
              first: index == 0,
              showDate: showDate,
              color: context.colors.error,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.text.content["all"]!.subtitle,
                          style: context.theme.textTheme.titleMedium,
                        ),
                        Text(
                          current.text.description["all"]!,
                        ),
                      ],
                    ),
                  ),
                  if (shouldShowArrow(current))
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.arrow_forward_ios),
                    ),
                ],
              ),
              onTap: () => handleEventList(context, current),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: isAppBarVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: AppBar(
          elevation: 4,
          title: Text(context.i18n.home),
          backgroundColor: context.colors.surface.withOpacity(0.8),
        ),
      ),
    );
  }
}
