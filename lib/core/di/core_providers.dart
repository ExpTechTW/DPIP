import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh_gateway.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/diagnostics/dump_uploader.dart';
import 'package:dpip/core/diagnostics/haste_api.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/map_reference_outline_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// App-wide, feature-agnostic providers: settings and shared services.
///
/// The first entry in the aggregate list in `app.dart`; feature modules add
/// their own after it.
List<SingleChildWidget> coreProviders(SharedDeps deps) => [
  ChangeNotifierProvider<RegionSelection>.value(value: deps.regions),
  ChangeNotifierProvider<ExperimentalSettings>.value(value: deps.experimental),
  ChangeNotifierProvider<RegionStore>.value(value: deps.regionStore),
  ChangeNotifierProvider<OnboardingStore>.value(value: deps.onboarding),
  ChangeNotifierProvider<LocaleController>.value(value: deps.locale),
  ChangeNotifierProvider<ThemeController>.value(value: deps.theme),
  ChangeNotifierProvider<ColorVisionController>.value(value: deps.colorVision),
  ChangeNotifierProvider<DisplaySettings>.value(value: deps.display),
  ChangeNotifierProvider<DefaultMapLayerController>.value(
    value: deps.defaultMapLayer,
  ),
  ChangeNotifierProvider<MapLayerOrderController>.value(
    value: deps.mapLayerOrder,
  ),
  ChangeNotifierProvider<MapLayerVisibilityController>.value(
    value: deps.mapLayerVisibility,
  ),
  ChangeNotifierProvider<MapReferenceOutlineController>.value(
    value: deps.mapReferenceOutline,
  ),
  Provider<SettingsStore>.value(value: deps.settings),
  Provider<AppDatabase>.value(value: deps.database),
  Provider<TleStore>.value(value: deps.tleStore),
  Provider<TownDirectory>.value(value: deps.townDirectory),
  Provider<Future<TownBoundaries>>.value(value: deps.townBoundaries),
  Provider<LocationService>.value(value: deps.locationService),
  ChangeNotifierProvider<LocationMonitor>.value(value: deps.locationMonitor),
  // Exposed for the developer page's health readout; the arming itself is
  // driven from the app shell, not from a page.
  Provider<BackgroundLocationService>.value(value: deps.backgroundLocation),
  // Watched by the More tab's badge and its 權限檢查 row.
  ChangeNotifierProvider<PermissionHealth>.value(value: deps.permissionHealth),
  Provider<RealtimeService>.value(value: deps.realtimeService),
  Provider<NotificationService>.value(value: deps.notificationService),
  Provider<SpeechService>(
    create: (_) => SystemSpeechService(),
    dispose: (_, speech) => speech.dispose(),
  ),
  Provider<MeshtasticService>.value(value: deps.meshtastic),
  ChangeNotifierProvider<MeshLink>.value(value: deps.meshLink),
  ChangeNotifierProvider<MeshAlerts>.value(value: deps.meshAlerts),
  ChangeNotifierProvider<MeshNodeStore>.value(value: deps.meshNodes),
  // The More tab's red dot follows it; the chat controller writes it.
  ChangeNotifierProvider<MeshUnread>.value(value: deps.meshUnread),
  Provider<MeshStore?>.value(value: deps.meshStore),
  Provider<DpipMeshGateway>.value(value: deps.meshGateway),
  Provider<ApiClient>.value(value: deps.apiClient),
  // Where a diagnostics dump goes. The contract rather than the paste service
  // behind it, so a page depends on "somewhere to send this" and not on Haste.
  Provider<DumpUploader>.value(value: HasteApi(deps.apiClient)),
  // Fed by ApiClient on every request outcome; read by the 伺服器狀態 page.
  ChangeNotifierProvider<EndpointHealthMonitor>.value(
    value: deps.endpointHealth,
  ),
  // Nullable — absent when the cache DB couldn't open; read by the Debug page.
  Provider<EtagCacheStore?>.value(value: deps.etagCache),
  Provider<NetworkUsageStore?>.value(value: deps.networkUsage),
  // MapLibre's tile authority — map surfaces warm through it. Nullable for the
  // same reason as the cache above.
  Provider<MapTileCache?>.value(value: deps.mapTileCache),
];
