/// `DpipApp` wires the first frame: permissions, location, and a notification
/// tap. The test supplies every dependency in memory and never calls
/// `bootstrap()`, which opens databases and Firebase.
library;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:dpip/app/app.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/data/dpip_mesh_gateway_impl.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/platform/widget_location_catalog_coordinator.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
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
import 'package:dpip/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:provider/provider.dart';

import '../core/meshtastic/fake_mesh_service.dart';

const _awesome = MethodChannel('awesome_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Geo geo;
  late GeolocatorPlatform previousGeo;

  setUp(() {
    geo = _Geo();
    previousGeo = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = geo;
    AwesomeNotificationsPlatform.operatingSystem = 'ios';
    AwesomeNotificationsPlatform.resetInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_awesome, (call) async {
          return switch (call.method) {
            'isNotificationAllowed' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    GeolocatorPlatform.instance = previousGeo;
    NotificationTaps.onTap = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_awesome, null);
    AwesomeNotificationsPlatform.operatingSystem = 'macos';
    AwesomeNotificationsPlatform.resetInstance();
  });

  testWidgets('launch waits for onboarding, then arms location', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory();
    await settings.setString(SettingKeys.locale, 'en');
    final deps = _deps(settings);
    final handoff = MapCameraHandoff();

    await tester.pumpWidget(
      DpipApp(
        deps: deps,
        providers: [
          ...coreProviders(deps),
          ChangeNotifierProvider<MapCameraHandoff>.value(value: handoff),
        ],
      ),
    );
    await tester.pump();
    expect(find.byType(OnboardingPage), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    NotificationTaps.onTap?.call(
      const NotificationTap(channelKey: 'eew-important-v2'),
    );
    await tester.pump();
    expect(handoff.hasPending, isTrue);
    expect(find.byType(OnboardingPage), findsOneWidget);

    geo.permission = LocationPermission.whileInUse;
    await deps.onboarding.complete();
    await tester.pump();
    await tester.pump();

    await settings.setString(SettingKeys.pushToken, 'token-1');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    geo.permission = LocationPermission.always;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

SharedDeps _deps(SettingsStore settings) {
  final regions = RegionSelection(settings);
  final mesh = FakeMeshService();
  const townDirectory = TownDirectory({});
  final regionStore = RegionStore(settings);
  final location = LocationService(
    townDirectory,
    isAvailable: () async => false,
    fix: () async => null,
    lastKnown: () async => null,
    status: () async => LocationStatus.denied,
  );
  final reporter = DeviceLocationReporter(
    positions: () => const Stream.empty(),
    onMoved: (_) async => false,
    settings: settings,
    now: () => DateTime.utc(2026, 1, 15),
  );
  final clock = ServerClock(_Clock(), _Elapsed(), _Time());
  final notifications = NotificationService(settings);
  return SharedDeps(
    settings: settings,
    database: const AppDatabase(durable: null, cache: null),
    tleStore: const TleStore(null),
    apiClient: ApiClient(Dio(), regions),
    regions: regions,
    experimental: ExperimentalSettings(settings),
    serverClock: clock,
    realtimeService: RealtimeService(clock, ticker: _Ticker()),
    notificationService: notifications,
    townDirectory: townDirectory,
    townBoundaries: Future<TownBoundaries>.value(_boundaries()),
    regionStore: regionStore,
    widgetLocationCatalogCoordinator: WidgetLocationCatalogCoordinator(
      regionStore,
      townDirectory,
      IosWidgetSnapshotWriter(isSupportedPlatform: false),
    ),
    locationService: location,
    deviceLocationReporter: reporter,
    backgroundLocation: BackgroundLocationService(
      platform: 0,
      version: '1',
      channel: const MethodChannel('test/app_bg'),
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

class _Geo extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Stream<ServiceStatus> getServiceStatusStream() => const Stream.empty();
}

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
