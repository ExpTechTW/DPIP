import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh_gateway.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';

/// The shared infrastructure every feature module builds on, assembled once in
/// `bootstrap()` and handed to each feature's `*Providers(deps)` function.
///
/// This is the composition seam: a feature turns these primitives into its own
/// providers (datasource → repository, realtime channels registered on
/// [realtimeService]), so adding a feature is one new `*Providers` function plus
/// one line in the aggregate list — never another named field on the app root.
class SharedDeps {
  const SharedDeps({
    required this.settings,
    required this.database,
    required this.tleStore,
    required this.apiClient,
    required this.regions,
    required this.experimental,
    required this.serverClock,
    required this.realtimeService,
    required this.notificationService,
    required this.townDirectory,
    required this.townBoundaries,
    required this.regionStore,
    required this.locationService,
    required this.deviceLocationReporter,
    required this.backgroundLocation,
    required this.locationMonitor,
    required this.permissionHealth,
    required this.onboarding,
    required this.locale,
    required this.theme,
    required this.colorVision,
    required this.display,
    required this.defaultMapLayer,
    required this.mapLayerOrder,
    required this.mapLayerVisibility,
    required this.meshtastic,
    required this.meshLink,
    required this.meshAlerts,
    required this.meshNodes,
    required this.meshUnread,
    this.meshStore,
    required this.meshGateway,
    required this.endpointHealth,
    this.etagCache,
    this.networkUsage,
    this.mapTileCache,
  });

  /// Persistence for feature-local settings.
  final SettingsStore settings;

  /// Region-aware HTTP surface for datasources.
  final ApiClient apiClient;

  /// App-wide region selection (also a provided setting).
  final RegionSelection regions;

  /// App-wide experimental settings (also provided).
  final ExperimentalSettings experimental;

  /// Corrected clock for realtime channels' freshness.
  final ServerClock serverClock;

  /// Realtime spine — a feature registers its channels here.
  final RealtimeService realtimeService;

  /// Push transport + channels (also provided).
  final NotificationService notificationService;

  /// Taiwan township directory (code → town), for GPS resolution + region
  /// labels. Loaded once at bootstrap.
  final TownDirectory townDirectory;

  /// Township boundary polygons (loads in the background) — GPS→township PIP and
  /// the selected-region outline on the home map.
  final Future<TownBoundaries> townBoundaries;

  /// App-wide Home region selection (also provided).
  final RegionStore regionStore;

  /// GPS → current township resolver (geolocator).
  final LocationService locationService;

  /// Distance-triggered device-location reporter (foreground). Started by the
  /// service host after GPS permission is granted.
  final DeviceLocationReporter deviceLocationReporter;

  /// Native background device-location reporting (terminated/background). The
  /// terminated-state counterpart to [deviceLocationReporter].
  final BackgroundLocationService backgroundLocation;

  /// App-wide location health monitor (also provided) — status + recovery when
  /// GPS / permission changes mid-session.
  final LocationMonitor locationMonitor;

  /// One app-wide answer to whether alerts can still reach the user.
  final PermissionHealth permissionHealth;

  /// First-launch onboarding completion (also provided) — gates the router and
  /// the app's permission requests.
  final OnboardingStore onboarding;

  /// The selected UI language override (also provided; drives `MaterialApp`).
  final LocaleController locale;

  /// The selected theme mode (also provided; drives `MaterialApp.themeMode`).
  final ThemeController theme;

  /// The colour-vision correction setting.
  final ColorVisionController colorVision;

  /// Text size / weight / contrast.
  final DisplaySettings display;

  /// Default Map-tab overlay (also provided; drives nav chrome + map open).
  final DefaultMapLayerController defaultMapLayer;

  /// User-customised map layer-picker order (also provided).
  final MapLayerOrderController mapLayerOrder;

  /// The map layers the user hid (also provided).
  final MapLayerVisibilityController mapLayerVisibility;

  /// LoRa mesh (Meshtastic) over BLE — off-grid emergency messaging.
  final MeshtasticService meshtastic;

  /// Keeps the chosen radio attached across pages, drops and app restarts, and
  /// provisions it for DPIP.
  final MeshLink meshLink;

  /// Local notifications for mesh traffic (no push involved).
  final MeshAlerts meshAlerts;

  /// The last known mesh node table — persisted, so the map and the node list
  /// have something to show with no radio attached.
  final MeshNodeStore meshNodes;

  /// Unread mesh conversations — read by the chat page and the More tab's dot.
  final MeshUnread meshUnread;

  /// The mesh conversation log and utilization history (SQLite). Null when
  /// the database couldn't be opened — the log is then session-only.
  final MeshStore? meshStore;

  /// Both SQLite files. Held so a settings screen can clear the cache without
  /// any store handing out a handle to the durable one.
  final AppDatabase database;

  /// Orbital elements — its own table, its own store.
  final TleStore tleStore;

  /// DPIP disaster payloads in and out of the mesh — the seam feeds use.
  final DpipMeshGateway meshGateway;

  /// Client-side health of the multi-active endpoints — fed by [apiClient],
  /// rendered by the More → 伺服器狀態 screen.
  final EndpointHealthMonitor endpointHealth;

  /// On-disk ETag HTTP cache (also provided) — null if the cache DB couldn't be
  /// opened. Exposed for the Debug page's cache stats.
  final EtagCacheStore? etagCache;

  /// Persisted network-usage accounting (also provided) — shares the cache DB,
  /// so null when that is. Exposed for the Debug page's traffic stats.
  final NetworkUsageStore? networkUsage;

  /// MapLibre's tile authority — backed by [etagCache], so null when that is.
  /// Map layers warm frames through it before revealing them.
  final MapTileCache? mapTileCache;

  /// A fresh warm scheduler over [mapTileCache].
  ///
  /// One per consumer, never shared: a warmer's [MapTileWarmer.cancel] abandons
  /// *its* schedule, so sharing one would let a layer switch silently drop a
  /// different layer's warm.
  MapTileWarmer mapTileWarmer() => MapTileWarmer(mapTileCache);
}
