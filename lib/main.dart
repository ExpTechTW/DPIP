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

import 'core/fcm.dart';
import 'model/received_notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final FirebaseMessaging messaging = FirebaseMessaging.instance;
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();
final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

const String darwinNotificationCategoryText = 'textCategory';
const String navigationActionId = 'id_3';
const String darwinNotificationCategoryPlain = 'plainCategory';

final List<DarwinNotificationCategory> darwinNotificationCategories = <DarwinNotificationCategory>[
  DarwinNotificationCategory(
    darwinNotificationCategoryText,
    actions: <DarwinNotificationAction>[
      DarwinNotificationAction.text(
        'text_1',
        'Action 1',
        buttonTitle: 'Send',
        placeholder: 'Placeholder',
      ),
    ],
  ),
  DarwinNotificationCategory(
    darwinNotificationCategoryPlain,
    actions: <DarwinNotificationAction>[
      DarwinNotificationAction.plain('id_1', 'Action 1'),
      DarwinNotificationAction.plain(
        'id_2',
        'Action 2 (destructive)',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.destructive,
        },
      ),
      DarwinNotificationAction.plain(
        navigationActionId,
        'Action 3 (foreground)',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        'id_4',
        'Action 4 (auth required)',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.authenticationRequired,
        },
      ),
    ],
    options: <DarwinNotificationCategoryOption>{
      DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
    },
  )
];

void ignoreErrors(_) {}

void setupAndroidNotificationChannels() {
  AndroidFlutterLocalNotificationsPlugin? plugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (plugin == null) return;

  const report = AndroidNotificationChannel(
    "report",
    "地震報告",
    groupId: "earthquake",
    description: "地震發生後接收的地震報告。",
    importance: Importance.defaultImportance,
  );

  const intensity = AndroidNotificationChannel(
    "intensity",
    "震度速報",
    groupId: "earthquake",
    description: "地震發生後接收的各地地震的最大震度通知。",
    importance: Importance.high,
  );

  const eew = AndroidNotificationChannel(
    "eew",
    "地震速報",
    groupId: "earthquake",
    description: "在地震發生時接收中央氣象署發布的強震即時警報。",
    importance: Importance.max,
    enableLights: true,
    enableVibration: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound("eew_alert.wav"),
  );

  const monitor = AndroidNotificationChannel(
    "monitor",
    "強震監視器",
    groupId: "earthquake",
    description: "當 TREM 在全臺部署的測站中，離所在地最近的測站觸發時接收的通知。",
    importance: Importance.high,
  );

  plugin.createNotificationChannel(report).catchError(ignoreErrors);
  plugin.createNotificationChannel(intensity).catchError(ignoreErrors);
  plugin.createNotificationChannel(eew).catchError(ignoreErrors);
  plugin.createNotificationChannel(monitor).catchError(ignoreErrors);
}

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
    notificationCategories: darwinNotificationCategories,
  );
  final initializationSettings = InitializationSettings(
    android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
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

  if (Platform.isAndroid) {
    setupAndroidNotificationChannels();
  }

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
