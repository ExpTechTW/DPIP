import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/changelog/page.dart';
import 'package:dpip/app/home/_widgets/date_timeline_item.dart';
import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/forecast_card.dart';
import 'package:dpip/app/home/_widgets/history_timeline_item.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/home/_widgets/location_not_set_card.dart';
import 'package:dpip/app/home/_widgets/location_out_of_service.dart';
import 'package:dpip/app/home/_widgets/mode_toggle_button.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app/home/_widgets/thunderstorm_card.dart';
import 'package:dpip/app/home/_widgets/weather_header.dart';
import 'package:dpip/core/gps_location.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Key? _mapKey;
  bool _isLoading = false;
  bool _isOutOfService = false;
  bool _wasVisible = true;

  RealtimeWeather? _weather;
  Map<String, dynamic>? _forecast;
  List<History>? _history;
  List<History>? _realtimeRegion;
  HomeMode _currentMode = HomeMode.localActive;

  String? _lastRefreshCode;
  DateTime? _lastRefreshTime;

  History? get _thunderstorm => _realtimeRegion
      ?.where((e) => e.type == HistoryType.thunderstorm)
      .sorted((a, b) => b.time.send.compareTo(a.time.send))
      .firstOrNull;

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
        content: Text('已更新至 {version}'.i18n.args({'version': 'v${Global.packageInfo.version}'})),
        action: SnackBarAction(label: '更新日誌'.i18n, onPressed: () => context.push(ChangelogPage.route)),
        duration: kPersistSnackBar,
      ),
    );
  }

  Future<void> _refresh() async {
    if (_isLoading) return;

    TalkerManager.instance.debug('🔄 _refresh called');

    await _reloadLocationData();

    final code = GlobalProviders.location.code;
    final coords = GlobalProviders.location.coordinates;
    final auto = GlobalProviders.location.auto;

    TalkerManager.instance.debug('🔄 After reload: code=$code, coords=$coords, auto=$auto');

    if (_shouldSkipRefresh(code)) {
      TalkerManager.instance.debug('🔄 Skipping refresh (throttled)');
      return;
    }

    final isOutOfService = _checkIfOutOfService(code);
    TalkerManager.instance.debug('🔄 isOutOfService=$isOutOfService');

    if (isOutOfService && !_currentMode.isNational) {
      _currentMode = _currentMode.isActive ? HomeMode.nationalActive : HomeMode.nationalHistory;
      TalkerManager.instance.debug('🔄 Switched to national mode');
    }

    setState(() {
      _isLoading = true;
      _isOutOfService = isOutOfService;
      _mapKey = Key('${DateTime.now().millisecondsSinceEpoch}');
    });

    _refreshIndicatorKey.currentState?.show();

    TalkerManager.instance.debug('🔄 Fetching weather, realtime region, and history...');
    await Future.wait([_fetchWeather(code), _fetchRealtimeRegion(code), _fetchHistory(code, isOutOfService)]);

    if (mounted) {
      setState(() => _isLoading = false);
      _lastRefreshCode = code;
      _lastRefreshTime = DateTime.now();
      TalkerManager.instance.debug('🔄 Refresh completed');
    }
  }

  Future<void> _reloadLocationData() async {
    if (GlobalProviders.location.auto) {
      await updateLocationFromGPS();
    } else {
      await Preference.reload();
      GlobalProviders.location.refresh();
    }
  }

  bool _shouldSkipRefresh(String? code) {
    if (_lastRefreshCode != code) return false;
    if (_lastRefreshTime == null) return false;

    final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
    return timeSinceLastRefresh.inMinutes < 1;
  }

  bool _checkIfOutOfService(String? code) {
    if (code == null) return true;

    final auto = GlobalProviders.location.auto;
    final location = Global.location[code];

    return auto && location == null;
  }

  Future<void> _fetchWeather(String? code) async {
    TalkerManager.instance.debug('🌤️ _fetchWeather called with code: $code');

    if (code == null) {
      TalkerManager.instance.debug('🌤️ code is null, clearing weather data');
      if (mounted)
        setState(() {
          _weather = null;
          _forecast = null;
        });
      return;
    }

    try {
      // 使用經緯度取得即時天氣
      final coords = GlobalProviders.location.coordinates;
      TalkerManager.instance.debug('🌤️ coordinates: $coords');

      if (coords != null) {
        TalkerManager.instance.debug('🌤️ Fetching realtime weather for ${coords.latitude}, ${coords.longitude}');
        final weather = await ExpTech().getWeatherRealtimeByCoords(coords.latitude, coords.longitude);
        TalkerManager.instance.debug('🌤️ Got realtime weather: ${weather.toJson()}');
        if (mounted) setState(() => _weather = weather);
      } else {
        TalkerManager.instance.debug('🌤️ coordinates is null, clearing realtime weather');
        if (mounted) setState(() => _weather = null);
      }

      // 取得天氣預報
      TalkerManager.instance.debug('🌤️ Fetching weather forecast for code: $code');
      final forecast = await ExpTech().getWeatherForecast(code);
      TalkerManager.instance.debug('🌤️ Got weather forecast keys: ${forecast.keys}');
      TalkerManager.instance.debug('🌤️ Got weather forecast[\'forecast\']: ${forecast['forecast']}');
      if (mounted) setState(() => _forecast = forecast);
    } catch (e, s) {
      if (!mounted) return;
      TalkerManager.instance.error('_HomePageState._fetchWeather', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('取得天氣異常'.i18n)));
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
      final shouldUseNational = _currentMode.isNational || isOutOfService || code == null;
      final List<History> history;

      if (shouldUseNational) {
        history = _currentMode.isActive ? await ExpTech().getRealtime() : await ExpTech().getHistory();
      } else {
        history = _currentMode.isActive
            ? await ExpTech().getRealtimeRegion(code)
            : await ExpTech().getHistoryRegion(code);
      }

      if (mounted) setState(() => _history = history);
    } catch (e, s) {
      if (!mounted) return;
      TalkerManager.instance.error('_HomePageState._fetchHistory', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('取得歷史資訊異常'.i18n)));
    }
  }

  void _onModeChanged(HomeMode mode) {
    setState(() => _currentMode = mode);
    _lastRefreshTime = null;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ModalRoute.of(context)?.isCurrent ?? false;
    if (!_wasVisible && isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
    _wasVisible = isVisible;

    return Stack(
      children: [
        RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refresh,
          edgeOffset: 16 + 48 + context.padding.top,
          child: ListView(
            children: [
              SizedBox(height: 16 + context.padding.top),
              _buildWeatherHeader(),
              if (!_isLoading) ..._buildRealtimeInfo(),
              _buildRadarMap(),
              _buildHistoryTimeline(),
            ],
          ),
        ),
        const Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Align(alignment: Alignment.topCenter, child: LocationButton()),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherHeader() {
    final code = GlobalProviders.location.code;
    final coords = GlobalProviders.location.coordinates;

    TalkerManager.instance.debug(
      '🌤️ _buildWeatherHeader: isLoading=$_isLoading, weather=$_weather, code=$code, coords=$coords, isOutOfService=$_isOutOfService',
    );

    if (_isLoading) {
      TalkerManager.instance.debug('🌤️ Showing skeleton (loading)');
      return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: WeatherHeader.skeleton(context));
    }
    if (_weather != null) {
      TalkerManager.instance.debug('🌤️ Showing weather header with data');
      return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: WeatherHeader(_weather!));
    }

    // 檢查是否有設定所在地 (code 存在)
    final hasLocation = code != null;

    if (_isOutOfService) {
      TalkerManager.instance.debug('🌤️ Showing out of service card');
      return const Padding(padding: EdgeInsets.all(16), child: LocationOutOfServiceCard());
    }

    // 如果有設定所在地但沒有天氣資料，可能是正在載入或發生錯誤，顯示 skeleton
    if (hasLocation) {
      TalkerManager.instance.debug('🌤️ Showing skeleton (has location but no weather)');
      return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: WeatherHeader.skeleton(context));
    }

    TalkerManager.instance.debug('🌤️ Showing location not set card');
    return const Padding(padding: EdgeInsets.all(16), child: LocationNotSetCard());
  }

  List<Widget> _buildRealtimeInfo() {
    return [
      if (GlobalProviders.data.eew.isNotEmpty)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: GlobalProviders.data.eew.length,
          itemBuilder: (context, index) =>
              Padding(padding: const EdgeInsets.all(16), child: EewCard(GlobalProviders.data.eew[index])),
        ),
      if (_thunderstorm != null) Padding(padding: const EdgeInsets.all(16), child: ThunderstormCard(_thunderstorm!)),
      if (_forecast != null) ForecastCard(_forecast!),
    ];
  }

  Widget _buildRadarMap() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: RadarMapCard(key: _mapKey),
    );
  }

  Widget _buildHistoryTimeline() {
    return Builder(
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

        final grouped = groupBy(history, (e) => e.time.send.toLocaleFullDateString(context));

        return Column(
          children: grouped.entries
              .sorted((a, b) => b.key.compareTo(a.key))
              .mapIndexed((index, entry) => _buildHistoryGroup(entry, index, history))
              .toList(),
        );
      },
    );
  }

  Widget _buildHistoryGroup(MapEntry<String, List<History>> entry, int index, List<History> allHistory) {
    final historyGroup = entry.value.sorted((a, b) => b.time.send.compareTo(a.time.send));

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
          return HistoryTimelineItem(expired: item.isExpired, history: item, last: item == allHistory.last);
        }),
      ],
    );
  }
}
