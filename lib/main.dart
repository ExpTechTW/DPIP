import 'dart:io';

import 'package:dpip/app.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/core/update.dart';
import 'package:dpip/core/widget_background.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/log.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart';

final talker = TalkerManager.instance;
void main() async {
  final overallStartTime = DateTime.now();
  talker.log('--- 冷啟動偵測開始 ---');
  talker.log('🔥 1. 主函數 (main) 啟動時間: ${overallStartTime.toIso8601String()}');
  WidgetsFlutterBinding.ensureInitialized();
  // iOS 14 以下改回用 StoreKit1
  InAppPurchaseStoreKitPlatform.enableStoreKit1();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  FlutterError.onError = (FlutterErrorDetails details) {
    talker.handle(details.exception, details.stack);

    if (Platform.isAndroid) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  final globalInitStart = DateTime.now();
  talker.log('⏳ 2. 啟動 Global.init()...');
  await Global.init();
  final globalInitEnd = DateTime.now();
  final globalDuration = globalInitEnd.difference(globalInitStart).inMilliseconds;
  talker.log('✅ 2. Global.init() 完成。耗時: ${globalDuration}ms');

  await Preference.init();
  GlobalProviders.init();
  initializeTimeZones();

  talker.log('⏳ 3. 啟動 Future.wait 並行任務... (測量總耗時)');
  final futureWaitStart = DateTime.now();
  await Future.wait([
    _loggedTask('DeviceInfo.init', DeviceInfo.init()),
    _loggedTask('AppLocalizations.load', AppLocalizations.load()),
    _loggedTask('LocationNameLocalizations.load', LocationNameLocalizations.load()),
    _loggedTask('WeatherStationLocalizations.load', WeatherStationLocalizations.load()),
    _loggedTask('fcmInit', fcmInit()),
    _loggedTask('notifyInit', notifyInit()),
    _loggedTask('updateInfoToServer', updateInfoToServer()),
    _loggedTask('WidgetBackground.initialize', WidgetBackground.initialize()),
  ]);

  final futureWaitEnd = DateTime.now();
  final futureWaitDuration = futureWaitEnd.difference(futureWaitStart).inMilliseconds;
  talker.log('✅ 3. Future.wait 並行任務全部完成。總耗時 (取決於最慢任務): ${futureWaitDuration}ms');

  final overallEndTime = DateTime.now();
  final overallDuration = overallEndTime.difference(overallStartTime).inMilliseconds;
  talker.log('--- 冷啟動偵測結束 ---');
  talker.log('🎉 4. 主函數執行完成 (準備呼叫 runApp)。');
  talker.log('🚨 總初始化耗時 (Main 開始到 runApp 前): ${overallDuration}ms');

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
  final locationInitStart = DateTime.now();
  talker.log('🚀 5. 啟動 LocationServiceManager.initalize() (並行背景執行)...');
  // ***關鍵修改：移除 await***
  final locationFuture = LocationServiceManager.initalize();

  locationFuture.whenComplete(() {
    final locationInitEnd = DateTime.now();
    final locationDuration = locationInitEnd.difference(locationInitStart).inMilliseconds;
    talker.log('✅ 5. LocationServiceManager.initalize() 完成。耗時: ${locationDuration}ms');
  }).catchError((e) {
    talker.error('❌ 5. LocationServiceManager.initalize() 失敗。錯誤: $e');
  });
}
Future<T> _loggedTask<T>(String taskName, Future<T> future) async {
  final start = DateTime.now();
  try {
    final result = await future;
    final end = DateTime.now();
    final duration = end.difference(start).inMilliseconds;
    talker.log('  [並行] 任務 "$taskName" 完成。耗時: ${duration}ms');
    return result;
  } catch (e) {
    final end = DateTime.now();
    final duration = end.difference(start).inMilliseconds;
    talker.error('  [並行] 任務 "$taskName" 失敗。耗時: ${duration}ms', e);
    rethrow; // 確保失敗時應用程式會報錯
  }
}
