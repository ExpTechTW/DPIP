import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/location.dart';
import 'package:dpip/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final service = FlutterBackgroundService();

Future<void> startBackgroundService() async {
  var isRunning = await service.isRunning();
  print("Background Service running $isRunning");
  if (!isRunning) {
    service.startService();
  }
}

Future<void> stopBackgroundService() async {
  var isRunning = await service.isRunning();
  print("Background Service running $isRunning");
  if (isRunning) {
    service.invoke("stopService");
  }
}

Future<void> initializeService() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

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

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
    print("stop");
    debugPrint("background process is now stopped");
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final position = await getLocation();
        String lat = position.position.latitude.toStringAsFixed(4);
        String lon = position.position.longitude.toStringAsFixed(4);
        LocationResult country = await getLatLngLocation(position.position.latitude, position.position.longitude);
        String fcmToken = Global.preference.getString("fcm-token") ?? "";
        if (position.change && fcmToken != "") {
          final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
          print(body);
        }
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}\n$lat,$lon ${country.cityTown}',
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
          title: "My App Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }
  });
}
