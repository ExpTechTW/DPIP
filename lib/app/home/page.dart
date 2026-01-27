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
import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:dpip/models/settings/map.dart';
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
  DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Key _mapKey = UniqueKey();
  bool _isLoading = false;
  bool _isOutOfService = false;
  bool _wasVisible = true;

  final _blurNotifier = ValueNotifier<double>(0.0);
  final _isFullyExpandedNotifier = ValueNotifier<bool>(false);

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
  String? _temporaryLocationCode;

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
    final screenHeight = MediaQuery.of(context).size.height;
    final baseSize = (_firstCardHeight / screenHeight).clamp(0.25, 0.6);
    final progress = ((size - baseSize) / (1.0 - baseSize)).clamp(0.0, 1.0);
    final newBlur = (progress * 15.0 / 5.0).round() * 5.0;
    if ((_blurNotifier.value - newBlur).abs() >= 4.9) {
      _blurNotifier.value = newBlur;
    }
    final isFullyExpanded = size >= 0.99;
    if (_isFullyExpandedNotifier.value != isFullyExpanded) {
      _isFullyExpandedNotifier.value = isFullyExpanded;
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _blurNotifier.dispose();
    _isFullyExpandedNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    GlobalProviders.location.$code.removeListener(_refresh);
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

  String? get _effectiveLocationCode =>
      _temporaryLocationCode ?? GlobalProviders.location.code;

  Future<void> _refresh() async {
    if (_isLoading) return;

    if (_temporaryLocationCode == null) {
      await _reloadLocationData();
    }

    final code = _effectiveLocationCode;

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

    final futures = <Future>[
      _fetchWeather(code),
      _fetchRealtimeRegion(code),
      _fetchHistory(code, isOutOfService),
    ];

    await Future.wait(futures);

    if (mounted) {
      setState(() => _isLoading = false);
      _lastRefreshCode = code;
    }
  }

  void _onTemporaryLocationChanged(String? code) {
    setState(() {
      _temporaryLocationCode = code;
    });
    _refresh();
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

    if (_temporaryLocationCode != null) return false;

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

      if (_temporaryLocationCode != null) {
        final location = Global.location[_temporaryLocationCode];
        if (location != null) {
          coords = LatLng(location.lat, location.lng);
        }
      } else if (Preference.locationLatitude != null &&
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
        .select<SettingsUserInterfaceModel, List<HomeDisplaySection>>(
          (model) => model.homeSections,
        );

    final utc8Time = WallpaperSelector.getUtc8Time();
    final wallpaperPath = WallpaperSelector.selectWallpaper(utc8Time);
    final shaderConfig = ShaderSelector.selectShaderConfig(_weather);
    final shaderBackground = ShaderSelector.buildShaderBackground(
      config: shaderConfig,
      imagePath: wallpaperPath,
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final baseSnapSize = (_firstCardHeight / screenHeight).clamp(0.25, 0.6);
    final handleHeight = 28.0 / screenHeight;
    final minSize = handleHeight.clamp(0.03, 0.05);
    final snapSizes = [minSize, baseSnapSize, 1.0];

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              if (!_sheetController.isAttached) return;
              final delta = -details.primaryDelta! / screenHeight;
              final newSize = (_sheetController.size + delta).clamp(
                minSize,
                1.0,
              );
              _sheetController.jumpTo(newSize);
            },
            onVerticalDragEnd: (details) {
              if (!_sheetController.isAttached) return;
              final currentSize = _sheetController.size;
              final velocity = details.primaryVelocity ?? 0;

              double targetSnap;
              if (velocity.abs() > 500) {
                if (velocity > 0) {
                  targetSnap =
                      snapSizes.where((s) => s < currentSize).lastOrNull ??
                      snapSizes.first;
                } else {
                  targetSnap =
                      snapSizes.where((s) => s > currentSize).firstOrNull ??
                      snapSizes.last;
                }
              } else {
                targetSnap = snapSizes.first;
                double minDist = (currentSize - targetSnap).abs();
                for (final snap in snapSizes) {
                  final dist = (currentSize - snap).abs();
                  if (dist < minDist) {
                    minDist = dist;
                    targetSnap = snap;
                  }
                }
              }

              _sheetController.animateTo(
                targetSnap,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            },
            child: RepaintBoundary(
              child: shaderBackground,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: RepaintBoundary(
            child: _buildHeroSection(),
          ),
        ),
        Positioned(
          top: 24,
          left: 24,
          child: SafeArea(
            child: RepaintBoundary(
              child: Selector<SettingsMapModel, Set<MapLayer>>(
                selector: (context, model) => model.layers,
                builder: (context, layers, child) {
                  return BlurredIconButton(
                    icon: const Icon(Symbols.map_rounded),
                    tooltip: '地圖',
                    onPressed: () => context.push(
                      MapPage.route(
                        options: MapPageOptions(initialLayers: layers),
                      ),
                    ),
                    elevation: 2,
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: 24,
          right: 24,
          child: SafeArea(
            child: RepaintBoundary(
              child: BlurredIconButton(
                icon: const Icon(Symbols.settings_rounded),
                tooltip: '設定',
                onPressed: () => SettingsIndexRoute().push(context),
                elevation: 2,
              ),
            ),
          ),
        ),
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: SafeArea(
            child: RepaintBoundary(
              child: Align(
                alignment: Alignment.topCenter,
                child: LocationButton(
                  temporaryCode: _temporaryLocationCode,
                  onLocationChanged: _onTemporaryLocationChanged,
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<double>(
          valueListenable: _blurNotifier,
          builder: (context, blurAmount, child) {
            if (blurAmount <= 0) return const SizedBox.shrink();
            final filter = ImageFilter.blur(
              sigmaX: blurAmount,
              sigmaY: blurAmount,
              tileMode: TileMode.clamp,
            );
            return Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: filter,
                      blendMode: BlendMode.srcOver,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: blurAmount / 50),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        _buildDraggableSheet(homeSections),
      ],
    );
  }

  Widget _buildDraggableSheet(List<HomeDisplaySection> homeSections) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseSnapSize = (_firstCardHeight / screenHeight).clamp(0.25, 0.6);
    final handleHeight = 28.0 / screenHeight;
    final minSize = handleHeight.clamp(0.03, 0.05);
    final initialSize = _measuredFirstCardHeight == null
        ? minSize
        : baseSnapSize;
    final snapSizes = [minSize, baseSnapSize, 1.0];

    return DraggableScrollableSheet(
      key: _sheetKey,
      controller: _sheetController,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: snapSizes,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              RepaintBoundary(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isFullyExpandedNotifier,
                  builder: (context, isFullyExpanded, child) {
                    return AnimatedOpacity(
                      opacity: isFullyExpanded ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 150),
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
                    );
                  },
                ),
              ),
              RepaintBoundary(
                child: _buildContentSection(homeSections),
              ),
            ],
          ),
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

  Widget _buildContentSection(List<HomeDisplaySection> homeSections) {
    final List<Widget> allCards = [];
    final List<Widget> firstCardChildren = [];

    final stationInfo = _buildStationInfo();
    firstCardChildren.add(stationInfo);

    Widget? firstSectionWidget;
    int? firstSectionIndex;

    if (!_isLoading) {
      final realtimeWidgets = _buildRealtimeInfo();
      allCards.addAll(realtimeWidgets);
    }
    for (var i = 0; i < homeSections.length; i++) {
      final section = homeSections[i];
      switch (section) {
        case HomeDisplaySection.radar:
          firstSectionWidget = _buildRadarMap();
          firstSectionIndex = i;
        case HomeDisplaySection.forecast:
          firstSectionWidget = _buildForecast();
          firstSectionIndex = i;
        case HomeDisplaySection.wind:
          if (!_isLoading && _weather != null) {
            firstSectionWidget = _buildWindCard();
            firstSectionIndex = i;
          }
      }
      if (firstSectionWidget != null) break;
    }

    if (firstSectionWidget != null) {
      firstCardChildren.add(firstSectionWidget);
    }

    allCards.add(
      KeyedSubtree(
        key: _firstCardKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: firstCardChildren,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureFirstCard());
    for (var i = 0; i < homeSections.length; i++) {
      if (i == firstSectionIndex) continue;
      final section = homeSections[i];
      switch (section) {
        case HomeDisplaySection.radar:
          allCards.add(_buildRadarMap());
        case HomeDisplaySection.forecast:
          allCards.add(_buildForecast());
        case HomeDisplaySection.wind:
          if (_weather != null) {
            allCards.add(_buildWindCard());
          }
      }
    }

    allCards.add(_buildHistoryTimeline());
    allCards.add(_buildCommunityCards());

    return Column(
      children: [
        ...allCards,
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildCommunityCards() {
    final options = [
      (
        icon: SimpleIcons.discord,
        color: const Color(0xFF5865F2),
        url: 'https://exptech.com.tw/dc',
      ),
      (
        icon: SimpleIcons.threads,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        url: 'https://www.threads.net/@dpip.tw',
      ),
      (
        icon: SimpleIcons.youtube,
        color: const Color(0xFFFF0000),
        url: 'https://www.youtube.com/@exptechtw/live',
      ),
      (
        icon: Symbols.favorite_rounded,
        color: Theme.of(context).colorScheme.primary,
        url: SettingsDonatePage.route,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: options.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (item.url.startsWith('/')) {
                    context.push(item.url);
                  } else {
                    launchUrl(Uri.parse(item.url));
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerLow.withValues(
                      alpha: 0.6,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 24, color: item.color),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStationInfo() {
    final weather = _weather;
    final hasData = weather != null;

    String timeStr = '--:--';
    if (hasData) {
      final dt = DateTime.fromMillisecondsSinceEpoch(weather.time);
      final hour = dt.hour;
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = hour < 12 ? '上午'.i18n : '下午'.i18n;
      timeStr =
          '$period ${hour12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    String stationLabel = '--';
    if (hasData) {
      stationLabel = weather.station.name;
      if (weather.station.distance >= 0) {
        stationLabel += '・${weather.station.distance.toStringAsFixed(1)}km';
      }
    }

    Widget buildChip(String label, String value, Color color) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.texts.labelSmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color.fromARGB(255, 90, 90, 90),
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  style: context.texts.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color.fromARGB(255, 60, 60, 60),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ResponsiveContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.pin_drop_rounded,
                    size: 15,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stationLabel,
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: context.texts.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  buildChip(
                    '濕度'.i18n,
                    hasData && weather.data.humidity >= 0
                        ? '${weather.data.humidity.round().toString().padLeft(3)}%'
                        : '---',
                    Colors.cyan,
                  ),
                  buildChip(
                    '氣壓'.i18n,
                    hasData && weather.data.pressure >= 0
                        ? '${weather.data.pressure.round().toString().padLeft(4)}hPa'
                        : '----',
                    Colors.purple,
                  ),
                  buildChip(
                    '降雨'.i18n,
                    hasData && weather.data.rain >= 0
                        ? '${weather.data.rain.toStringAsFixed(1).padLeft(5)}mm'
                        : '----',
                    Colors.blue,
                  ),
                  buildChip(
                    '能見度'.i18n,
                    hasData && weather.data.visibility >= 0
                        ? '${weather.data.visibility.round().toString().padLeft(2)}km'
                        : '--',
                    Colors.amber,
                  ),
                  buildChip(
                    '風速'.i18n,
                    hasData && weather.data.wind.speed >= 0
                        ? '${weather.data.wind.direction.isNotEmpty ? '${weather.data.wind.direction} ' : ''}${weather.data.wind.speed.toStringAsFixed(1)}m/s'
                        : '----',
                    Colors.teal,
                  ),
                  buildChip(
                    '陣風'.i18n,
                    hasData && weather.data.gust.speed >= 0
                        ? '${weather.data.gust.speed.toStringAsFixed(1).padLeft(4)}m/s'
                        : '----',
                    Colors.orange,
                  ),
                ],
              ),
            ],
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
