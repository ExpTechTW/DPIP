import 'dart:async';
import 'dart:io';

import 'package:dpip/global.dart';
import 'package:dpip/view/init.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import 'core/fcm.dart';
import 'model/received_notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final FirebaseMessaging messaging = FirebaseMessaging.instance;
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();
final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();
final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;
StreamSubscription<Position>? positionStreamSubscription;

const String darwinNotificationCategoryText = 'textCategory';
const String navigationActionId = 'id_3';
const String darwinNotificationCategoryPlain = 'plainCategory';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  await Global.init();
  await Firebase.initializeApp();
  await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );
  FirebaseMessaging.onMessage.listen(messageHandler);
  FirebaseMessaging.onBackgroundMessage(messageHandler);
  FirebaseMessaging.onMessageOpenedApp.listen(messageHandler);

  final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
      didReceiveLocalNotificationStream.add(
        ReceivedNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        ),
      );
    },
  );
  final initializationSettings = InitializationSettings(
    android: const AndroidInitializationSettings('ic_launcher'),
    iOS: initializationSettingsDarwin,
  );
  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          selectNotificationStream.add(notificationResponse.payload);
          break;
        case NotificationResponseType.selectedNotificationAction:
          if (notificationResponse.actionId == navigationActionId) {
            selectNotificationStream.add(notificationResponse.payload);
          }
          break;
      }
    },
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<StatefulWidget> createState() => MainAppState();

  static MainAppState? of(BuildContext context) => context.findAncestorStateOfType<MainAppState>();
}

class MainAppState extends State<MainApp> {
  ThemeMode _themeMode = {
        "light": ThemeMode.light,
        "dark": ThemeMode.dark,
        "system": ThemeMode.system
      }[Global.preference.getString('theme')] ??
      ThemeMode.system;

  void changeTheme(String themeMode) {
    setState(() {
      switch (themeMode) {
        case "light":
          _themeMode = ThemeMode.light;
          break;
        case "dark":
          _themeMode = ThemeMode.dark;
          break;
        case "system":
          _themeMode = ThemeMode.system;
          break;
        default:
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startPositionStream();
  }

  void startPositionStream() {
    if (positionStreamSubscription == null) {
      final positionStream = geolocatorPlatform.getPositionStream(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.medium,
                distanceFilter: 500,
                forceLocationManager: false,
                intervalDuration: const Duration(minutes: 5),
                //(Optional) Set foreground notification config to keep the app alive
                //when going to the background
                foregroundNotificationConfig: const ForegroundNotificationConfig(
                  notificationText: "服務中...",
                  notificationTitle: "DPIP 背景定位",
                  notificationChannelName: '背景定位',
                  enableWifiLock: true,
                  enableWakeLock: true,
                  setOngoing: false,
                ),
              )
            : AppleSettings(
                accuracy: LocationAccuracy.low,
                activityType: ActivityType.other,
                distanceFilter: 500,
                timeLimit: const Duration(minutes: 5),
                pauseLocationUpdatesAutomatically: true,
                // Only set to true if our app will be started up in the background.
                showBackgroundLocationIndicator: false,
                allowBackgroundLocationUpdates: true,
              ),
      );
      positionStreamSubscription = positionStream.handleError((error) {
        positionStreamSubscription?.cancel();
        positionStreamSubscription = null;
      }).listen((Position? position) async {
        if (position != null) {
          String? lat = position.latitude.toStringAsFixed(4);
          String? lon = position.longitude.toStringAsFixed(4);
          String? coordinate = '$lat,$lon';
          messaging.getToken().then((value) {
            Global.api.postNotifyLocation(
              Global.packageInfo.version,
              Platform.isAndroid ? "0" : "1",
              coordinate,
              value!,
            );
          });
        }
      });
      print('位置已開啟');
    }
  }

  //   positionStreamSubscription = Geolocator.getPositionStream(
  //     locationSettings: locationSettings,
  //   )
  //   .listen((Position position) {
  //     setState(() {
  //       currentLocation = '位置: ${position.latitude}, ${position.longitude}';
  //     });

  //     if (lastPosition != null) {
  //       double distance = Geolocator.distanceBetween(
  //         lastPosition!.latitude,
  //         lastPosition!.longitude,
  //         position.latitude,
  //         position.longitude,
  //       );

  //       if (distance >= 100) {
  //         stopPositionStream();
  //       }
  //     }

  //     lastPosition = position;
  //   });
  // }

  void stopPositionStream() {
    positionStreamSubscription?.cancel();
    positionStreamSubscription = null;
    print('位置已停止');
  }

  @override
  void dispose() {
    stopPositionStream();
    super.dispose();
  }

  // static Future<void> initCallback(Map<dynamic, dynamic> params) async {
  //   print('Locator initialized');
  // }

  // static Future<void> disposeCallback() async {
  //   print('Locator disposed');
  // }

  // static void notificationCallback() {
  //   print('Notification clicked');
  // }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoApp(
        home: const InitPage(),
        theme: CupertinoThemeData(
          brightness: _themeMode == ThemeMode.system
              ? SchedulerBinding.instance.platformDispatcher.platformBrightness
              : _themeMode == ThemeMode.light
                  ? Brightness.light
                  : Brightness.dark,
        ),
      );
    } else {
      return DynamicColorBuilder(
        builder: (lightColorScheme, darkColorScheme) => MaterialApp(
          title: "DPIP",
          theme: ThemeData(
            colorScheme: lightColorScheme,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            brightness: Brightness.dark,
          ),
          themeMode: _themeMode,
          home: const InitPage(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }
  }
}
