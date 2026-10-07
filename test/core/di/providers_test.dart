/// The composition root, without booting the app.
///
/// `coreProviders` and `weatherProviders` are the lists `bootstrap` installs.
/// A missed repository — one satellite channel sharing another's warmer, a
/// wind model left at the radar zoom — would only show up once a map asked
/// for tiles. Building the lists with fakes is enough to see each one.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh_gateway.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/platform/widget_location_catalog_coordinator.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
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
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/features/weather/data/frame_tile_repository.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/features/weather/weather_providers.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../core/meshtastic/fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('each overlay gets its own warmer, zoom and path', (
    tester,
  ) async {
    final deps = _deps();
    final warmers = [deps.mapTileWarmer(), deps.mapTileWarmer()];
    expect(identical(warmers[0], warmers[1]), isFalse);
    expect(_deps().mapTileWarmer(), isNotNull);

    late RadarRepository radarRepo;
    late QpesumsRepository qpesumsRepo;
    late SatelliteRepository satelliteRepo;
    late Map<SatelliteChannel, SatelliteRepository> channels;
    late Map<WindForecastModel, WindForecastRepository> winds;
    await tester.pumpWidget(
      MultiProvider(
        providers: weatherProviders(deps),
        child: Builder(
          builder: (context) {
            radarRepo = context.read<RadarRepository>();
            qpesumsRepo = context.read<QpesumsRepository>();
            satelliteRepo = context.read<SatelliteRepository>();
            channels = context
                .read<Map<SatelliteChannel, SatelliteRepository>>();
            winds = context
                .read<Map<WindForecastModel, WindForecastRepository>>();
            context.read<MeteorWeatherRepository>();
            context.read<MeteorRainRepository>();
            context.read<MeteorLightningRepository>();
            context.read<RainHourTrendRepository>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final radar = radarRepo as FrameTileRepositoryImpl;
    final qpesums = qpesumsRepo as FrameTileRepositoryImpl;
    final satellite = satelliteRepo as FrameTileRepositoryImpl;
    expect(radar.sourceMaxZoom, 11);
    expect(radar.sourceMinZoom, 3);
    expect(radar.tilePathPrefix, contains('radar'));
    expect(qpesums.sourceMaxZoom, 11);
    expect(qpesums.sourceMinZoom, 3);
    expect(qpesums.tilePathPrefix, contains('qpesums'));
    expect(satellite.sourceMaxZoom, 11);
    expect(satellite.sourceMinZoom, 0);
    expect(satellite.tilePathPrefix, contains('satellite'));

    expect(channels.keys, SatelliteChannel.values.toSet());
    final urls = {
      for (final entry in channels.entries)
        entry.key: (entry.value as FrameTileRepositoryImpl).tileUrl('1'),
    };
    expect(urls.values.toSet(), hasLength(SatelliteChannel.values.length));
    expect(urls[SatelliteChannel.visibleBlue], contains('/satellite/1/'));

    expect(winds.keys, WindForecastModel.values.toSet());
    for (final model in WindForecastModel.values) {
      final repo = winds[model]! as FrameTileRepositoryImpl;
      expect(repo.sourceMaxZoom, 6);
      expect(repo.tileUrl('1@2'), contains('/wind/${model.key}/'));
    }
  });

  testWidgets('core providers can be read, and speech is disposed with them', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      ),
    );

    final deps = _deps();
    await tester.pumpWidget(
      MultiProvider(
        providers: coreProviders(deps),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _ReadCore(),
        ),
      ),
    );
    expect(find.text('speech'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _ReadCore extends StatelessWidget {
  const _ReadCore();

  @override
  Widget build(BuildContext context) {
    context.read<SpeechService>();
    context.read<NotificationService>();
    context.read<RealtimeService>();
    context.read<MeshLink>();
    context.read<MeshAlerts>();
    return const Text('speech');
  }
}

SharedDeps _deps() {
  final settings = SettingsStore.inMemory();
  final service = FakeMeshService();
  final location = LocationService(const TownDirectory({}));
  final regions = RegionStore(settings);
  final notifications = NotificationService(settings);
  final clock = ServerClock(const SystemClock(), SystemElapsed(), _Time());
  return SharedDeps(
    settings: settings,
    database: const AppDatabase(durable: null, cache: null),
    tleStore: const TleStore(null),
    apiClient: ApiClient(Dio(), RegionSelection(settings)),
    regions: RegionSelection(settings),
    experimental: ExperimentalSettings(settings),
    serverClock: clock,
    realtimeService: RealtimeService(clock),
    notificationService: notifications,
    townDirectory: const TownDirectory({}),
    townBoundaries: Future.value(
      TownBoundaries.fromDecoded({
        '100': {
          'b': [121.0, 25.0, 121.1, 25.1],
          'p': [
            [
              [121.0, 25.0, 121.1, 25.0, 121.1, 25.1, 121.0, 25.1, 121.0, 25.0],
            ],
          ],
        },
      }),
    ),
    regionStore: regions,
    widgetLocationCatalogCoordinator: WidgetLocationCatalogCoordinator(
      regions,
      const TownDirectory({}),
      IosWidgetSnapshotWriter(isSupportedPlatform: false),
    ),
    locationService: location,
    deviceLocationReporter: DeviceLocationReporter(
      positions: () => const Stream<GpsFix>.empty(),
      onMoved: (_) async => true,
      settings: settings,
    ),
    backgroundLocation: BackgroundLocationService(platform: 0, version: '1'),
    locationMonitor: LocationMonitor(
      location: location,
      reporter: DeviceLocationReporter(
        positions: () => const Stream<GpsFix>.empty(),
        onMoved: (_) async => true,
        settings: settings,
      ),
      regions: regions,
    ),
    permissionHealth: PermissionHealth(
      location: location,
      notifications: notifications,
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
    meshtastic: service,
    meshLink: MeshLink(service, settings),
    meshAlerts: MeshAlerts(service, settings, post: (_) async {}),
    meshNodes: MeshNodeStore(service, settings),
    meshUnread: MeshUnread(null),
    meshGateway: _Gateway(),
    endpointHealth: EndpointHealthMonitor(),
  );
}

class _Time implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => const Ok(0);
}

class _Gateway implements DpipMeshGateway {
  @override
  Stream<DpipMeshPacket> get inbound => const Stream.empty();

  @override
  Future<Result<void>> broadcast(DpipMeshPacket packet) async => const Ok(null);

  @override
  bool get isReady => false;
}
