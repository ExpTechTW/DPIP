import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/settings/donate/page.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/changelog/page.dart';
import 'package:dpip/app/home/_widgets/date_timeline_item.dart';
import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/forecast_card.dart';
import 'package:dpip/app/home/_widgets/hero_weather.dart';
import 'package:dpip/app/home/_widgets/history_timeline_item.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/home/_widgets/location_not_set_card.dart';
import 'package:dpip/app/home/_widgets/location_out_of_service.dart';
import 'package:dpip/app/home/_widgets/mode_toggle_button.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app/home/_widgets/thunderstorm_card.dart';
import 'package:dpip/app/home/_widgets/wind_card.dart';
import 'package:dpip/app/settings/layout/page.dart';
import 'package:dpip/core/gps_location.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/rain_shader_background.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'home_display_mode.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _locationButtonKey = GlobalKey();
  final _scrollController = ScrollController();

  Key _mapKey = UniqueKey();
  bool _isLoading = false;
  bool _isOutOfService = false;
  bool _wasVisible = true;
  double? _locationButtonHeight;

  RealtimeWeather? _weather;
  Map<String, dynamic>? _forecast;
  List<History>? _history;
  List<History>? _realtimeRegion;
  HomeMode _currentMode = HomeMode.localActive;

  String? _lastRefreshCode;
  bool _isFirstRefresh = true;

  History? get _thunderstorm => _realtimeRegion
      ?.where((e) => e.type == HistoryType.thunderstorm)
      .sorted((a, b) => b.time.send.compareTo(a.time.send))
      .firstOrNull;

  /// 是否正在下雨（用於決定是否顯示雨滴效果）
  bool get _isRaining {
    // TODO: 測試完成後移除強制啟用
    return true;
    // if (_weather == null) return false;
    // final code = _weather!.data.weatherCode;
    // // 雨天代碼範圍：15-35（包含雨、大雨、雷雨）
    // return code >= 15 && code <= 35;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVersion());
    GlobalProviders.location.$code.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GlobalProviders.location.$code.removeListener(_refresh);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _checkVersion() {
    Preference.version ??= Global.packageInfo.version;
    if (Global.packageInfo.version == Preference.version) return;

    Preference.version = Global.packageInfo.version;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          '已更新至 {version}'.i18n.args({
            'version': 'v${Global.packageInfo.version}',
          }),
        ),
        action: SnackBarAction(
          label: '更新日誌'.i18n,
          onPressed: () => context.push(ChangelogPage.route),
        ),
        duration: kPersistSnackBar,
      ),
    );
  }

  Future<void> _refresh() async {
    if (_isLoading) return;

    await _reloadLocationData();

    final code = GlobalProviders.location.code;

    final isOutOfService = _checkIfOutOfService(code);

    if (isOutOfService && !_currentMode.isNational) {
      _currentMode = _currentMode.isActive
          ? HomeMode.nationalActive
          : HomeMode.nationalHistory;
    }

    setState(() {
      _isLoading = true;
      _isOutOfService = isOutOfService;
      if (!_isFirstRefresh && _lastRefreshCode != code) {
        _mapKey = Key('${DateTime.now().millisecondsSinceEpoch}');
        _weather = null;
        _forecast = null;
      }
      _isFirstRefresh = false;
    });

    _refreshIndicatorKey.currentState?.show();

    final homeSections = context
        .read<SettingsUserInterfaceModel>()
        .homeSections;

    final futures = <Future>[
      _fetchWeather(code),
      _fetchRealtimeRegion(code),
    ];

    if (homeSections.contains(HomeDisplaySection.history)) {
      futures.add(_fetchHistory(code, isOutOfService));
    } else {
      if (mounted) {
        setState(() {
          _history = null;
        });
      }
    }

    await Future.wait(futures);

    if (mounted) {
      setState(() => _isLoading = false);
      _lastRefreshCode = code;
    }
  }

  Future<void> _reloadLocationData() async {
    if (GlobalProviders.location.auto) {
      await updateLocationFromGPS();
    } else {
      await Preference.reload();
      final code = Preference.locationCode;
      if (code != null) {
        final location = Global.location[code];
        if (location != null) {
          Preference.locationLatitude = location.lat;
          Preference.locationLongitude = location.lng;
        }
      }
      GlobalProviders.location.refresh();
    }
  }

  bool _checkIfOutOfService(String? code) {
    if (code == null) return true;

    final auto = GlobalProviders.location.auto;
    final location = Global.location[code];

    return auto && location == null;
  }

  Future<void> _fetchWeather(String? code) async {
    if (code == null) {
      if (mounted)
        setState(() {
          _weather = null;
          _forecast = null;
        });
      return;
    }

    try {
      LatLng? coords;
      if (Preference.locationLatitude != null &&
          Preference.locationLongitude != null) {
        coords = LatLng(
          Preference.locationLatitude!,
          Preference.locationLongitude!,
        );
      } else {
        coords = GlobalProviders.location.coordinates;
      }

      if (coords != null) {
        final weather = await ExpTech().getWeatherRealtimeByCoords(
          coords.latitude,
          coords.longitude,
        );
        if (mounted) setState(() => _weather = weather);
      } else {
        if (mounted) setState(() => _weather = null);
      }

      final forecast = await ExpTech().getWeatherForecast(code);
      if (mounted) setState(() => _forecast = forecast);
    } catch (e, s) {
      if (!mounted) return;
      TalkerManager.instance.error('_HomePageState._fetchWeather', e, s);
      context.scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('取得天氣異常'.i18n)),
      );
    }
  }

  Future<void> _fetchRealtimeRegion(String? code) async {
    if (code == null) {
      if (mounted) setState(() => _realtimeRegion = null);
      return;
    }

    try {
      final realtime = await ExpTech().getRealtimeRegion(code);
      if (mounted) setState(() => _realtimeRegion = realtime);
    } catch (e, s) {
      if (!mounted) return;
      TalkerManager.instance.error('_HomePageState._fetchRealtimeRegion', e, s);
      if (mounted) setState(() => _realtimeRegion = null);
    }
  }

  Future<void> _fetchHistory(String? code, bool isOutOfService) async {
    try {
      final shouldUseNational =
          _currentMode.isNational || isOutOfService || code == null;
      final List<History> history;

      if (shouldUseNational) {
        history = _currentMode.isActive
            ? await ExpTech().getRealtime()
            : await ExpTech().getHistory();
      } else {
        history = _currentMode.isActive
            ? await ExpTech().getRealtimeRegion(code)
            : await ExpTech().getHistoryRegion(code);
      }

      if (mounted) setState(() => _history = history);
    } catch (e, s) {
      if (!mounted) return;
      TalkerManager.instance.error('_HomePageState._fetchHistory', e, s);
      context.scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('取得歷史資訊異常'.i18n)),
      );
    }
  }

  void _onModeChanged(HomeMode mode) {
    setState(() => _currentMode = mode);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ModalRoute.of(context)?.isCurrent ?? false;
    if (!_wasVisible && isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
    _wasVisible = isVisible;

    final homeSections = context
        .select<SettingsUserInterfaceModel, Set<HomeDisplaySection>>(
          (model) => model.homeSections,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _locationButtonKey.currentContext != null) {
        final RenderBox? box =
            _locationButtonKey.currentContext!.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final newHeight = box.size.height;
          if (_locationButtonHeight != newHeight) {
            setState(() {
              _locationButtonHeight = newHeight;
            });
          }
        }
      }
    });

    return Stack(
      children: [
        // 雨滴背景（全螢幕，持續顯示）
        Positioned.fill(
          child: RainShaderBackground(
            animated: _isRaining,
          ),
        ),
        // 主內容
        RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 英雄區塊 - 第一屏簡潔顯示
              SliverToBoxAdapter(
                child: _buildHeroSection(),
              ),
              // 詳細內容區塊
              SliverToBoxAdapter(
                child: _buildContentSection(homeSections),
              ),
            ],
          ),
        ),
        // 位置按鈕
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: LocationButton(key: _locationButtonKey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final code = GlobalProviders.location.code;

    // 如果沒有設定位置或服務區域外，顯示提示
    if (code == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: LocationNotSetCard(),
          ),
        ),
      );
    }

    if (_isOutOfService) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: LocationOutOfServiceCard(),
          ),
        ),
      );
    }

    return HeroWeather(
      weather: _weather,
      isLoading: _isLoading,
    );
  }

  Widget _buildContentSection(Set<HomeDisplaySection> homeSections) {
    return Column(
      children: [
        // 拖曳指示器
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // 實時警報
        if (!_isLoading) ..._buildRealtimeInfo(),
        // 其他區塊
        if (homeSections.isNotEmpty) ...[
          if (homeSections.contains(HomeDisplaySection.radar))
            _buildRadarMap(),
          if (homeSections.contains(HomeDisplaySection.forecast))
            _buildForecast(),
          if (!_isLoading && _weather != null) _buildWindCard(),
          _buildCommunityCards(),
          if (homeSections.contains(HomeDisplaySection.history))
            _buildHistoryTimeline(),
        ] else if (GlobalProviders.location.code != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '您還沒有啟用首頁區塊，請到設定選擇要顯示的內容。'.i18n,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push(SettingsLayoutPage.route),
                  child: Text('前往設定'.i18n),
                ),
              ],
            ),
          ),
        // 底部安全區域
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildCommunityCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Symbols.group_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '社群'.i18n,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 社群卡片
          Row(
            children: [
              Expanded(
                child: _buildSocialCard(
                  icon: SimpleIcons.discord,
                  label: 'Discord',
                  color: const Color(0xFF5865F2),
                  onTap: () => launchUrl(Uri.parse('https://exptech.com.tw/dc')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSocialCard(
                  icon: SimpleIcons.threads,
                  label: 'Threads',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  onTap: () =>
                      launchUrl(Uri.parse('https://www.threads.net/@dpip.tw')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSocialCard(
                  icon: SimpleIcons.youtube,
                  label: 'YouTube',
                  color: const Color(0xFFFF0000),
                  onTap: () => launchUrl(
                      Uri.parse('https://www.youtube.com/@exptechtw/live')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDonateCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonateCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(SettingsDonatePage.route),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.tertiaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.favorite_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '贊助我們'.i18n,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRealtimeInfo() {
    return [
      if (GlobalProviders.data.eew.isNotEmpty)
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: GlobalProviders.data.eew.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.all(16),
            child: EewCard(GlobalProviders.data.eew[index]),
          ),
        ),
      if (_thunderstorm != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: ThunderstormCard(_thunderstorm!),
        ),
    ];
  }

  Widget _buildWindCard() {
    if (_weather == null) return const SizedBox.shrink();
    return WindCard(_weather!);
  }

  Widget _buildRadarMap() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: RadarMapCard(key: _mapKey),
    );
  }

  Widget _buildForecast() {
    if (_forecast == null) return const SizedBox.shrink();
    return ForecastCard(_forecast!);
  }

  Widget _buildHistoryTimeline() {
    return ResponsiveContainer(
      child: Builder(
        builder: (context) {
          final history = _history;

          if (history == null || history.isEmpty) {
            return Column(
              children: [
                DateTimelineItem(
                  TZDateTime.now(UTC).toLocaleFullDateString(context),
                  first: true,
                  last: true,
                  mode: _currentMode,
                  onModeChanged: _onModeChanged,
                  isOutOfService: _isOutOfService,
                ),
              ],
            );
          }

          final grouped = groupBy(
            history,
            (e) => e.time.send.toLocaleFullDateString(context),
          );

          return Column(
            children: grouped.entries
                .sorted((a, b) => b.key.compareTo(a.key))
                .mapIndexed(
                  (index, entry) => _buildHistoryGroup(entry, index, history),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildHistoryGroup(
    MapEntry<String, List<History>> entry,
    int index,
    List<History> allHistory,
  ) {
    final historyGroup = entry.value.sorted(
      (a, b) => b.time.send.compareTo(a.time.send),
    );

    return Column(
      children: [
        DateTimelineItem(
          entry.key,
          first: index == 0,
          mode: index == 0 ? _currentMode : null,
          onModeChanged: index == 0 ? _onModeChanged : null,
          isOutOfService: _isOutOfService,
        ),
        ...historyGroup.map((item) {
          return HistoryTimelineItem(
            expired: item.isExpired,
            history: item,
            last: item == allHistory.last,
          );
        }),
      ],
    );
  }
}
