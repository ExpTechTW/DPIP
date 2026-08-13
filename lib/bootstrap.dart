import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:dpip/app/app.dart';
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_api.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/ntp_time_source.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/features/changelog/changelog_providers.dart';
import 'package:dpip/features/disaster_map/disaster_map_providers.dart';
import 'package:dpip/features/earthquake/earthquake_providers.dart';
import 'package:dpip/features/events/events_providers.dart';
import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/notification/notification_providers.dart';
import 'package:dpip/features/sponsor/sponsor_providers.dart';
import 'package:dpip/features/typhoon/typhoon_providers.dart';
import 'package:dpip/features/weather/weather_providers.dart';
import 'package:dpip/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Initializes platform services and launches the app.
///
/// Assembles the shared infrastructure ([SharedDeps]) each feature builds on,
/// then lets every feature contribute its own providers — so this stays a fixed
/// spine plus a one-line-per-feature aggregate, not a god-function.
///
/// Firebase is initialized with **explicit** [DefaultFirebaseOptions] rather
/// than the native `GoogleService-Info.plist` / `google-services.json`, so init
/// doesn't depend on the iOS plist being added to the Xcode target's bundle
/// resources. Firebase init and notification setup are best-effort: a failure is
/// logged and the app still launches (push is simply unavailable).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  Log.installErrorHandlers();
  Log.info('DPIP starting up');

  // Kick off every independent resource load in parallel — Firebase, prefs,
  // the SQLite cache, the town directory and package info never touch each
  // other, so the serial chain would simply add their latencies. Each is
  // awaited individually below so failures keep their per-resource handling.
  unawaited(_initFirebase());
  final prefsFuture = SharedPreferences.getInstance();
  final cacheFuture = _openCache();
  final townDirectoryFuture = TownDirectory.load();
  final appVersionFuture = PackageInfo.fromPlatform().then((p) => p.version);

  final prefs = Prefs(await prefsFuture);
  final regions = RegionSelection(prefs);
  final experimental = ExperimentalSettings(prefs);
  final onboarding = OnboardingStore(prefs);
  final locale = LocaleController(prefs);
  final theme = ThemeController(prefs);
  final defaultMapLayer = DefaultMapLayerController(prefs);
  final mapLayerOrder = MapLayerOrderController(prefs);
  final cache = await cacheFuture;
  final dio = createDio(etagCache: cache?.etag, usage: cache?.usage);
  final apiClient = ApiClient(dio, regions);
  // MapLibre asks Dart for every ExpTech tile before it asks the network, so
  // this must be bound before the first map is built.
  final mapTileCache = cache == null
      ? null
      : MapTileCache(cache.etag, usage: cache.usage);
  await mapTileCache?.install();
  // Turn off the OS-level disk HTTP cache (iOS NSURLCache) and drop its
  // residue: every cached byte now lives in the app's own SQLite, so a second
  // disk copy is pure overhead. Fire-and-forget: it never delays launch.
  unawaited(const StorageScanner().configure());
  // Debug runs leave JIT kernel snapshots (main.dart.dill / .swap.dill) in
  // tmp — a debug → release switch on a dev device would otherwise carry
  // hundreds of MB of them around. tmp is scratch space, so wiping it on a
  // release launch is always safe (release never has anything there of its
  // own); the debug → release direction is the only one that matters.
  if (kReleaseMode) {
    unawaited(const StorageScanner().clearTmp());
  }

  // Calibrated clock: real SNTP (flutter_ntp, ExpTech primary / Apple backup)
  // anchored to a monotonic clock, exposed globally via `AppTime` and resynced
  // every 60s by the realtime service. The initial sync is fire-and-forget so it
  // never delays launch (until it lands, the clock reads device time).
  final serverClock = ServerClock(
    const SystemClock(),
    SystemElapsed(),
    NtpTimeSource(),
  );
  AppTime.install(serverClock);
  serverClock.sync().ignore();
  final realtimeService = RealtimeService(serverClock);

  // Push: best-effort and off the first frame — a missing push environment or
  // slow FCM registration must never gate launch. The token is only consumed
  // by device-location reports, which fire after GPS permission, so it lands
  // long before it is needed.
  final notificationService = NotificationService(prefs);
  unawaited(_initNotifications(notificationService));

  // Location: the township directory (centroids) backs Home region labels and
  // the nearest-centroid fallback; the boundary polygons back exact
  // point-in-polygon GPS resolution and decode in a background isolate (see
  // `TownBoundaries.load`) so they never delay launch or the first frames.
  final townDirectory = await townDirectoryFuture;
  final townBoundaries = TownBoundaries.load();
  final regionStore = RegionStore(prefs);
  final locationService = LocationService(
    townDirectory,
    boundaries: townBoundaries,
  );

  // Distance-triggered device-location report: on each meaningful move, POST the
  // coordinates for push targeting (platform + push token + app version). Started
  // after the first frame once GPS permission is granted; a null token (not yet
  // registered) simply skips — it self-heals on the next move.
  final locationApi = LocationApi(apiClient);
  final appVersion = await appVersionFuture;
  final reportPlatform = Platform.isIOS ? 1 : 0;
  final deviceLocationReporter = DeviceLocationReporter(
    positions: () => locationService.positionStream(),
    prefs: prefs,
    onMoved: (fix) async {
      final token = notificationService.token;
      if (token == null) return false;
      await locationApi.updateDeviceLocation(
        platform: reportPlatform,
        token: token,
        version: appVersion,
        lat: fix.lat,
        lng: fix.lng,
      );
      return true;
    },
  );
  // Terminated/background counterpart: native reports on significant moves.
  final backgroundLocation = BackgroundLocationService(
    platform: reportPlatform,
    version: appVersion,
  );

  // Watches the OS location toggle / permission and recovers reporting after a
  // mid-session change; drives the "fix it" banner.
  final locationMonitor = LocationMonitor(
    location: locationService,
    reporter: deviceLocationReporter,
    regions: regionStore,
  );

  final deps = SharedDeps(
    prefs: prefs,
    apiClient: apiClient,
    regions: regions,
    experimental: experimental,
    serverClock: serverClock,
    realtimeService: realtimeService,
    notificationService: notificationService,
    townDirectory: townDirectory,
    townBoundaries: townBoundaries,
    regionStore: regionStore,
    locationService: locationService,
    deviceLocationReporter: deviceLocationReporter,
    backgroundLocation: backgroundLocation,
    locationMonitor: locationMonitor,
    onboarding: onboarding,
    locale: locale,
    theme: theme,
    defaultMapLayer: defaultMapLayer,
    mapLayerOrder: mapLayerOrder,
    etagCache: cache?.etag,
    networkUsage: cache?.usage,
    mapTileCache: mapTileCache,
  );

  // Each feature turns [deps] into its providers (and registers its realtime
  // channels). Adding a feature = one line here + its `*Providers` function.
  Log.info('bootstrap ready in ${Log.sinceStart.elapsedMilliseconds} ms');
  runApp(
    DpipApp(
      deps: deps,
      providers: [
        ...coreProviders(deps),
        ...earthquakeProviders(deps),
        ...weatherProviders(deps),
        ...disasterMapProviders(deps),
        ...typhoonProviders(deps),
        ...eventsProviders(deps),
        ...changelogProviders(deps),
        ...notificationProviders(deps),
        ...sponsorProviders(),
        ...homeProviders(),
      ],
    ),
  );
}

/// Opens the SQLite ETag cache (and the network-usage tables it shares the
/// database with) under the platform cache directory. Best-effort: if the
/// database can't be opened the app runs without HTTP caching / accounting rather
/// than failing to launch. The usage tables are created with `IF NOT EXISTS` on
/// every open, so they're added to a pre-existing cache DB without a version bump.
Future<({EtagCacheStore etag, NetworkUsageStore usage})?> _openCache() async {
  try {
    final base = await getApplicationCacheDirectory();
    final db = await openDatabase(
      '${base.path}/http_etag_cache.db',
      version: 2,
      onCreate: (db, _) => EtagCacheStore.createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 was a gzip+json+base64 envelope — drop and rebuild for the fast
        // columnar schema (one-time cold miss on upgrade).
        if (oldVersion < 2) await EtagCacheStore.migrateToV2(db);
      },
    );
    await NetworkUsageStore.createSchema(db);
    await EtagCacheStore.configureConnection(db);
    final usage = NetworkUsageStore(db);
    return (etag: EtagCacheStore(db, usage: usage), usage: usage);
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'ETag cache unavailable');
    return null;
  }
}

/// Initializes Firebase in parallel with the rest of bootstrap. Hot-restart
/// safe: the native Firebase app survives a Dart hot restart, so
/// re-initializing then throws — only initialize when no default app exists.
/// Best-effort: a failure is logged and the app still launches.
Future<void> _initFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    Log.info('Firebase initialized');
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'Firebase init failed (push unavailable)');
  }
}

/// Initializes push after the first frame — never gate launch on FCM.
Future<void> _initNotifications(NotificationService service) async {
  try {
    await service.init();
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'Notification init skipped');
  }
}
