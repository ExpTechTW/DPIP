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

Timer? timer;
FlutterBackgroundService service = FlutterBackgroundService();
bool androidServiceInit = false;

void initBackgroundService() async {
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  if (isAutoLocatingEnabled) {
    final isNotificationEnabled = await Permission.notification.status;
    final isLocationAlwaysEnabled = await Permission.locationAlways.status;
    if (isLocationAlwaysEnabled.isGranted && isNotificationEnabled.isGranted) {
      if (Platform.isAndroid) {
        androidForegroundService();
      }
      startBackgroundService(true);
    }
  }
}

void startBackgroundService(bool init) async {
  if (Platform.isIOS) {
    LocationService locationService = LocationService();
    locationService.iosStartPositionStream();
  } else if (Platform.isAndroid) {
    if (!androidServiceInit) {
      androidForegroundService();
    }
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    } else if (!init) {
      stopBackgroundService();
      service.startService();
    }
  }
}

void stopBackgroundService() async {
  if (Platform.isIOS) {
    LocationService locationService = LocationService();
    locationService.iosStopPositionStream();
  } else if (Platform.isAndroid) {
    timer?.cancel();
    if (await service.isRunning()) {
      service.invoke("stopService");
    }
  }
}

Future<void> androidForegroundService() async {
  androidServiceInit = true;
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    '前景自動定位',
    description: '前景自動定位',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      iOS: DarwinInitializationSettings(),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
      initialNotificationTitle: 'DPIP',
      initialNotificationContent: '前景服務啟動中...',
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

  LocationService locationService = LocationService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setAutoStartOnBootMode(false);
    }
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

    void task() async {
      if (await service.isForegroundService()) {
        final position = await locationService.androidGetLocation();
        String lat = position.position.latitude.toStringAsFixed(4);
        String lon = position.position.longitude.toStringAsFixed(4);
        String country = position.position.country;
        String? fcmToken = Global.preference.getString("fcm-token");
        if (position.change && fcmToken != null) {
          final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
          print(body);
        }

        String notifyTitle = 'COOL SERVICE';
        String notifyBody = 'Awesome ${DateTime.now()}\n$lat,$lon $country';

        flutterLocalNotificationsPlugin.show(
          888,
          notifyTitle,
          notifyBody,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              '前景自動定位',
              icon: '@mipmap/ic_launcher',
              ongoing: true,
            ),
          ),
        );

        service.setForegroundNotificationInfo(
          title: notifyTitle,
          content: notifyBody,
        );
      }
    }

    task();
    timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      task();
    });
  }
}
