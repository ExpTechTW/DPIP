import 'dart:io';

import 'package:dpip/app/app.dart';
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_api.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/ntp_time_source.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/earthquake_providers.dart';
import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/notification/notification_providers.dart';
import 'package:dpip/features/weather/weather_providers.dart';
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
/// Firebase reads its configuration from the native `google-services.json` /
/// `GoogleService-Info.plist`. Firebase init and notification setup are
/// best-effort: a failure is logged and the app still launches (push is simply
/// unavailable until the environment is complete).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  Log.installErrorHandlers();
  Log.info('DPIP starting up');

  try {
    await Firebase.initializeApp();
    Log.info('Firebase initialized');
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'Firebase init skipped (no config yet)');
  }

  final prefs = await SharedPreferences.getInstance();
  final regions = RegionSelection(prefs);
  final experimental = ExperimentalSettings(prefs);
  final dio = createDio(etagCache: await _openEtagCache());
  final apiClient = ApiClient(dio, regions);

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

  // Push: best-effort so a missing push environment never blocks launch.
  final notificationService = NotificationService(prefs);
  try {
    await notificationService.init();
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'Notification init skipped');
  }

  // Location: the township directory backs both GPS resolution and Home region
  // labels; the region store holds the Home selection; the location service maps
  // a GPS fix to a township. GPS itself is requested after the first frame.
  final townDirectory = await TownDirectory.load();
  final regionStore = RegionStore(prefs);
  final locationService = LocationService(townDirectory);

  // Distance-triggered device-location report: on each meaningful move, POST the
  // coordinates for push targeting (platform + push token + app version). Started
  // after the first frame once GPS permission is granted; a null token (not yet
  // registered) simply skips — it self-heals on the next move.
  final locationApi = LocationApi(apiClient);
  final appVersion = (await PackageInfo.fromPlatform()).version;
  final reportPlatform = Platform.isIOS ? 1 : 0;
  final deviceLocationReporter = DeviceLocationReporter(
    positions: locationService.positionStream(),
    onMoved: (fix) async {
      final token = notificationService.token;
      if (token == null) return;
      await locationApi.updateDeviceLocation(
        platform: reportPlatform,
        token: token,
        version: appVersion,
        lat: fix.lat,
        lng: fix.lng,
      );
    },
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
    regionStore: regionStore,
    locationService: locationService,
    deviceLocationReporter: deviceLocationReporter,
  );

  // Each feature turns [deps] into its providers (and registers its realtime
  // channels). Adding a feature = one line here + its `*Providers` function.
  runApp(
    DpipApp(
      deps: deps,
      providers: [
        ...coreProviders(deps),
        ...earthquakeProviders(deps),
        ...weatherProviders(deps),
        ...notificationProviders(deps),
        ...homeProviders(),
      ],
    ),
  );
}

/// Opens the SQLite ETag cache under the platform cache directory. Best-effort:
/// if the database can't be opened the app runs without HTTP caching rather than
/// failing to launch.
Future<EtagCacheStore?> _openEtagCache() async {
  try {
    final base = await getApplicationCacheDirectory();
    final db = await openDatabase(
      '${base.path}/http_etag_cache.db',
      version: 1,
      onCreate: (db, _) => EtagCacheStore.createSchema(db),
    );
    return EtagCacheStore(db);
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'ETag cache unavailable');
    return null;
  }
}
