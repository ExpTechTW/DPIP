import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/route/settings/settings.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/list_icon.dart';
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
  String city = '', town = '', region = '';
  final scrollController = ScrollController();
  late final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  bool isAppBarVisible = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _setupScrollListener();
    HomePage.setActiveCallback(_handlePositionUpdate);
  }

  @override
  void dispose() {
    HomePage.clearActiveCallback();
    scrollController.dispose();
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
    city = Global.preference.getString('location-city') ?? '';
    town = Global.preference.getString('location-town') ?? '';
    region = Global.location.entries.firstWhereOrNull((l) => l.value.city == city && l.value.town == town)?.key ?? '';
  }

  Future<void> _refreshWeatherData() async {
    if (region.isEmpty) return;
    final data = await ExpTech().getWeatherRealtime(region);
    setState(() => weatherData = data);
  }

  Future<void> refreshRealtimeList() async {
    if (region.isEmpty) return;
    final data = country ? await ExpTech().getRealtime() : await ExpTech().getRealtimeRegion(region);
    if (mounted) {
      setState(() => realtimeList = data.reversed.toList());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMainContent(),
          _buildAppBar(),
        ],
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

  Widget _buildLocationButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/settings'),
            builder: (context) => const SettingsRoute(initialRoute: '/location'),
          ),
        ),
        icon: const Icon(Symbols.pin_drop_rounded),
        label: Text('$city$town', style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildTemperatureDisplay() {
    final tempParts = (weatherData['weather']?['data']?['air']?['temperature'] ?? '--').toString().split('.');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
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
                  text: tempParts.length > 1 ? '.${tempParts[1]}°C' : '°C',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    color: context.colors.onPrimaryContainer.withOpacity(0.85),
                  ),
                ),
              ],
            ),
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
          _buildWeatherDetailItem('濕度', '${weatherData['weather']?['data']?['air']?['relative_humidity'] ?? '- -'} %'),
          _buildWeatherDetailItem('降水量', '${weatherData['rain']?['data']?['1h'] ?? '- -'} mm'),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailItem(String label, String value) {
    return Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 16,
        color: context.colors.onSurfaceVariant.withOpacity(0.75),
      ),
    );
  }

  Widget _buildLocationToggle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              icon: Symbols.public_rounded,
              label: '全國',
              isSelected: country,
              onTap: () => _toggleView(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildToggleButton(
              icon: Symbols.my_location_rounded,
              label: '所在地',
              isSelected: !country,
              onTap: () => _toggleView(false),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleView(bool isCountry) {
    setState(() {
      country = isCountry;
      refreshRealtimeList();
    });
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
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
        realtimeList.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  context.i18n.home_safety,
                  style: TextStyle(fontSize: 16, color: context.colors.onSurfaceVariant),
                ),
              )
            : Column(
                children: realtimeList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final current = entry.value;
                  final showDate = index == 0 || current.time.send.day != realtimeList[index - 1].time.send.day;

                  return TimeLineTile(
                    time: current.time.send,
                    icon: Icon(ListIcons.getListIcon(current.icon)),
                    height: 100,
                    first: index == 0,
                    showDate: showDate,
                    color: context.colors.error,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.text.content['all']!.subtitle, style: context.theme.textTheme.titleMedium),
                        Text(current.text.description['all']!),
                      ],
                    ),
                    onTap: () {},
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
