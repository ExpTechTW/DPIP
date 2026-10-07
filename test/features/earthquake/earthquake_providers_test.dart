/// The earthquake composition root: one function turns [SharedDeps] into the
/// report catalogue, the EEW/RTS controllers, and the two live channels.
///
/// Those channels are registered eagerly — `RealtimeService.startAll` runs
/// after the first frame and can only start what is already on the service.
/// The demo branches are compile-time flags and are off in the test binary, so
/// this pins the production wiring: real SSE sources, not the synthetic feeds.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/build/demo_flags.dart';
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
import 'package:dpip/core/platform/widget_location_catalog_coordinator.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/core/settings/eew_spoken_announcement_settings.dart';
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
import 'package:dpip/features/earthquake/data/ml_intensity_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/rts_live_demand.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/earthquake/earthquake_providers.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 2026-03-10 14:00 Taipei. Nothing in this wiring reads the clock until a
/// channel starts, and these tests never start one.
final _now = DateTime.utc(2026, 3, 10, 6);

class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

class _FixedSource implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => Ok(_now.millisecondsSinceEpoch);
}

/// One township, so the boundary grid has a finite extent. An empty table
/// leaves the index dividing by infinity.
TownBoundaries _oneTown() => TownBoundaries.fromDecoded({
  'A': {
    'b': [120.0, 24.0, 120.1, 24.1],
    'p': [
      [
        [120.0, 24.0, 120.1, 24.0, 120.1, 24.1, 120.0, 24.1, 120.0, 24.0],
      ],
    ],
  },
});

/// A radio that is never started. The providers only need an instance so
/// [SharedDeps] can be built; they do not scan, connect, or subscribe.
class _IdleMesh implements MeshtasticService {
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

  void close() {
    _connections.close();
    _nodes.close();
    _messages.close();
    _data.close();
    _routes.close();
    _stats.close();
    _notices.close();
    _traffic.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo flags are off, so the live sources are the ones constructed', () {
    expect(kMonitorDemoEnabled, isFalse);
    expect(kStartupEewDemoEnabled, isFalse);
  });

  testWidgets('registers both feeds and publishes every earthquake provider', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory();
    final regions = RegionSelection(settings);
    final clock = ServerClock(_FixedClock(), SystemElapsed(), _FixedSource());
    await clock.sync();
    AppTime.install(clock);
    final realtime = RealtimeService(clock);
    final towns = const TownDirectory({});
    final location = LocationService(
      towns,
      isAvailable: () async => false,
      fix: () async => null,
      lastKnown: () async => null,
      status: () async => LocationStatus.denied,
    );
    final reporter = DeviceLocationReporter(
      positions: () => const Stream.empty(),
      onMoved: (_) async => false,
      settings: settings,
      now: () => _now,
    );
    final regionStore = RegionStore(settings);
    final notifications = NotificationService(settings);
    final mesh = _IdleMesh();
    final experimental = ExperimentalSettings(settings);
    final locale = LocaleController(settings);
    final theme = ThemeController(settings);
    final colorVision = ColorVisionController(settings);
    final display = DisplaySettings(settings);
    final defaultMapLayer = DefaultMapLayerController(settings);
    final mapLayerOrder = MapLayerOrderController(settings);
    final mapLayerVisibility = MapLayerVisibilityController(settings);
    final mapReferenceOutline = MapReferenceOutlineController(settings);
    final onboarding = OnboardingStore(settings);
    final locationMonitor = LocationMonitor(
      location: location,
      reporter: reporter,
      regions: regionStore,
    );
    final permissionHealth = PermissionHealth(
      location: location,
      notifications: notifications,
    );
    final meshLink = MeshLink(mesh, settings);
    final meshAlerts = MeshAlerts(mesh, settings, now: () => _now);
    final meshNodes = MeshNodeStore(mesh, settings, now: () => _now);
    final meshUnread = MeshUnread(null);
    final endpointHealth = EndpointHealthMonitor();
    final notifiers = <ChangeNotifier>[
      regions,
      experimental,
      locale,
      theme,
      colorVision,
      display,
      defaultMapLayer,
      mapLayerOrder,
      mapLayerVisibility,
      mapReferenceOutline,
      onboarding,
      regionStore,
      locationMonitor,
      permissionHealth,
      meshLink,
      meshAlerts,
      meshNodes,
      meshUnread,
      endpointHealth,
    ];

    final deps = SharedDeps(
      settings: settings,
      database: const AppDatabase(durable: null, cache: null),
      tleStore: const TleStore(null),
      apiClient: ApiClient(Dio(), regions, endpointHealth),
      regions: regions,
      experimental: experimental,
      serverClock: clock,
      realtimeService: realtime,
      notificationService: notifications,
      townDirectory: towns,
      townBoundaries: Future<TownBoundaries>.value(_oneTown()),
      regionStore: regionStore,
      widgetLocationCatalogCoordinator: WidgetLocationCatalogCoordinator(
        regionStore,
        towns,
        IosWidgetSnapshotWriter(isSupportedPlatform: false),
      ),
      locationService: location,
      deviceLocationReporter: reporter,
      backgroundLocation: BackgroundLocationService(
        platform: 0,
        version: 'test',
        channel: const MethodChannel('test/earthquake_providers_bg'),
      ),
      locationMonitor: locationMonitor,
      permissionHealth: permissionHealth,
      onboarding: onboarding,
      locale: locale,
      theme: theme,
      colorVision: colorVision,
      display: display,
      defaultMapLayer: defaultMapLayer,
      mapLayerOrder: mapLayerOrder,
      mapLayerVisibility: mapLayerVisibility,
      mapReferenceOutline: mapReferenceOutline,
      meshtastic: mesh,
      meshLink: meshLink,
      meshAlerts: meshAlerts,
      meshNodes: meshNodes,
      meshUnread: meshUnread,
      meshGateway: DpipMeshGatewayImpl(mesh, () => null),
      endpointHealth: endpointHealth,
    );

    final widgets = earthquakeProviders(deps);
    expect(widgets, hasLength(13));

    await tester.pumpWidget(
      MultiProvider(providers: widgets, child: const SizedBox.shrink()),
    );
    final context = tester.element(find.byType(SizedBox));

    final eew = context.read<EewRealtimeController>();
    final rts = context.read<RtsRealtimeController>();
    final cwaOnly = context.read<EewCwaOnlySettings>();
    final spoken = context.read<EewSpokenAnnouncementSettings>();
    expect(context.read<EewRepository>(), isA<EewRepository>());
    expect(context.read<ReportRepository>(), isA<ReportRepository>());
    expect(cwaOnly.enabled, isTrue);
    expect(spoken.enabled, isFalse);
    expect(context.read<RealtimeNotifier<List<Eew>>>(), same(eew));
    expect(context.read<RealtimeNotifier<Rts>>(), same(rts));
    expect(context.read<TremStationRepository>(), isA<TremStationRepository>());
    expect(context.read<RtsLiveDemand>(), isA<RtsLiveDemand>());
    expect(context.read<MlIntensityEstimator>(), isA<MlIntensityService>());

    // The travel-time table is decoded with Isolate.run, and that future was
    // created in this test's fake-async zone. Awaiting it directly deadlocks:
    // the reply is queued on the zone that is paused for the await. A real
    // pause lets the worker finish; the reply is applied when the zone resumes.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump();
    final table = await context.read<Future<SeismicTravelTimeTable>>();
    final grid = await context.read<Future<RtsBoxGrid>>();
    expect(table.rowsByDepth, isNotEmpty);
    expect(grid.rings, isNotEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    eew.dispose();
    rts.dispose();
    cwaOnly.dispose();
    spoken.dispose();
    realtime.dispose();
    for (final notifier in notifiers) {
      notifier.dispose();
    }
    mesh.close();
  });
}
