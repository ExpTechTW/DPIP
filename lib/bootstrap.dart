import 'package:dpip/api/exclusive_api.dart';
import 'package:dpip/api/external_api.dart';
import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/app/app.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/features/map/data/radar_api.dart';
import 'package:dpip/features/settings/presentation/experimental_settings.dart';
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

  runApp(
    DpipApp(
      regions: regions,
      experimental: experimental,
      redundantApi: RedundantApi(apiClient),
      exclusiveApi: ExclusiveApi(apiClient),
      externalApi: ExternalApi(dio),
      radarApi: RadarApi(apiClient),
    ),
  );
}
