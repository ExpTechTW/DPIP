import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app_old/page/home/home.dart';
import 'package:dpip/app_old/page/map/monitor/monitor.dart';
import 'package:dpip/app_old/page/map/radar/radar.dart';
import 'package:dpip/core/location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/location_to_code.dart';
import 'package:dpip/utils/log.dart';

Timer? timer;
FlutterBackgroundService service = FlutterBackgroundService();
bool androidServiceInit = false;

enum ServiceEvent { setAsForeground, setAsBackground, sendPosition, sendDebug, removePosition, stopService }

void initBackgroundService() async {
  bool isAutoLocatingEnabled = GlobalProviders.location.auto;
  if (!isAutoLocatingEnabled) {
    TalkerManager.instance.info('自動定位未啟用，不初始化背景服務');
    return;
  }

  final isNotificationEnabled = await Permission.notification.status;
  final isLocationAlwaysEnabled = await Permission.locationAlways.status;

  if (isNotificationEnabled.isGranted && isLocationAlwaysEnabled.isGranted) {
    if (!Platform.isAndroid) return;

    androidForegroundService();
    androidSendPositionlisten();
    androidStartBackgroundService(true);
  }
}

void androidStartBackgroundService(bool init) async {
  if (!androidServiceInit) {
    androidForegroundService();
    androidSendPositionlisten();
  }

  var isRunning = await service.isRunning();
  if (!isRunning) {
    service.startService();
  } else if (!init) {
    androidStopBackgroundService();
    service.startService();
  }
}

void androidStopBackgroundService() async {
  var isRunning = await service.isRunning();
  if (!isRunning) return;

  bool isAutoLocatingEnabled = GlobalProviders.location.auto;
  if (isAutoLocatingEnabled) {
    service.invoke(ServiceEvent.removePosition.name);
  }

  service.invoke(ServiceEvent.stopService.name);
}

void androidSendPositionlisten() {
  service.on(ServiceEvent.sendPosition.name).listen((event) {
    if (event != null) {
      double lat = event.values.first['lat'] ?? 0;
      double lng = event.values.first['lng'] ?? 0;

      GeoJsonProperties? location = GeoJsonHelper.checkPointInPolygons(lat, lng);

      GlobalProviders.location.setCode(location?.code.toString());
      GlobalProviders.location.setLatitude(lat);
      GlobalProviders.location.setLongitude(lng);

      const MonitorPage(data: 0).createState();

      HomePage.updatePosition();
      RadarMap.updatePosition();
      MonitorPage.updatePosition();
    }
  });
  service.on(ServiceEvent.sendDebug.name).listen((event) {
    if (event != null) {
      var notifyBody = event['notifyBody'];
      TalkerManager.instance.debug('自動定位: $notifyBody');
    }
  });
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
      foregroundServiceTypes: [AndroidForegroundType.location],
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'DPIP',
      initialNotificationContent: '前景服務啟動中...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart, onBackground: onIosBackground),
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
  // Initialize required services and dependencies
  await Global.init();
  await Preference.init();
  GlobalProviders.init();

  final locationService = LocationService();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Setup service event listeners
  service.on(ServiceEvent.stopService.name).listen((event) {
    timer?.cancel();
    if (service is AndroidServiceInstance) {
      service.setAutoStartOnBootMode(false);
    }
    service.stopSelf();
    TalkerManager.instance.info('背景服務已停止');
  });

  // Only proceed with Android-specific setup if this is an Android service
  if (service is AndroidServiceInstance) {
    // Initialize foreground service and notification
    await service.setAsForegroundService();
    await flutterLocalNotificationsPlugin.show(
      888,
      'DPIP',
      '前景服務啟動中...',
      const NotificationDetails(
        android: AndroidNotificationDetails('my_foreground', '前景自動定位', icon: '@mipmap/ic_launcher', ongoing: true),
      ),
    );

    service.setAutoStartOnBootMode(true);

    // Setup service state change listeners
    service.on(ServiceEvent.setAsForeground.name).listen((event) => service.setAsForegroundService());
    service.on(ServiceEvent.setAsBackground.name).listen((event) => service.setAsBackgroundService());
    service.on(ServiceEvent.removePosition.name).listen((event) {
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setLatitude(null);
      GlobalProviders.location.setLongitude(null);
    });

    // Define the periodic location update task
    void task() async {
      if (!await service.isForegroundService()) return;

      // Get current position and location info
      final position = await locationService.androidGetLocation();
      service.invoke(ServiceEvent.sendPosition.name, {'position': position.toJson()});

      final lat = position.lat.toString();
      final lon = position.lng.toString();
      final location =
          position.code == null
              ? '服務區域外'
              : '${Global.location[position.code.toString()]?.city}${Global.location[position.code.toString()]?.town}';

      // Handle FCM notification if position changed
      final fcmToken = Preference.notifyToken;
      if (position.change && fcmToken.isNotEmpty) {
        final body = await ExpTech().getNotifyLocation(token: fcmToken, lat: lat, lng: lon);
        TalkerManager.instance.debug(body);
      }

      // Update notification with current position
      final notifyTitle = '自動定位中';
      final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final notifyBody = '$date\n$lat,$lon $location';

      service.invoke(ServiceEvent.sendDebug.name, {'notifyBody': notifyBody});
      await flutterLocalNotificationsPlugin.show(
        888,
        notifyTitle,
        notifyBody,
        const NotificationDetails(
          android: AndroidNotificationDetails('my_foreground', '前景自動定位', icon: '@mipmap/ic_launcher', ongoing: true),
        ),
      );
      service.setForegroundNotificationInfo(title: notifyTitle, content: notifyBody);
    }

    // Start the periodic task
    task();
    timer = Timer.periodic(const Duration(minutes: 5), (timer) async => task());
  }
}
