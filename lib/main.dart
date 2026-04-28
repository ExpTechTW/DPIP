import 'dart:async';
import 'dart:io';

import 'package:dpip/app.dart';
import 'package:dpip/core/compass.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/i18n.dart';
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
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart';

final fcmReadyCompleter = Completer<void>();
final talker = TalkerManager.instance;

void main() async {
  final overallStartTime = DateTime.now();
  talker.log('--- 冷啟動偵測開始 ---');
  talker.log('🔥 1. (main) 啟動時間: ${overallStartTime.toIso8601String()}');
  WidgetsFlutterBinding.ensureInitialized();
  String? initialShortcut;

  if (Platform.isIOS) {
    // iOS 14 以下改回用 StoreKit1
    InAppPurchaseStoreKitPlatform.enableStoreKit1();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    talker.handle(details.exception, details.stack);
  };

  final globalInitStart = DateTime.now();
  talker.log('⏳ 2. 啟動 Global...');
  await Global.init();
  final globalInitEnd = DateTime.now();
  talker.log(
    '✅ 2. Global 完成。耗時: ${globalInitEnd.difference(globalInitStart).inMilliseconds}ms',
  );

  await Preference.init();
  final isFirstLaunch = Preference.instance.getBool('isFirstLaunch') ?? true;
  GlobalProviders.init();
  initializeTimeZones();
  initialShortcut = await getInitialShortcut();

  talker.log('⏳ 3. 啟動 並行任務... (測量總耗時)');
  final futureWaitStart = DateTime.now();
  await Future.wait([
    _loggedTask('AppLocalizations.load', AppLocalizations.load()),
    _loggedTask(
      'LocationNameLocalizations.load',
      LocationNameLocalizations.load(),
    ),
    // _loggedTask(
    //   'WeatherStationLocalizations.load',
    //   WeatherStationLocalizations.load(),
    // ),
  ]);
  final futureWaitEnd = DateTime.now();
  talker.log(
    '✅ 3.並行任務全部完成。總耗時 (取決於最慢任務): ${futureWaitEnd.difference(futureWaitStart).inMilliseconds}ms',
  );

  if (Platform.isIOS) {
    await DeviceInfo.init();
  } else {
    unawaited(
      () async {
        final start = DateTime.now();
        await DeviceInfo.init();
        talker.log(
          '📱 DeviceInfo.init 完成 ${DateTime.now().difference(start).inMilliseconds}ms',
        );
      }(),
    );
  }

  if (isFirstLaunch) {
    talker.log('🟣 首次啟動 → 前置初始化 FCM + 通知');
    await Future.wait([
      _loggedTask('fcmInit', fcmInit()),
      _loggedTask('notifyInit', notifyInit()),
    ]);
    unawaited(Future(() => updateInfoToServer()));
    await Preference.instance.setBool('isFirstLaunch', false);
  }

  final overallEndTime = DateTime.now();
  talker.log(
    '🚨 總初始化耗時 (runApp 前): ${overallEndTime.difference(overallStartTime).inMilliseconds}ms',
  );

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
          ChangeNotifierProvider.value(value: GlobalProviders.experimental),
          ChangeNotifierProvider.value(value: GlobalProviders.location),
          ChangeNotifierProvider.value(value: GlobalProviders.map),
          ChangeNotifierProvider.value(value: GlobalProviders.notification),
          ChangeNotifierProvider.value(value: GlobalProviders.ui),
        ],
        child: DpipApp(initialShortcut: initialShortcut),
      ),
    ),
  );
  if (!isFirstLaunch) {
    talker.log('🟢 非首次啟動 → FCM + 通知 為背景初始化');
    unawaited(
      Future(() async {
        try {
          await fcmInit();
          await notifyInit();
          await updateInfoToServer();
        } catch (e, st) {
          talker.error('背景初始化失敗: $e\n$st');
        }
      }),
    );
  }
  unawaited(CompassService.instance.initialize());
  final locationInitStart = DateTime.now();
  talker.log('🚀 啟動 LocationServiceManager ...');
  final locationFuture = LocationServiceManager.initalize();

  locationFuture
      .whenComplete(() {
        final locationInitEnd = DateTime.now();
        final locationDuration = locationInitEnd.difference(locationInitStart).inMilliseconds;
        talker.log('✅ LocationServiceManager 完成。耗時: ${locationDuration}ms');
      })
      .catchError((e) {
        talker.error('❌ LocationServiceManager 失敗。錯誤: $e');
      });
}

const platform = MethodChannel('com.exptech.dpip/shortcut');

Future<String?> getInitialShortcut() async {
  try {
    final result = await platform.invokeMethod<String>('getInitialShortcut');
    return result;
  } on PlatformException catch (e, st) {
    talker.error('Failed to get initial shortcut', e, st);
    return null;
  }
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
    rethrow;
  }
}
