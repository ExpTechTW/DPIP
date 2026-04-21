/// Main home page presenting weather, EEW alerts, and live weather modules.
library;

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/home/_lib/home_priority.dart';
import 'package:dpip/app/home/_models/home_location.dart';
import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/app/home/_widgets/hero_weather.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/home/_widgets/location_not_set_card.dart';
import 'package:dpip/app/home/_widgets/location_out_of_service.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/gps_location.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/models/settings/map.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/shader_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// The main home screen widget.
///
/// Composes a full-screen shader background, a priority-sorted scroll feed
/// (EEW → thunderstorm → routine weather modules), and overlay controls for
/// map/location/settings. The event timeline lives in the separate time tab.
class HomePage extends StatefulWidget {
  /// Creates the [HomePage].
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Key _mapKey = UniqueKey();
  bool _isLoading = false;
  bool _isOutOfService = false;
  bool _wasVisible = true;

  RealtimeWeather? _weather;
  Map<String, dynamic>? _forecast;
  List<History>? _realtimeRegion;

  String? _lastRefreshCode;
  bool _isFirstRefresh = true;

  HomeLocationModel? _homeLocationModel;

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
      _homeLocationModel?.temporaryCode ?? GlobalProviders.location.code;

  Future<void> _refresh() async {
    if (_isLoading) return;

    if (_homeLocationModel?.temporaryCode == null) {
      await _reloadLocationData();
    }

    final code = _effectiveLocationCode;

    final isOutOfService = _checkIfOutOfService(code);

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
    ];

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

    if (_homeLocationModel?.temporaryCode != null) return false;

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

      final temporaryCode = _homeLocationModel?.temporaryCode;
      if (temporaryCode != null) {
        final location = Global.location[temporaryCode];
        if (location != null) {
          coords = LatLng(location.lat, location.lng);
        }
      } else if (Preference.locationLatitude != null && Preference.locationLongitude != null) {
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
      TalkerManager.instance.error(
        '_HomePageState._fetchRealtimeRegion',
        e,
        s,
      );
      if (mounted) setState(() => _realtimeRegion = null);
    }
  }

  Widget _buildHeroSection({required bool compact}) {
    final code = _effectiveLocationCode;
    final screenHeight = context.dimension.height;

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
      compact: compact,
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
        color: context.theme.brightness == .dark ? Colors.white : Colors.black,
        url: 'https://www.threads.net/@dpip.tw',
      ),
      (
        icon: SimpleIcons.youtube,
        color: const Color(0xFFFF0000),
        url: 'https://www.youtube.com/@exptechtw/live',
      ),
      (
        icon: Symbols.favorite_rounded,
        color: context.colors.primary,
        url: SettingsDonateRoute().location,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVersion());
    GlobalProviders.location.$code.addListener(_refresh);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ModalRoute.of(context)?.isCurrent ?? false;
    if (!_wasVisible && isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
    _wasVisible = isVisible;

    final homeSections = context.select<SettingsUserInterfaceModel, List<HomeDisplaySection>>(
      (model) => model.homeSections,
    );
    final eews = context.select<DpipDataModel, List<Eew>>((model) => model.eew);

    final thunderstorm = pickActiveThunderstorm(_realtimeRegion);
    final hasAlerts = eews.isNotEmpty || thunderstorm != null;

    final shaderConfig = ShaderSelector.selectShaderConfig(_weather);
    final shaderBackground = ShaderSelector.buildShaderBackground(
      config: shaderConfig,
      backgroundColor: context.colors.surface,
    );

    final feedModules = buildHomeFeedModules(
      eews: eews,
      thunderstorm: thunderstorm,
      weather: _weather,
      forecast: _forecast,
      sections: homeSections,
      isOutOfService: _isOutOfService,
      isLoading: _isLoading,
      radarKey: _mapKey,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: shaderBackground),
        ),
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                RepaintBoundary(
                  child: _buildHeroSection(compact: hasAlerts),
                ),
                ...feedModules,
                _buildCommunityCards(),
                SizedBox(height: context.padding.bottom + 16),
              ],
            ),
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
                    onPressed: () =>
                        MapRoute(layers: layers.map((l) => l.name).join(',')).push(context),
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
                child: const LocationButton(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = context.read<HomeLocationModel>();
    if (_homeLocationModel != model) {
      _homeLocationModel?.removeListener(_refresh);
      _homeLocationModel = model;
      model.addListener(_refresh);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) _refresh();
  }

  @override
  void dispose() {
    _homeLocationModel?.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    GlobalProviders.location.$code.removeListener(_refresh);
    super.dispose();
  }
}
