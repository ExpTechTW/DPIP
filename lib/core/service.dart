import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/location.dart';
import 'package:dpip/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final service = FlutterBackgroundService();

void initService() async {
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  if (isAutoLocatingEnabled) {
    final isNotificationEnabled = await Permission.notification.status;
    final isLocationAlwaysEnabled = await Permission.locationAlways.status;
    if (isLocationAlwaysEnabled.isGranted && isNotificationEnabled.isGranted) {
      startBackgroundService();
    } else {
      stopBackgroundService();
    }
  }
}

void startBackgroundService() async {
  LocationService locationService = LocationService();

  if (Platform.isIOS) {
    locationService.iosStartPositionStream();
  } else if (Platform.isAndroid) {
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    } else {
      initializeService();
    }
  }
}

void stopBackgroundService() async {
  LocationService locationService = LocationService();
  if (Platform.isIOS) {
    locationService.stopPositionStream();
  } else if (Platform.isAndroid) {
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    }
  }
}

Future<void> initializeService() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      iOS: DarwinInitializationSettings(),
      android: AndroidInitializationSettings('ic_bg_service_small'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Global.init();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) {
    service.stopSelf();
    print("background process is now stopped");
  });

  if (service is AndroidServiceInstance) {
    service.setAutoStartOnBootMode(true);

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      LocationService locationService = LocationService();
      if (await service.isForegroundService()) {
        final position = await locationService.getLocation();
        String lat = position.position.latitude.toStringAsFixed(4);
        String lon = position.position.longitude.toStringAsFixed(4);
        String country = position.position.country;
        String fcmToken = Global.preference.getString("fcm-token") ?? "";
        if (position.change && fcmToken != "") {
          final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
          print(body);
        }
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}\n$lat,$lon $country',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        service.setForegroundNotificationInfo(
          title: 'COOL SERVICE',
          content: 'Awesome ${DateTime.now()}\n$lat,$lon $country',
        );
      }
    });
  }
}
