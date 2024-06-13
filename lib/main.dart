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
Position? lastPosition;

const String darwinNotificationCategoryText = 'textCategory';
const String navigationActionId = 'id_3';
const String darwinNotificationCategoryPlain = 'plainCategory';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // BackgroundTask.instance.setBackgroundHandler(backgroundHandler);
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

// @pragma('vm:entry-point')
// void backgroundHandler(Location data) {
//   // Implement the process you want to run in the background.
//   // ex) Check health data.
//
//   print('背景位置: ${data.lat}, ${data.lng}');
// }

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<StatefulWidget> createState() => MainAppState();

  static MainAppState? of(BuildContext context) => context.findAncestorStateOfType<MainAppState>();
}

class MainAppState extends State<MainApp> {
  String? currentLocation;
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
    initializeBackgroundTask();
  }

  void initializeBackgroundTask() async {
    bool serviceEnabled;
    LocationPermission permission;
    bool isLocationAutoSetEnabled = Global.preference.getBool("loc-auto") ?? false;

    if (isLocationAutoSetEnabled) {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('定位服務被禁止。');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('位置權限被拒絕。');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error('位置權限被永久拒絕，我們無法請求權限。');
      }

      startPositionStream();
    }
  }

  void startPositionStream() {
    if (positionStreamSubscription == null) {
      if (Platform.isAndroid) {
        final positionStream = geolocatorPlatform.getPositionStream(
            locationSettings: AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 100,
                forceLocationManager: false,
                intervalDuration: const Duration(seconds: 1),
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
              Future<String> test = Global.api.postNotifyLocation(
                Global.packageInfo.version,
                (Platform.isAndroid) ? "1" : "0",
                coordinate,
                value!,
              );
              test.then((value) {
                print(value); // 打印 Future<String> 的值
              }).catchError((error) {
                print('發生錯誤: $error');
              });
            });
          }
        });
      } else if (Platform.isIOS) {
        final positionStream = geolocatorPlatform.getPositionStream(
          locationSettings: AppleSettings(
            accuracy: LocationAccuracy.medium,
            activityType: ActivityType.otherNavigation,
            distanceFilter: 100,
            timeLimit: const Duration(minutes: 15),
            pauseLocationUpdatesAutomatically: true,
            // Only set to true if our app will be started up in the background.
            showBackgroundLocationIndicator: false,
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
                (Platform.isAndroid) ? "0" : "1",
                coordinate,
                value!,
              )
              .then((value) {
                print(value); // 打印 Future<String> 的值
              }).catchError((error) {
                print('發生錯誤: $error');
              });
            });
          }
        });
      }
    }

    positionStreamSubscription = Geolocator.getPositionStream(
            // locationSettings: locationSettings,
            )
        .listen((Position position) {
      setState(() {
        currentLocation = '位置: ${position.latitude}, ${position.longitude}';
      });

      if (lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance >= 100) {
          stopPositionStream();
        }
      }

      lastPosition = position;
    });
    print('位置已開啟');
  }

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

  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    print('Locator initialized');
  }

  static Future<void> disposeCallback() async {
    print('Locator disposed');
  }

  // static Future<void> locationCallback(locationDto) async {
  //   double latitude = locationDto.latitude;
  //   double longitude = locationDto.longitude;

  //   List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
  //   if (placemarks.isNotEmpty) {
  //     Placemark place = placemarks.first;
  //     String address = '${place.street}, ${place.locality}, ${place.country}';
  //     print('Current location address: $address');
  //   } else {
  //     print('No address available for the current location');
  //   }

  //   String coordinate = '$latitude,$longitude';
  //   String? token = await messaging.getToken();
  //   if (token != null) {
  //     try {
  //       String response = await Global.api.postNotifyLocation(
  //         "0.0.0",
  //         "Android",
  //         coordinate,
  //         token,
  //       );
  //       print(response);
  //     } catch (error) {
  //       print('Location update error: $error');
  //     }
  //   }
  // }

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
