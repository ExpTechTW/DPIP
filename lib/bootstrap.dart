import 'package:dpip/app/app.dart';
import 'package:dpip/core/di/core_providers.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/ntp_api.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/features/earthquake/earthquake_providers.dart';
import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/weather/weather_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final dio = createDio();
  final apiClient = ApiClient(dio, regions);

  // Realtime spine: a corrected server clock feeds staleness. The initial clock
  // sync is fire-and-forget so it never delays launch (EEW staleness is
  // offset-independent — both instants come from this clock).
  final serverClock = ServerClock(
    const SystemClock(),
    NtpServerTimeSource(NtpApi(apiClient).serverTimeMs),
  );
  serverClock.sync().ignore();
  final realtimeService = RealtimeService(serverClock);

  // Push: best-effort so a missing push environment never blocks launch.
  final notificationService = NotificationService(prefs);
  try {
    await notificationService.init();
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'Notification init skipped');
  }

  final deps = SharedDeps(
    prefs: prefs,
    apiClient: apiClient,
    regions: regions,
    experimental: experimental,
    serverClock: serverClock,
    realtimeService: realtimeService,
    notificationService: notificationService,
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
        ...homeProviders(),
      ],
    ),
  );
}
