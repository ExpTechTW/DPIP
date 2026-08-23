import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;

import 'package:dpip/app/app.dart';
import 'package:dpip/app/router/app_router.dart' show onboardingRefresh;
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_api.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/meshtastic/data/dpip_mesh_gateway_impl.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/data/meshtastic_client_impl.dart';
import 'package:dpip/core/meshtastic/mesh_metrics_recorder.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
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
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/core/storage/retention.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/features/changelog/changelog_providers.dart';
import 'package:dpip/features/release_highlights/release_highlights_providers.dart';
import 'package:dpip/features/disaster_map/disaster_map_providers.dart';
import 'package:dpip/features/earthquake/earthquake_providers.dart';
import 'package:dpip/features/events/events_providers.dart';
import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/meshtastic/meshtastic_providers.dart';
import 'package:dpip/features/notification/notification_providers.dart';
import 'package:dpip/features/sponsor/sponsor_providers.dart';
import 'package:dpip/features/status/status_providers.dart';
import 'package:dpip/features/typhoon/typhoon_providers.dart';
import 'package:dpip/features/weather/weather_providers.dart';
import 'package:dpip/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntry, LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart';

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
/// The licence for the bundled weather icon font (`assets/fonts/`).
Stream<LicenseEntry> _weatherIconLicense() async* {
  yield const LicenseEntryWithLineBreaks(
    ['DpipWeatherIcons (Material Symbols)'],
    'Copyright Google LLC\n'
    '\n'
    'Licensed under the Apache License, Version 2.0 (the "License"); you may '
    'not use this file except in compliance with the License. You may obtain '
    'a copy of the License at\n'
    '\n'
    '    http://www.apache.org/licenses/LICENSE-2.0\n'
    '\n'
    'Unless required by applicable law or agreed to in writing, software '
    'distributed under the License is distributed on an "AS IS" BASIS, '
    'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. '
    'See the License for the specific language governing permissions and '
    'limitations under the License.\n'
    '\n'
    'Source: https://github.com/google/material-design-icons',
  );
}

/// Set by `tool/run.sh` and `tool/run.ps1`, which is how the app is started.
///
/// Any value counts, deliberately. `bool.fromEnvironment` reads only the exact
/// string `true` and answers `false` to everything else — including `1`, which
/// is what the script passed at first, so the guard fired on the very launch
/// that had obeyed it.
const bool _launchedByTool = String.fromEnvironment('DPIP_RUN_SH') != '';

/// Refuses to start when it was not, and says what to run instead.
///
/// Debug only — a release build is produced by `flutter build` in CI, which
/// never sets this and must never be blocked by it.
///
/// A refusal rather than a warning, because both alternatives are wrong
/// *invisibly*. A bare `flutter run` resolves whatever SDK the shell's PATH
/// cached, and `mise activate` does not refresh that when mise.toml changes —
/// so the app builds against a different SDK than CI with nothing to show for
/// it. `mise exec -- flutter run` fixes the SDK and still leaves the log
/// unreadable, because colour has to be added by the pipe (see
/// tool/internal/colorize_logs.sh). A warning written into a log nobody can
/// read yet is not much of a warning.
///
/// The instructions name every shell: this runs on the *device*, so it cannot
/// see which machine launched it.
void _refuseUnlessLaunchedByTool() {
  if (!kDebugMode || _launchedByTool) return;
  const message =
      'DPIP must be started through its run script.\n'
      '\n'
      '  macOS / Linux    tool/run.sh -d <device>\n'
      '  Windows          tool\\run.ps1 -d <device>\n'
      '                   (or, for a coloured log, Git Bash / WSL:\n'
      '                    bash tool/run.sh -d <device>)\n'
      '\n'
      '`flutter run` and `mise exec -- flutter run` both start it, and both\n'
      "are wrong in ways nothing tells you about: the first builds against\n"
      "whatever SDK your shell's PATH cached rather than the one mise.toml\n"
      'pins, and neither colours the log — that is added by the pipe the\n'
      'script provides, not by the app.\n'
      '\n'
      'See AGENTS.md -> Running.';
  // Through `Log` like everything else — it reaches the console as one plain
  // line per entry, which is exactly the output being asked for here.
  Log.error(message);
  exit(1);
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  Log.installErrorHandlers();
  Log.info('DPIP starting up');
  _refuseUnlessLaunchedByTool();

  // The bundled weather glyphs are Material Symbols (Apache-2.0). Registering
  // the licence puts it in the app's own 開放原始碼授權 page (More → licences),
  // which is where a bundled third-party asset has to be declared — Flutter
  // only collects licences for *packages* by itself.
  LicenseRegistry.addLicense(_weatherIconLicense);

  // Kick off every independent resource load in parallel — Firebase, settings,
  // the SQLite cache, the town directory and package info never touch each
  // other, so the serial chain would simply add their latencies. Each is
  // awaited individually below so failures keep their per-resource handling.
  unawaited(_initFirebase());
  final durableFuture = _openDurable();
  final cacheFuture = _openCache();
  final townDirectoryFuture = TownDirectory.load();
  // Boundaries too: independent of everything, and its isolate decode is the
  // longest single asset load — starting it here overlaps it with the DB opens.
  final townBoundaries = TownBoundaries.load();
  // The label a human reads, and the ordinal that orders — see [AppBuild].
  // Stamped in by CI; falls back to the platform's own values locally.
  final appVersionFuture = AppBuild.ensureLoaded().then((_) => AppBuild.label);

  final durable = await durableFuture;
  final settings = await SettingsStore.open(durable);
  Log.info(
    'settings ready durable=${durable != null} keys=${settings.keys.length} '
    'onboarding=${settings.getBool(SettingKeys.onboardingComplete)}',
  );
  final onboarding = OnboardingStore(settings);
  // A launch that could not open the database must not spend the whole session
  // pretending to be a first run: keep trying, and when the file opens, hand
  // it to the store so this session's writes persist — then re-announce
  // onboarding so a redirect held on the welcome page re-runs.
  if (durable == null) unawaited(_recoverDurable(settings, onboarding));
  // Persist the log as early as the database allows: everything after this
  // point survives a crash or a background kill, which is exactly the window
  // the in-memory history used to lose.
  final logStore = durable == null ? null : LogStore(durable);
  if (logStore != null) Log.persistTo(logStore);
  final regions = RegionSelection(settings);
  final experimental = ExperimentalSettings(settings);
  final locale = LocaleController(settings);
  final theme = ThemeController(settings);
  // Constructed before the first frame: it installs the saved setting into
  // AppColorVision, so nothing paints in standard colours and then corrects.
  final colorVision = ColorVisionController(settings);
  final display = DisplaySettings(settings);
  final defaultMapLayer = DefaultMapLayerController(settings);
  final mapLayerOrder = MapLayerOrderController(settings);
  final cache = await cacheFuture;
  final dio = createDio(etagCache: cache?.etag, usage: cache?.usage);
  final endpointHealth = EndpointHealthMonitor();
  final apiClient = ApiClient(dio, regions, endpointHealth);
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
  final notificationService = NotificationService(settings);
  unawaited(_initNotifications(notificationService));

  // Location: the township directory (centroids) backs Home region labels and
  // the nearest-centroid fallback; the boundary polygons back exact
  // point-in-polygon GPS resolution and decode in a background isolate (see
  // `TownBoundaries.load`) so they never delay launch or the first frames.
  final townDirectory = await townDirectoryFuture;
  final regionStore = RegionStore(settings);
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
    settings: settings,
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
  // Replay whatever the native side recorded while there was no Dart to hear
  // it. A background wake runs with no Flutter isolate at all, so nothing that
  // path does can reach `Log` as it happens — which is why "it never reports"
  // came with no evidence of *where* it stopped. Native keeps a small ring of
  // breadcrumbs across process deaths; this is where they enter the log the
  // user can actually send. Unawaited: a diagnostic must never delay a launch.
  unawaited(backgroundLocation.drainBreadcrumbs());

  // Watches the OS location toggle / permission and recovers reporting after a
  // mid-session change; drives the "fix it" banner.
  // One shared read of "can an alert still reach this user", so the shell badge
  // and the permission page agree and neither polls the OS on a rebuild.
  final permissionHealth = PermissionHealth(
    location: locationService,
    notifications: notificationService,
  );

  final locationMonitor = LocationMonitor(
    location: locationService,
    reporter: deviceLocationReporter,
    regions: regionStore,
  );

  // The mesh link is app-wide, not page-owned: a radio stays attached (and
  // keeps reconnecting) for the whole app session, because it is a reception
  // path for disaster information. `start()` picks a saved radio back up.
  final meshtastic = MeshtasticClientImpl();
  final meshLink = MeshLink(meshtastic, settings);
  // Mesh data lives in the durable database, deliberately **not** the HTTP
  // cache one: that lives in the platform cache directory, which the OS may
  // purge, and a conversation is the one thing here that cannot be fetched
  // again.
  final meshStore = durable == null ? null : MeshStore(durable);
  final meshAlerts = MeshAlerts(meshtastic, settings, store: meshStore);
  final meshNodes = MeshNodeStore(meshtastic, settings, store: meshStore);
  final meshUnread = MeshUnread(meshStore);
  // Retention for every table, on one schedule: now, then hourly. No store
  // prunes on its own timing any more — see [RetentionService] for why an app
  // that is left running needs a clock rather than a bootstrap.
  RetentionService(
    mesh: meshStore,
    logs: logStore,
    usage: cache?.usage,
    httpCache: cache?.etag,
  ).start();

  final deps = SharedDeps(
    settings: settings,
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
    permissionHealth: permissionHealth,
    onboarding: onboarding,
    locale: locale,
    theme: theme,
    colorVision: colorVision,
    display: display,
    defaultMapLayer: defaultMapLayer,
    mapLayerOrder: mapLayerOrder,
    meshtastic: meshtastic,
    meshLink: meshLink,
    meshAlerts: meshAlerts,
    meshNodes: meshNodes,
    meshUnread: meshUnread,
    meshStore: meshStore,
    database: AppDatabase(durable: durable, cache: cache?.db),
    tleStore: TleStore(durable),
    meshGateway: DpipMeshGatewayImpl(meshtastic, () => meshLink.dpipChannel),
    endpointHealth: endpointHealth,
    etagCache: cache?.etag,
    networkUsage: cache?.usage,
    mapTileCache: mapTileCache,
  );

  // Reconnects to the saved radio, if there is one. Deliberately not awaited:
  // BLE takes seconds and the first frame must not wait for it.
  meshLink.start();
  // Local notifications for anything the mesh delivers while the user is
  // elsewhere — raised by the app itself, so they work with no internet.
  meshAlerts.start();
  meshNodes.start();
  if (meshStore != null) {
    MeshMetricsRecorder(meshtastic, meshNodes, meshStore).start();
  }

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
        ...meshtasticProviders(deps),
        ...releaseHighlightsProviders(deps),
        ...sponsorProviders(),
        ...homeProviders(),
        ...statusProviders(deps),
      ],
    ),
  );
}

/// Opens the SQLite ETag cache (and the network-usage tables it shares the
/// database with) under the platform cache directory. Best-effort: if the
/// database can't be opened the app runs without HTTP caching / accounting rather
/// than failing to launch. The usage tables are created with `IF NOT EXISTS` on
/// every open, so they're added to a pre-existing cache DB without a version bump.
///
/// The v1→v2 migration rides a probe instead of sqflite's `version`/`onUpgrade`
/// hooks (sqlite_async has none): the v2 `CREATE TABLE IF NOT EXISTS` is
/// harmless against either shape — [EtagCacheStore.migrateToV2] is what drops
/// the legacy envelope table when its columns say v1.
Future<({EtagCacheStore etag, NetworkUsageStore usage, SqliteDatabase db})?>
_openCache() async {
  try {
    final base = await getApplicationCacheDirectory();
    final db = EtagCacheStore.open(path: '${base.path}/http_etag_cache.db');
    await NetworkUsageStore.createSchema(db);
    await EtagCacheStore.createSchema(db);
    final usage = NetworkUsageStore(db);
    return (etag: EtagCacheStore(db, usage: usage), usage: usage, db: db);
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'ETag cache unavailable');
    return null;
  }
}

/// Opens the durable database — settings, orbital elements and mesh history.
///
/// Application-support, not cache: none of this can be fetched again, and the
/// cache directory is one the OS may empty whenever it wants space. The HTTP
/// cache is a separate file for exactly that reason, which is also what makes
/// "clear cache" unable to reach any of this. See `core/storage/app_database.dart`.
///
/// Best-effort like the cache. The old failure mode this used to retry around —
/// a notification-tap cold start losing a race for the file against the
/// background engine awesome spins up, and degrading the session to "never been
/// configured" — is gone at the source with sqlite_async: opens run on a
/// background isolate with WAL and a built-in lock timeout (30 s default), so
/// contention waits instead of failing. What remains here is the honest
/// fallback for an open that still fails (missing parent directory, full disk,
/// first-unlock encryption state): bounded retries, then [_recoverDurable]
/// keeps trying off the launch path. Every schema statement is `IF NOT EXISTS`
/// and runs on every open, so a database created by an older build picks up
/// tables added later without a version bump.
Future<SqliteDatabase?> _openDurable() async {
  const attempts = 3;
  Object? lastError;
  StackTrace? lastStackTrace;
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      final base = await getApplicationSupportDirectory();
      final db = SqliteDatabase(
        path: '${base.path}/dpip.db',
        options: const SqliteOptions(
          // WAL + busy_timeout are package defaults; FULL fsyncs every commit,
          // which is what settings, the mesh conversation and the log want —
          // none of it can be fetched again (the cache file relaxes to NORMAL).
          synchronous: SqliteSynchronous.full,
        ),
      );
      await _createDurableSchema(db);
      if (attempt > 1) {
        Log.info('durable database recovered on attempt $attempt/$attempts');
      }
      return db;
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (attempt < attempts) {
        Log.warning(
          'durable database attempt $attempt/$attempts failed: $error',
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  Log.handle(lastError!, lastStackTrace, 'durable database unavailable');
  return null;
}

/// Keeps trying to open the durable database after a launch that could not —
/// a degraded session is recoverable, not terminal.
///
/// A slow first unlock or a genuinely wedged file can still cost the open at
/// launch. Rather than showing a returning user onboarding for the rest of the
/// session, poll until the file opens (or the budget runs out), then hand it
/// to [SettingsStore.attachDatabase]: memory stays authoritative, disk catches
/// up, and everything written in between survives. The onboarding store then
/// re-announces, so a router redirect held on the welcome page re-runs and
/// releases the user the moment the flag is back.
Future<void> _recoverDurable(
  SettingsStore settings,
  OnboardingStore onboarding,
) async {
  const attempts = 10;
  const interval = Duration(seconds: 3);
  for (var attempt = 1; attempt <= attempts; attempt++) {
    await Future<void>.delayed(interval);
    try {
      final base = await getApplicationSupportDirectory();
      final db = SqliteDatabase(
        path: '${base.path}/dpip.db',
        options: const SqliteOptions(synchronous: SqliteSynchronous.full),
      );
      await _createDurableSchema(db);
      final moved = await settings.attachDatabase(db);
      Log.info(
        'durable database attached in the background'
        '${moved ? '; reconciled session-only writes' : ''}',
      );
      // Rows adopted from disk (onboarding.complete among them) only matter
      // once listeners re-read them: OnboardingStore's listeners re-read the
      // store, and the router's redirect re-runs on the refresh signal.
      onboarding.reload();
      onboardingRefresh.fire();
      return;
    } catch (error) {
      Log.warning('durable recovery attempt $attempt/$attempts failed: $error');
    }
  }
  Log.error(
    'durable database never opened this session; '
    'settings will not persist until the next launch',
  );
}

Future<void> _createDurableSchema(SqliteDatabase db) async {
  await SettingsStore.createSchema(db);
  await LogStore.createSchema(db);
  await TleStore.createSchema(db);
  await MeshStore.createSchema(db);
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
