import 'package:dpip/api/exclusive_api.dart';
import 'package:dpip/api/external_api.dart';
import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/app/app.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/data/eew_repository_impl.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/shared/map/radar_api.dart';
import 'package:dpip/shared/map/radar_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes platform services and launches the app.
///
/// Firebase reads its configuration from the native `google-services.json` /
/// `GoogleService-Info.plist` bundled with each platform. Those files are not
/// yet in place on the rewrite branch, so initialization is best-effort: a
/// missing/invalid config is logged and the app still launches (push
/// notifications are simply unavailable until the config is added).
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
  final redundantApi = RedundantApi(apiClient);
  final exclusiveApi = ExclusiveApi(apiClient);
  final eewRepository = EewRepositoryImpl(redundantApi);

  // Realtime spine: a corrected server clock feeds staleness; each feed is a
  // channel the service starts after the first frame and pauses on background.
  // The initial clock sync is fire-and-forget so it never delays launch (EEW
  // staleness is offset-independent — both instants come from this clock).
  final serverClock = ServerClock(
    const SystemClock(),
    NtpServerTimeSource(exclusiveApi.getNtp),
  );
  serverClock.sync().ignore();

  final realtimeService = RealtimeService(serverClock);
  final eewChannel = RealtimeChannel<List<Eew>>(
    source: EewRealtimeSource(eewRepository),
    clock: serverClock,
    elapsed: SystemElapsed(),
    ticker: const SystemTicker(),
    config: RealtimeConfig.eew,
    label: 'eew',
  );
  realtimeService.register(eewChannel);
  final eewController = EewRealtimeController(eewChannel);

  runApp(
    DpipApp(
      regions: regions,
      experimental: experimental,
      redundantApi: redundantApi,
      exclusiveApi: exclusiveApi,
      externalApi: ExternalApi(dio),
      radarRepository: RadarRepositoryImpl(RadarApi(apiClient)),
      eewRepository: eewRepository,
      realtimeService: realtimeService,
      eewController: eewController,
    ),
  );
}
