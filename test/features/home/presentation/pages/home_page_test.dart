/// Home is a sheet over a map. The tests drive the sheet, the forced sky, and
/// the two taps (map and the gold support bar) without waiting on a ticker
/// that never settles.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolveBackdrop keeps a forced look off the live channels', () {
    const wind = WeatherWind();
    final rain = WeatherRealtimeData(
      weather: 'rain',
      weatherCode: 6,
      humidity: 80,
      wind: wind,
      gust: wind,
    );
    final snow = WeatherRealtimeData(
      weather: 'snow',
      weatherCode: 8,
      humidity: 40,
      wind: wind,
      gust: wind,
    );

    final absent = resolveBackdrop(WeatherMode.auto, null);
    expect(absent.mode, WeatherMode.auto);
    expect(absent.rain, isNull);
    expect(absent.snow, isNull);
    expect(absent.humidity, isNull);

    final liveRain = resolveBackdrop(WeatherMode.auto, rain);
    expect(liveRain.rain, 0.35);
    expect(liveRain.humidity, 80);
    expect(liveRain.snow, isNull);

    final liveSnow = resolveBackdrop(WeatherMode.auto, snow);
    expect(liveSnow.snow, 1);
    expect(liveSnow.rain, isNull);

    final forced = resolveBackdrop(WeatherMode.clear, rain);
    expect(forced.mode, WeatherMode.clear);
    expect(forced.rain, isNull);
    expect(forced.snow, isNull);
    expect(forced.humidity, isNull);
  });

  testWidgets('sheet, sky, and the map and support taps', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);

    final platform = _MapPlatform();
    final previous = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => MapLibrePlatform.createInstance = previous);

    final settings = SettingsStore.inMemory();
    final store = RegionStore(settings);
    store.select(0);
    final experimental = ExperimentalSettings(settings);
    final extent = HomeSheetExtent();
    final reset = HomeResetSignal();
    final handoff = MapCameraHandoff();
    final tab = VisibleTab(0);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final router = GoRouter(
      initialLocation: AppRoutes.homePath,
      routes: [
        GoRoute(
          path: AppRoutes.homePath,
          name: AppRoutes.home,
          builder: (_, _) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.mapPath,
          name: AppRoutes.map,
          builder: (_, _) => const Text('map-route'),
        ),
        GoRoute(
          path: AppRoutes.sponsorPath,
          name: AppRoutes.sponsor,
          builder: (_, _) => const Text('sponsor-route'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      VisibleTabScope(
        visibleTab: tab,
        child: MultiProvider(
          providers: _providers(
            store: store,
            experimental: experimental,
            extent: extent,
            reset: reset,
            handoff: handoff,
          ),
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await _flush(tester);
    expect(find.text(l10n.sponsorTitle), findsOneWidget);

    await tester.tap(find.text(l10n.sponsorTitle).hitTestable());
    await tester.pump();
    await tester.pump();
    expect(
      find.text('sponsor-route'),
      findsOneWidget,
      reason: 'location ${router.state.uri}',
    );
    router.go(AppRoutes.homePath);
    await _flush(tester);

    extent.value = 0.96;
    experimental.weatherMode = WeatherMode.rain;
    experimental.skyTimeMode = SkyTimeMode.noon;
    await tester.pump();
    extent.value = HomeSheetExtent.rest;
    tab.value = 2;
    await tester.pump();
    tab.shellOnTop = false;
    await tester.pump();
    tab.value = 0;
    tab.shellOnTop = true;
    await tester.pump();
    reset.fire();
    await tester.pump();

    await tester.tapAt(const Offset(400, 220));
    await tester.pump();
    await tester.pump();
    expect(find.text('map-route'), findsOneWidget);
    final nationwide = handoff.takePending();
    expect(nationwide?.layerId, 'radar');
    router.go(AppRoutes.homePath);
    await _flush(tester);

    store.addSaved('6300100');
    store.select(2);
    handoff.homeBounds = LatLngBounds(
      southwest: const LatLng(25, 121.5),
      northeast: const LatLng(25.1, 121.6),
    );
    await tester.pump();
    await tester.tapAt(const Offset(400, 220));
    await tester.pump();
    expect(handoff.takePending()?.layerId, 'radar');
    router.go(AppRoutes.homePath);
    await _flush(tester);

    store.setCurrentCode('6300100');
    store.select(1);
    handoff.homeBounds = null;
    await tester.pump();
    await tester.tapAt(const Offset(400, 220));
    await tester.pump();
    expect(handoff.takePending(), isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
  }
}

List<SingleChildWidget> _providers({
  required RegionStore store,
  required ExperimentalSettings experimental,
  required HomeSheetExtent extent,
  required HomeResetSignal reset,
  required MapCameraHandoff handoff,
}) {
  const directory = TownDirectory({});
  final events = _Events();
  final clock = _Clock();
  return [
    ChangeNotifierProvider<RegionStore>.value(value: store),
    ChangeNotifierProvider<ExperimentalSettings>.value(value: experimental),
    ChangeNotifierProvider<HomeSheetExtent>.value(value: extent),
    ChangeNotifierProvider<HomeResetSignal>.value(value: reset),
    ChangeNotifierProvider<MapCameraHandoff>.value(value: handoff),
    ChangeNotifierProvider(create: (_) => MapStationHandoff()),
    Provider<TownDirectory>.value(value: directory),
    Provider<LocationService>.value(
      value: LocationService(
        directory,
        isAvailable: () async => false,
        fix: () async => null,
        lastKnown: () async => null,
        status: () async => LocationStatus.denied,
      ),
    ),
    Provider<Future<TownBoundaries>>.value(
      value: Future<TownBoundaries>.value(_boundaries()),
    ),
    Provider<RadarRepository>.value(value: _Radar()),
    Provider<EventRepository>.value(value: events),
    ChangeNotifierProvider(
      create: (_) => HomeWeatherController(
        const _Weather(),
        _Hours(),
        store,
        directory,
        gpsFix: () async => null,
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => HomeActiveEventsController(events, store),
    ),
    ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>(
      create: (_) => RealtimeNotifier<List<Eew>>(
        RealtimeChannel<List<Eew>>(
          source: _NoEew(),
          clock: clock,
          elapsed: _Elapsed(),
          ticker: _Ticker(),
          config: RealtimeConfig.eew,
          label: 'home-eew',
        ),
      ),
    ),
    Provider<Future<SeismicTravelTimeTable>>.value(
      value: Future<SeismicTravelTimeTable>.value(
        const SeismicTravelTimeTable({}),
      ),
    ),
  ];
}

class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 1, 15, 4);
}

class _Elapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _Ticker implements Ticker {
  @override
  TickerHandle start(Duration interval, void Function() onTick) => _Handle();
}

class _Handle implements TickerHandle {
  @override
  void cancel() {}
}

class _NoEew extends RealtimeSource<List<Eew>> {
  @override
  Future<Result<List<Eew>>> fetch() async => const Ok([]);

  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => true;
}

class _Events implements EventRepository {
  @override
  Future<Result<List<Event>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async =>
      const Ok([]);
}

class _Weather implements MeteorWeatherRepository {
  const _Weather();

  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async =>
      const Ok(null);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(const WeatherForecast(updateTime: 0, forecast: []));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _Hours implements RainHourTrendRepository {
  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async =>
      Ok(RainHourTrend.dry(startUtc: DateTime.utc(2026, 1, 15)));
}

class _Radar implements RadarRepository {
  @override
  Future<Result<List<String>>> frames() async => const Ok([]);

  @override
  int get sourceMaxZoom => 8;

  @override
  int get sourceMinZoom => 3;

  @override
  String tileUrl(String frame) => 'https://example.test/$frame/{z}/{x}/{y}.png';

  @override
  Future<void> warmFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool fill = false,
    bool immediate = false,
    bool refreshResident = false,
  }) async {}

  @override
  Future<FrameTileReadiness> frameTileReadiness({
    required String frame,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool warm = false,
  }) async => (ready: true, resident: 0, required: 0);

  @override
  void cancelTileWarm() {}

  @override
  Future<void> abandonFrames(List<String> frames) async {}

  @override
  Future<void> releaseTiles() async {}
}

TownBoundaries _boundaries() => TownBoundaries.fromDecoded(<String, dynamic>{
  '6300100': <String, dynamic>{
    'b': <num>[121.50, 25.02, 121.55, 25.06],
    'p': <dynamic>[
      <dynamic>[
        <num>[
          121.50, 25.02, 121.55, 25.02, 121.55, 25.06, 121.50, 25.06, //
          121.50, 25.02,
        ],
      ],
    ],
  },
});

class _MapPlatform extends MapLibrePlatform {
  final layers = <String>{};
  final sources = <String>{};

  @override
  Future<void> initPlatform(int id) async {
    onMapStyleLoadedPlatform.call(null);
  }

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    onPlatformViewCreated(1);
    return const SizedBox.shrink();
  }

  @override
  Future<void> setRenderPaused(bool paused) async {}

  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) async => null;

  @override
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async => true;

  @override
  Future<List<dynamic>> getLayerIds() async => const [];

  @override
  Future<void> addGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {
    sources.add(sourceId);
  }

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson,
  ) async {}

  @override
  Future<void> addLineLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addFillLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addCircleLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addSymbolLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addRasterLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async {
    sources.add(sourceId);
  }

  @override
  Future<void> removeLayer(String layerId) async {
    if (!layers.remove(layerId)) throw StateError('missing layer $layerId');
  }

  @override
  Future<void> removeSource(String sourceId) async {
    if (!sources.remove(sourceId)) {
      throw StateError('missing source $sourceId');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor) return null;
    return Future<void>.value();
  }
}
