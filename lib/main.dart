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
import 'package:geocoding/geocoding.dart';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/locator_settings.dart' as background_locator;

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
  String? currentLocation;
  late StreamSubscription<Position> positionStreamSubscription;
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
    startBackgroundLocator();
  }

  @override
  void dispose() {
    super.dispose();
    BackgroundLocator.unRegisterLocationUpdate();
  }

  void startBackgroundLocator() async {
    await BackgroundLocator.initialize();
    BackgroundLocator.registerLocationUpdate(
      locationCallback,
      initCallback: initCallback,
      disposeCallback: disposeCallback,
      iosSettings: const IOSSettings(
        accuracy: background_locator.LocationAccuracy.BALANCED,
        distanceFilter: 500,
      ),
      autoStop: false,
      androidSettings: const AndroidSettings(
        accuracy: background_locator.LocationAccuracy.BALANCED,
        interval: 3600,
        distanceFilter: 500,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location tracking',
          notificationTitle: 'Start Location Tracking',
          notificationMsg: 'Track location in background',
          notificationBigMsg: 'Background location tracking is running',
          notificationIconColor: Colors.grey,
          notificationTapCallback: notificationCallback,
        ),
      ),
    );
  }

  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    print('Locator initialized');
  }

  static Future<void> disposeCallback() async {
    print('Locator disposed');
  }

  static Future<void> locationCallback(locationDto) async {
    double latitude = locationDto.latitude;
    double longitude = locationDto.longitude;

    // 使用 geocoding 插件進行反向地理編碼
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String address = '${place.street}, ${place.locality}, ${place.country}';
      print('Current location address: $address');
    } else {
      print('No address available for the current location');
    }

    // 處理你的位置信息上報邏輯，例如：
    String coordinate = '$latitude,$longitude';
    String? token = await messaging.getToken();
    if (token != null) {
      try {
        String response = await Global.api.postNotifyLocation(
          "0.0.0",
          "Android",
          coordinate,
          token,
        );
        print(response);
      } catch (error) {
        print('Location update error: $error');
      }
    }
  }

  static void notificationCallback() {
    print('Notification clicked');
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
