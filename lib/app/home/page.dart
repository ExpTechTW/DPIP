import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/changelog/page.dart';
import 'package:dpip/app/home/_widgets/date_timeline_item.dart';
import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/history_timeline_item.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/home/_widgets/location_not_set_card.dart';
import 'package:dpip/app/home/_widgets/location_out_of_service.dart';
import 'package:dpip/app/home/_widgets/mode_toggle_button.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app/home/_widgets/thunderstorm_card.dart';
import 'package:dpip/app/home/_widgets/weather_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/time_convert.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:timezone/timezone.dart';
import 'dart:io';

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

    // 重新載入位置數據
    if (Platform.isIOS && GlobalProviders.location.auto) {
      // iOS: 從 native 端讀取保存的位置
      await updateSavedLocationIOS();
    } else {
      // Android: 重新載入 SharedPreferences 緩存以獲取背景 task 寫入的最新數據
      await Preference.reload();
      GlobalProviders.location.refresh();
    }

    final auto = GlobalProviders.location.auto;
    final code = GlobalProviders.location.code;
    final location = Global.location[code];
    // 服務區外的情況包括:
    // 1. 啟用自動定位但沒有有效位置 (auto && code == null)
    // 2. 沒有設定任何位置 (code == null)
    final isOutOfService = code == null || (auto && location == null);

    // 如果 code 不變且距離上次刷新不到 1 分鐘，跳過刷新
    final now = DateTime.now();
    if (_lastRefreshCode == code &&
        _lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inMinutes < 1) {
      return;
    }

    // 如果服務區外或尚未設定所在地，切換到全國模式
    if ((isOutOfService || code == null) && !_currentMode.isNational) {
      _currentMode = _currentMode.isActive ? HomeMode.nationalActive : HomeMode.nationalHistory;
    }

    setState(() {
      _isLoading = true;
      _isOutOfService = isOutOfService;
      _mapKey = Key('${DateTime.now().millisecondsSinceEpoch}');
    });

    _refreshIndicatorKey.currentState?.show();

    await Future.wait([_fetchWeather(code), _fetchRealtimeRegion(code), _fetchHistory(code, isOutOfService)]);

    if (mounted) {
      setState(() => _isLoading = false);
      _lastRefreshCode = code;
      _lastRefreshTime = now;
    }
  }

  Future<void> _fetchWeather(String? code) async {
    if (code == null) {
      if (mounted) setState(() => _weather = null);
      return;
    }

    try {
      final weather = await ExpTech().getWeatherRealtime(code);
      if (mounted) setState(() => _weather = weather);
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
    // 強制刷新，重置時間戳以略過 1 分鐘限制
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
          edgeOffset: 24 + 48 + context.padding.top,
          child: ListView(
            children: [
              SizedBox(height: 24 + 48 + context.padding.top),
              _buildWeatherHeader(),
              if (!_isLoading) ..._buildRealtimeInfo(),
              _buildRadarMap(),
              _buildHistoryTimeline(),
            ],
          ),
        ),
        const Positioned(
          top: 24,
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
    if (_isLoading) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: WeatherHeader.skeleton(context));
    }
    if (_weather != null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: WeatherHeader(_weather!));
    }
    if (_isOutOfService) {
      return const Padding(padding: EdgeInsets.all(16), child: LocationOutOfServiceCard());
    }
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
          final expireTime = convertToTZDateTime(item.time.expires['all'] ?? 0);
          final isExpired = TZDateTime.now(UTC).isAfter(expireTime.toUtc());
          return HistoryTimelineItem(expired: isExpired, history: item, last: item == allHistory.last);
        }),
      ],
    );
  }
}
