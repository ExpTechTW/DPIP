import 'package:dpip/api/exclusive_api.dart';
import 'package:dpip/api/external_api.dart';
import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/app/app.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes platform services and launches the app.
///
/// Firebase reads its configuration from the native `google-services.json` /
/// `GoogleService-Info.plist` bundled with each platform, so no generated
/// options file is required here.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  Log.installErrorHandlers();
  Log.info('DPIP starting up');

  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final regions = RegionSelection(prefs);
  final dio = createDio();
  final apiClient = ApiClient(dio, regions);

  runApp(
    DpipApp(
      regions: regions,
      redundantApi: RedundantApi(apiClient),
      exclusiveApi: ExclusiveApi(apiClient),
      externalApi: ExternalApi(dio),
    ),
  );
}
