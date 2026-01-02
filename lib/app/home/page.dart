import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
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
import 'package:dpip/app/settings/donate/page.dart';
import 'package:dpip/core/gps_location.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/shader_selector.dart';
import 'package:dpip/utils/wallpaper_selector.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

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
  DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Key _mapKey = UniqueKey();
  bool _isLoading = false;
  bool _isOutOfService = false;
  bool _wasVisible = true;
  double? _locationButtonHeight;

  final _blurNotifier = ValueNotifier<double>(0.0);
  final _sheetSizeNotifier = ValueNotifier<double>(0.5);

  final _firstCardKey = GlobalKey();
  double? _measuredFirstCardHeight;
  Key _sheetKey = UniqueKey();

  static const double _defaultFirstCardHeight = 280.0;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
      _measureFirstCard();
    });
    GlobalProviders.location.$code.addListener(_refresh);
    _sheetController.addListener(_onSheetChanged);
    _refresh();
  }

  void _measureFirstCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardContext = _firstCardKey.currentContext;
      if (cardContext != null) {
        final box = cardContext.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final height = box.size.height + 28;
          final isFirstMeasure = _measuredFirstCardHeight == null;
          if (isFirstMeasure ||
              ((_measuredFirstCardHeight! - height).abs() > 1)) {
            _sheetController.removeListener(_onSheetChanged);
            _sheetController.dispose();

            setState(() {
              _measuredFirstCardHeight = height;
              _sheetKey = UniqueKey();
              _sheetController = DraggableScrollableController();
            });

            _sheetController.addListener(_onSheetChanged);

            if (isFirstMeasure && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final screenHeight = MediaQuery.of(context).size.height;
                final targetSize = (height / screenHeight).clamp(0.25, 0.6);
                _sheetController.animateTo(
                  targetSize,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              });
            }
          }
        }
      }
    });
  }

  double get _firstCardHeight =>
      _measuredFirstCardHeight ?? _defaultFirstCardHeight;

  void _onSheetChanged() {
    final size = _sheetController.size;
    _sheetSizeNotifier.value = size;
    final screenHeight = MediaQuery.of(context).size.height;
    final baseSize = (_firstCardHeight / screenHeight).clamp(0.25, 0.6);
    final progress = ((size - baseSize) / (0.95 - baseSize)).clamp(0.0, 1.0);
    final newBlur = progress * 15.0;
    if ((newBlur - _blurNotifier.value).abs() > 0.3) {
      _blurNotifier.value = newBlur;
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _blurNotifier.dispose();
    _sheetSizeNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    GlobalProviders.location.$code.removeListener(_refresh);
    _scrollController.dispose();
    _sheetController.dispose();
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
          onPressed: () => ChangelogRoute().push(context),
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

    final utc8Time = WallpaperSelector.getUtc8Time();
    final wallpaperPath = WallpaperSelector.selectWallpaper(utc8Time);
    final shaderConfig = ShaderSelector.selectShaderConfig(_weather);
    final shaderBackground = ShaderSelector.buildShaderBackground(
      config: shaderConfig,
      imagePath: wallpaperPath,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: shaderBackground,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildHeroSection(),
        ),
        ValueListenableBuilder<double>(
          valueListenable: _blurNotifier,
          builder: (context, blurAmount, child) {
            if (blurAmount <= 0) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurAmount,
                    sigmaY: blurAmount,
                  ),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: blurAmount / 60),
                  ),
                ),
              ),
            );
          },
        ),
        _buildDraggableSheet(homeSections),
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

  Widget _buildDraggableSheet(Set<HomeDisplaySection> homeSections) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseSnapSize = (_firstCardHeight / screenHeight).clamp(0.25, 0.6);
    final initialSize = _measuredFirstCardHeight == null ? 0.05 : baseSnapSize;

    return DraggableScrollableSheet(
      key: _sheetKey,
      controller: _sheetController,
      initialChildSize: initialSize,
      minChildSize: 0.05,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: [0.05, baseSnapSize, 0.95],
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _sheetSizeNotifier,
              builder: (context, size, child) {
                final opacity = ((0.95 - size) / 0.1).clamp(0.0, 1.0);
                if (opacity <= 0) return const SizedBox(height: 12);
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            _buildContentSection(homeSections),
          ],
        );
      },
    );
  }

  Widget _buildHeroSection() {
    final code = GlobalProviders.location.code;
    final screenHeight = MediaQuery.of(context).size.height;

    if (code == null) {
      return SizedBox(
        height: screenHeight * 0.5,
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
        height: screenHeight * 0.5,
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
    final List<Widget> allCards = [];
    bool isFirstCardSet = false;

    if (!_isLoading) {
      for (final widget in _buildRealtimeInfo()) {
        if (!isFirstCardSet) {
          allCards.add(KeyedSubtree(key: _firstCardKey, child: widget));
          isFirstCardSet = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _measureFirstCard(),
          );
        } else {
          allCards.add(widget);
        }
      }
    }

    if (homeSections.isNotEmpty) {
      if (homeSections.contains(HomeDisplaySection.radar)) {
        final radarWidget = _buildRadarMap();
        if (!isFirstCardSet) {
          allCards.add(KeyedSubtree(key: _firstCardKey, child: radarWidget));
          isFirstCardSet = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _measureFirstCard(),
          );
        } else {
          allCards.add(radarWidget);
        }
      }
      if (homeSections.contains(HomeDisplaySection.forecast)) {
        allCards.add(_buildForecast());
      }
      if (!_isLoading &&
          homeSections.contains(HomeDisplaySection.wind) &&
          _weather != null) {
        allCards.add(_buildWindCard());
      }
      allCards.add(_buildCommunityCards());
      if (homeSections.contains(HomeDisplaySection.history)) {
        allCards.add(_buildHistoryTimeline());
      }
    } else if (GlobalProviders.location.code != null) {
      allCards.add(
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
                onPressed: () => SettingsLayoutRoute().push(context),
                child: Text('前往設定'.i18n),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...allCards,
        // 底部安全區域
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildCommunityCards() {
    return ResponsiveContainer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                    onTap: () =>
                        launchUrl(Uri.parse('https://exptech.com.tw/dc')),
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
                    onTap: () => launchUrl(
                      Uri.parse('https://www.threads.net/@dpip.tw'),
                    ),
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
                      Uri.parse('https://www.youtube.com/@exptechtw/live'),
                    ),
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
