import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';

/// The shared infrastructure every feature module builds on, assembled once in
/// `bootstrap()` and handed to each feature's `*Providers(deps)` function.
///
/// This is the composition seam: a feature turns these primitives into its own
/// providers (datasource → repository, realtime channels registered on
/// [realtimeService]), so adding a feature is one new `*Providers` function plus
/// one line in the aggregate list — never another named field on the app root.
class SharedDeps {
  const SharedDeps({
    required this.prefs,
    required this.apiClient,
    required this.regions,
    required this.experimental,
    required this.serverClock,
    required this.realtimeService,
    required this.notificationService,
    required this.townDirectory,
    required this.regionStore,
    required this.locationService,
    required this.deviceLocationReporter,
    required this.backgroundLocation,
    required this.locationMonitor,
    required this.onboarding,
    required this.locale,
    this.etagCache,
    this.networkUsage,
  });

  /// Persistence for feature-local settings.
  final Prefs prefs;

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

  /// First-launch onboarding completion (also provided) — gates the router and
  /// the app's permission requests.
  final OnboardingStore onboarding;

  /// The selected UI language override (also provided; drives `MaterialApp`).
  final LocaleController locale;

  /// On-disk ETag HTTP cache (also provided) — null if the cache DB couldn't be
  /// opened. Exposed for the Debug page's cache stats.
  final EtagCacheStore? etagCache;

  /// Persisted network-usage accounting (also provided) — shares the cache DB,
  /// so null when that is. Exposed for the Debug page's traffic stats.
  final NetworkUsageStore? networkUsage;
}
