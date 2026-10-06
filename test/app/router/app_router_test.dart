/// The route table is built when this library loads. These tests run the
/// redirect and each page builder; they do not start Firebase or a database.
library;

import 'package:dio/dio.dart';
import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/shell/main_shell.dart';
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/map_reference_outline_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/meshtastic/data/dpip_mesh_gateway_impl.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/features/changelog/changelog_providers.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/events_providers.dart';
import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:dpip/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/weather_providers.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../core/meshtastic/fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every route builder can construct its page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox));
    final built = <Widget>[];
    _walk(appRouter.configuration.routes, context, built);
    expect(built, isNotEmpty);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('an unfinished welcome stays put until the refresh fires', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory();
    await settings.setString(SettingKeys.locale, 'en');
    final onboarding = OnboardingStore(settings);
    final locale = LocaleController(settings);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OnboardingStore>.value(value: onboarding),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OnboardingPage), findsOneWidget);

    await onboarding.complete();
    await tester.pump();
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a finished welcome opens the home shell', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final platform = _MapPlatform();
    final previous = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => MapLibrePlatform.createInstance = previous);

    final deps = _deps(complete: true);
    onboardingRefresh.fire();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ...coreProviders(deps),
          ...changelogProviders(deps),
          Provider<ChangelogRepository>.value(value: _Notes()),
          ...eventsProviders(deps),
          Provider<EventRepository>.value(value: _Events()),
          ...weatherProviders(deps),
          Provider<RadarRepository>.value(value: _Radar()),
          ...homeProviders(),
          _eew(),
          Provider<Future<SeismicTravelTimeTable>>.value(
            value: Future<SeismicTravelTimeTable>.value(
              const SeismicTravelTimeTable({}),
            ),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    appRouter.go('/nowhere');
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

void _walk(List<RouteBase> routes, BuildContext context, List<Widget> built) {
  for (final route in routes) {
    switch (route) {
      case GoRoute():
        final builder = route.builder;
        if (builder != null) {
          built.add(builder(context, _state(route.path)));
        }
        _walk(route.routes, context, built);
      case StatefulShellRoute():
        for (final branch in route.branches) {
          _walk(branch.routes, context, built);
        }
      default:
        break;
    }
  }
}

GoRouterState _state(String path) => GoRouterState(
  appRouter.configuration,
  uri: Uri.parse('/x/42?t=1700000000&tab=temp&replace=6300100&returnToMore=1'),
  matchedLocation: '/x/42',
  name: path,
  path: path,
  fullPath: path,
  pathParameters: const {'id': '42', 'city': 'Taipei'},
  pageKey: ValueKey<String>(path),
);

ChangeNotifierProvider<RealtimeNotifier<List<Eew>>> _eew() =>
    ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>(
      create: (_) => RealtimeNotifier<List<Eew>>(
        RealtimeChannel<List<Eew>>(
          source: _NoEew(),
          clock: _Clock(),
          elapsed: _Elapsed(),
          ticker: _Ticker(),
          config: RealtimeConfig.eew,
          label: 'router-eew',
        ),
      ),
    );

SharedDeps _deps({required bool complete}) {
  final settings = SettingsStore.inMemory();
  if (complete) {
    settings.setBool(SettingKeys.onboardingComplete, true);
  }
  final regions = RegionSelection(settings);
  final mesh = FakeMeshService();
  final location = LocationService(
    const TownDirectory({}),
    isAvailable: () async => false,
    fix: () async => null,
    lastKnown: () async => null,
    status: () async => LocationStatus.denied,
  );
  final clock = ServerClock(_Clock(), _Elapsed(), _Time());
  return SharedDeps(
    settings: settings,
    database: const AppDatabase(durable: null, cache: null),
    tleStore: const TleStore(null),
    apiClient: ApiClient(Dio(), regions),
    regions: regions,
    experimental: ExperimentalSettings(settings),
    serverClock: clock,
    realtimeService: RealtimeService(clock, ticker: _Ticker()),
    notificationService: NotificationService(settings),
    townDirectory: const TownDirectory({}),
    townBoundaries: Future<TownBoundaries>.value(_boundaries()),
    regionStore: RegionStore(settings)..select(0),
    locationService: location,
    deviceLocationReporter: DeviceLocationReporter(
      positions: () => const Stream.empty(),
      onMoved: (_) async => false,
      settings: settings,
      now: () => DateTime.utc(2026, 1, 15),
    ),
    backgroundLocation: BackgroundLocationService(
      platform: 0,
      version: '1',
      channel: const MethodChannel('test/router_bg'),
    ),
    locationMonitor: LocationMonitor(
      location: location,
      reporter: DeviceLocationReporter(
        positions: () => const Stream.empty(),
        onMoved: (_) async => false,
        settings: settings,
        now: () => DateTime.utc(2026, 1, 15),
      ),
      regions: RegionStore(settings),
    ),
    permissionHealth: PermissionHealth(
      location: location,
      notifications: NotificationService(settings),
    ),
    onboarding: OnboardingStore(settings),
    locale: LocaleController(settings),
    theme: ThemeController(settings),
    colorVision: ColorVisionController(settings),
    display: DisplaySettings(settings),
    defaultMapLayer: DefaultMapLayerController(settings),
    mapLayerOrder: MapLayerOrderController(settings),
    mapLayerVisibility: MapLayerVisibilityController(settings),
    mapReferenceOutline: MapReferenceOutlineController(settings),
    meshtastic: mesh,
    meshLink: MeshLink(mesh, settings),
    meshAlerts: MeshAlerts(
      mesh,
      settings,
      post: (_) async {},
      now: () => DateTime.utc(2026, 1, 15),
    ),
    meshNodes: MeshNodeStore(
      mesh,
      settings,
      now: () => DateTime.utc(2026, 1, 15),
    ),
    meshUnread: MeshUnread(null),
    meshGateway: DpipMeshGatewayImpl(mesh, () => null),
    endpointHealth: EndpointHealthMonitor(),
  );
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

class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 1, 15);
}

class _Elapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _Time implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => const Ok(1768435200000);
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

class _Notes implements ChangelogRepository {
  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async =>
      const Ok([]);

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(UnexpectedFailure('no avatar'));
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
  Future<List<dynamic>> getLayerIds() async => layers.toList();

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
