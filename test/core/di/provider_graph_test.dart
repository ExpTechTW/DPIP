/// The feature `*Providers` functions are the composition root. If one of
/// them throws while assembling, the app never reaches its first frame, so
/// this builds the same graph a launch does — with no socket, no BLE radio,
/// and no store — and reads back every repository it registered.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/meshtastic/data/dpip_mesh_gateway_impl.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
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
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/features/bug_tracker/bug_tracker_counter.dart';
import 'package:dpip/features/bug_tracker/bug_tracker_providers.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:dpip/features/changelog/changelog_providers.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/disaster_map/disaster_map_providers.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/earthquake_providers.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/events_providers.dart';
import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/meshtastic/meshtastic_providers.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/notification_providers.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip/features/release_highlights/release_highlights_providers.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:dpip/features/sponsor/sponsor_providers.dart';
import 'package:dpip/features/status/domain/cloudflare_status_repository.dart';
import 'package:dpip/features/status/domain/server_status_repository.dart';
import 'package:dpip/features/status/status_providers.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/typhoon_providers.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 10, 6);
}

class _Time implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => const Ok(0);
}

class _Mesh implements MeshtasticService {
  final _connections = StreamController<MeshConnectionStatus>.broadcast();
  final _nodes = StreamController<MeshNode>.broadcast();
  final _messages = StreamController<MeshMessage>.broadcast();
  final _data = StreamController<MeshDataPacket>.broadcast();
  final _routes = StreamController<MeshRoute>.broadcast();
  final _stats = StreamController<MeshLocalStats>.broadcast();
  final _notices = StreamController<MeshNotice>.broadcast();
  final _traffic = StreamController<MeshTraffic>.broadcast();

  @override
  Future<Result<void>> initialize() async => const Ok(null);

  @override
  Stream<MeshDevice> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) => const Stream.empty();

  @override
  Future<Result<void>> connect(MeshDevice device) async => const Ok(null);

  @override
  Future<Result<void>> connectToId(String id) async => const Ok(null);

  @override
  Future<MeshLinkOwner> linkOwner(String deviceId) async => MeshLinkOwner.free;

  @override
  Future<Result<void>> disconnect() async => const Ok(null);

  @override
  Future<Result<void>> sendText(String text, {int channel = 0}) async =>
      const Ok(null);

  @override
  Stream<MeshConnectionStatus> get connectionStream => _connections.stream;

  @override
  Stream<MeshNode> get nodeStream => _nodes.stream;

  @override
  Stream<MeshMessage> get messageStream => _messages.stream;

  @override
  Stream<MeshDataPacket> get dataStream => _data.stream;

  @override
  Future<Result<int>> sendData({
    required int portnum,
    required List<int> payload,
    int channel = 0,
    int? destination,
    bool wantAck = false,
    bool wantResponse = false,
  }) async => const Err(NetworkFailure('unused'));

  @override
  Future<Result<int>> traceRoute(int nodeNum) async =>
      const Err(NetworkFailure('unused'));

  @override
  Stream<MeshRoute> get routeStream => _routes.stream;

  @override
  Stream<MeshLocalStats> get localStatsStream => _stats.stream;

  @override
  MeshLocalStats? get localStats => null;

  @override
  Stream<MeshNotice> get noticeStream => _notices.stream;

  @override
  MeshTraffic get traffic => const MeshTraffic();

  @override
  Stream<MeshTraffic> get trafficStream => _traffic.stream;

  @override
  MeshRadioInfo? get radioInfo => null;

  @override
  List<MeshChannel> get channels => const [];

  @override
  String? get region => null;

  @override
  int? get myNodeNum => null;

  @override
  Future<Result<int>> ensureChannel(MeshChannelSpec spec) async =>
      const Err(NetworkFailure('unused'));

  @override
  Future<Result<void>> applyRegion(String region) async => const Ok(null);

  @override
  Future<Result<bool>> setRadioTime(DateTime utc) async => const Ok(false);

  @override
  bool get isConnected => false;
}

SharedDeps _deps() {
  final settings = SettingsStore.inMemory();
  final regions = RegionSelection(settings);
  final mesh = _Mesh();
  final location = LocationService(
    const TownDirectory({}),
    isAvailable: () async => false,
    fix: () async => null,
    lastKnown: () async => null,
    status: () async => LocationStatus.denied,
  );
  final reporter = DeviceLocationReporter(
    positions: () => const Stream.empty(),
    onMoved: (_) async => false,
    settings: settings,
  );
  final notifications = NotificationService(settings);
  return SharedDeps(
    settings: settings,
    database: const AppDatabase(durable: null, cache: null),
    tleStore: const TleStore(null),
    apiClient: ApiClient(Dio(), regions),
    regions: regions,
    experimental: ExperimentalSettings(settings),
    serverClock: ServerClock(_Clock(), SystemElapsed(), _Time()),
    realtimeService: RealtimeService(
      ServerClock(_Clock(), SystemElapsed(), _Time()),
    ),
    notificationService: notifications,
    townDirectory: const TownDirectory({}),
    townBoundaries: Future<TownBoundaries>.value(
      TownBoundaries.fromDecoded({
        'A': {
          'b': [120.0, 24.0, 120.1, 24.1],
          'p': [
            [
              [120.0, 24.0, 120.1, 24.0, 120.1, 24.1, 120.0, 24.1, 120.0, 24.0],
            ],
          ],
        },
      }),
    ),
    regionStore: RegionStore(settings),
    locationService: location,
    deviceLocationReporter: reporter,
    backgroundLocation: BackgroundLocationService(
      platform: 0,
      version: '1',
      channel: const MethodChannel('test/provider_graph_bg'),
    ),
    locationMonitor: LocationMonitor(
      location: location,
      reporter: reporter,
      regions: RegionStore(settings),
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
    meshtastic: mesh,
    meshLink: MeshLink(mesh, settings),
    meshAlerts: MeshAlerts(mesh, settings, post: (_) async {}),
    meshNodes: MeshNodeStore(mesh, settings),
    meshUnread: MeshUnread(null),
    meshGateway: DpipMeshGatewayImpl(mesh, () => null),
    endpointHealth: EndpointHealthMonitor(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every feature module registers its repositories', (
    tester,
  ) async {
    final deps = _deps();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ...coreProviders(deps),
          ...changelogProviders(deps),
          ...eventsProviders(deps),
          ...typhoonProviders(deps),
          ...statusProviders(deps),
          ...disasterMapProviders(deps),
          ...bugTrackerProviders(deps),
          ...notificationProviders(deps),
          ...releaseHighlightsProviders(deps),
          ...weatherProviders(deps),
          ...earthquakeProviders(deps),
          ...homeProviders(),
          ...meshtasticProviders(deps),
          ...sponsorProviders(),
        ],
        child: const SizedBox.shrink(),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    expect(context.read<ChangelogRepository>(), isNotNull);
    expect(context.read<EventRepository>(), isNotNull);
    expect(context.read<MeteorTyphoonRepository>(), isNotNull);
    expect(context.read<ServerStatusRepository>(), isNotNull);
    expect(context.read<CloudflareStatusRepository>(), isNotNull);
    expect(context.read<DisasterMapRepository>(), isNotNull);
    expect(context.read<BugRepository>(), isNotNull);
    expect(context.read<BugTrackerCounter>(), isNotNull);
    expect(context.read<NotifyRepository>(), isNotNull);
    expect(context.read<ReleaseHighlightRepository>(), isNotNull);
    expect(context.read<RadarRepository>(), isNotNull);
    expect(context.read<QpesumsRepository>(), isNotNull);
    expect(context.read<SatelliteRepository>(), isNotNull);
    expect(
      context.read<Map<SatelliteChannel, SatelliteRepository>>().length,
      SatelliteChannel.values.length,
    );
    expect(
      context.read<Map<WindForecastModel, WindForecastRepository>>().length,
      WindForecastModel.values.length,
    );
    expect(context.read<MeteorWeatherRepository>(), isNotNull);
    expect(context.read<MeteorRainRepository>(), isNotNull);
    expect(context.read<MeteorLightningRepository>(), isNotNull);
    expect(context.read<RainHourTrendRepository>(), isNotNull);
    expect(context.read<EewRepository>(), isNotNull);
    expect(context.read<ReportRepository>(), isNotNull);
    // See earthquake_providers_test: awaiting an Isolate.run future that was
    // born in the fake-async zone deadlocks. Pause in real time, then read.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump();
    expect(await context.read<Future<SeismicTravelTimeTable>>(), isNotNull);
    expect(await context.read<Future<RtsBoxGrid>>(), isNotNull);
    expect(context.read<HomeWeatherController>(), isNotNull);
    expect(context.read<HomeActiveEventsController>(), isNotNull);
    expect(context.read<MeshChatController>(), isNotNull);
    expect(context.read<SponsorRepository>(), isNotNull);
    expect(deps.mapTileWarmer(), isNotNull);

    final eew = context.read<EewRealtimeController>();
    final rts = context.read<RtsRealtimeController>();
    await tester.pumpWidget(const SizedBox.shrink());
    eew.dispose();
    rts.dispose();
  });
}
