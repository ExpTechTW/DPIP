import 'package:dpip/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Initializes platform services and launches the app.
///
/// Firebase reads its configuration from the native `google-services.json` /
/// `GoogleService-Info.plist` bundled with each platform, so no generated
/// options file is required here.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const DpipApp());
}
