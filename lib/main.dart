import 'dart:io';

import 'package:dpip/app.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/installation_tracker.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/core/update.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/log.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeInstallationData();

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
  await AppLocalizations.load();

  initializeTimeZones();

  await fcmInit();
  await notifyInit();
  initBackgroundService();

  await updateInfoToServer();

  runApp(
    I18n(
      initialLocale: GlobalProviders.ui.locale,
      supportedLocales: [
        'en'.asLocale,
        'ja'.asLocale,
        'ko'.asLocale,
        'ru'.asLocale,
        'vi'.asLocale,
        'zh'.asLocale,
        'zh-Hans'.asLocale,
        'zh-Hant'.asLocale,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: GlobalProviders.data),
          ChangeNotifierProvider.value(value: GlobalProviders.location),
          ChangeNotifierProvider.value(value: GlobalProviders.map),
          ChangeNotifierProvider.value(value: GlobalProviders.notification),
          ChangeNotifierProvider.value(value: GlobalProviders.ui),
        ],
        child: const DpipApp(),
      ),
    ),
  );
}
