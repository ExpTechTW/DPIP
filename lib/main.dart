import 'dart:io';

import 'package:dpip/app.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart';

import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  final talker = TalkerManager.instance;
  talker.log('start');
  FlutterError.onError = (FlutterErrorDetails details) {
    talker.handle(details.exception, details.stack);

    if (Platform.isAndroid) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  await Global.init();
  await DeviceInfo.init();
  await Preference.init();
  GlobalProviders.init();

  initializeTimeZones();

  await fcmInit();
  await notifyInit();
  initBackgroundService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GlobalProviders.location),
        ChangeNotifierProvider.value(value: GlobalProviders.notification),
        ChangeNotifierProvider.value(value: GlobalProviders.ui),
      ],
      child: const DpipApp(),
    ),
  );
}
