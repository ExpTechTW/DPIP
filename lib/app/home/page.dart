import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:provider/provider.dart';
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
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';
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

  Key? _mapKey;
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

    await _reloadLocationData();

    final code = GlobalProviders.location.code;

    if (_shouldSkipRefresh(code)) return;

    final isOutOfService = _checkIfOutOfService(code);

    if (isOutOfService && !_currentMode.isNational) {
      _currentMode = _currentMode.isActive ? HomeMode.nationalActive : HomeMode.nationalHistory;
    }

    setState(() {
      _isLoading = true;
      _isOutOfService = isOutOfService;
      _mapKey = Key('${DateTime.now().millisecondsSinceEpoch}');
      if (_lastRefreshCode != code) {
        _weather = null;
        _forecast = null;
      }
    });

    _refreshIndicatorKey.currentState?.show();

    await Future.wait([_fetchWeather(code), _fetchRealtimeRegion(code), _fetchHistory(code, isOutOfService)]);

    if (mounted) {
      setState(() => _isLoading = false);
      _lastRefreshCode = code;
      _lastRefreshTime = DateTime.now();
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

  bool _shouldSkipRefresh(String? code) {
    if (_lastRefreshCode != code) {
      _lastRefreshCode = code;
      _lastRefreshTime = null;
      return false;
    }
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
      if (Preference.locationLatitude != null && Preference.locationLongitude != null) {
        coords = LatLng(Preference.locationLatitude!, Preference.locationLongitude!);
      } else {
        coords = GlobalProviders.location.coordinates;
      }

      if (coords != null) {
        final weather = await ExpTech().getWeatherRealtimeByCoords(coords.latitude, coords.longitude);
        if (mounted) setState(() => _weather = weather);
      } else {
        if (mounted) setState(() => _weather = null);
      }

      final forecast = await ExpTech().getWeatherForecast(code);
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
    final model = context.watch<SettingsUserInterfaceModel>();
    final topPadding = MediaQuery.of(context).padding.top;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _locationButtonKey.currentContext != null) {
        final RenderBox? box = _locationButtonKey.currentContext!.findRenderObject() as RenderBox?;
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
        RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.only(
              top: _locationButtonHeight != null ? 16 + topPadding + _locationButtonHeight! : 0,
            ),
            children: [
              if (model.isEnabled(HomeDisplaySection.weather))
                _buildWeatherHeader(),
              if (model.isEnabled(HomeDisplaySection.realtime))
                ..._buildRealtimeInfo(),
              if (model.isEnabled(HomeDisplaySection.radar))
                _buildRadarMap(),
              if (model.isEnabled(HomeDisplaySection.forecast))
                _buildForecast(),
              if (model.isEnabled(HomeDisplaySection.history))
                _buildHistoryTimeline(),
            ],
          ),
        ),
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

  Widget _buildWeatherHeader() {
    final code = GlobalProviders.location.code;

    if (_isLoading) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: WeatherHeader.skeleton(context));
    }
    if (_weather != null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: WeatherHeader(_weather!));
    }

    if (_isOutOfService) {
      return const Padding(padding: EdgeInsets.all(16), child: LocationOutOfServiceCard());
    }

    if (code != null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: WeatherHeader.skeleton(context));
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

  Widget _buildForecast() {
    if (_forecast == null) return const SizedBox.shrink();
    return ForecastCard(_forecast!);
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
