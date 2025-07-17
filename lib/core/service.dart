import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app_old/page/map/radar/radar.dart';
import 'package:dpip/core/location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/location_to_code.dart';
import 'package:dpip/utils/log.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:permission_handler/permission_handler.dart';

Timer? _locationUpdateTimer;
final _backgroundService = FlutterBackgroundService();
bool _isAndroidServiceInitialized = false;

enum ServiceEvent { setAsForeground, setAsBackground, sendPosition, sendDebug, removePosition, stopService }

Future<void> initBackgroundService() async {
  final isAutoLocationEnabled = GlobalProviders.location.auto;
  if (!isAutoLocationEnabled) {
    TalkerManager.instance.info('自動定位未啟用，不初始化背景服務');
    return;
  }

  final notificationPermission = await Permission.notification.status;
  final locationPermission = await Permission.locationAlways.status;

  if (notificationPermission.isGranted && locationPermission.isGranted) {
    if (!Platform.isAndroid) return;

    _initializeAndroidForegroundService();
    _setupPositionListener();
    startAndroidBackgroundService(shouldInitialize: true);
  }
}

Future<void> startAndroidBackgroundService({required bool shouldInitialize}) async {
  if (!_isAndroidServiceInitialized) {
    _initializeAndroidForegroundService();
    _setupPositionListener();
  }

  final isServiceRunning = await _backgroundService.isRunning();
  if (!isServiceRunning) {
    _backgroundService.startService();
  } else if (!shouldInitialize) {
    stopAndroidBackgroundService();
    _backgroundService.startService();
  }
}

Future<void> stopAndroidBackgroundService() async {
  final isServiceRunning = await _backgroundService.isRunning();
  if (!isServiceRunning) return;

  final isAutoLocationEnabled = GlobalProviders.location.auto;
  if (isAutoLocationEnabled) {
    _backgroundService.invoke(ServiceEvent.removePosition.name);
  }

  _backgroundService.invoke(ServiceEvent.stopService.name);
}

void _setupPositionListener() {
  _backgroundService.on(ServiceEvent.sendPosition.name).listen((event) {
    if (event == null) return;

    final result = GetLocationResult.fromJson(event);

    final latitude = result.lat ?? 0;
    final longitude = result.lng ?? 0;

    final location = GeoJsonHelper.checkPointInPolygons(latitude, longitude);

    GlobalProviders.location.setCode(location?.code.toString());
    GlobalProviders.location.setLatLng(latitude: latitude, longitude: longitude);

    RadarMap.updatePosition();
  });

  _backgroundService.on(ServiceEvent.sendDebug.name).listen((event) {
    if (event == null) return;

    final notificationBody = event['notifyBody'];
    TalkerManager.instance.debug('自動定位: $notificationBody');
  });
}

Future<void> _initializeAndroidForegroundService() async {
  _isAndroidServiceInitialized = true;

  await AwesomeNotifications().initialize(
    null, // 使用預設 launcher icon
    [
      NotificationChannel(
        channelKey: 'my_foreground',
        channelName: '前景自動定位',
        channelDescription: '背景定位服務通知',
        importance: NotificationImportance.Low,
        defaultColor: const Color(0xFF2196f3),
        ledColor: Colors.white,
        locked: true,
        playSound: false,
        onlyAlertOnce: true,
      )
    ],
  );

  await _backgroundService.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      isForegroundMode: true,
      foregroundServiceTypes: [AndroidForegroundType.location],
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'DPIP',
      initialNotificationContent: '前景服務啟動中...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(onForeground: _onServiceStart, onBackground: _onIosBackground),
  );
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
Future<void> _onServiceStart(ServiceInstance service) async {
  // Initialize required services and dependencies
  await Global.init();
  await Preference.init();
  GlobalProviders.init();

  final locationService = LocationService();

  // Setup service event listeners
  service.on(ServiceEvent.stopService.name).listen((event) {
    _locationUpdateTimer?.cancel();
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
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 888,
        channelKey: 'my_foreground',
        title: 'DPIP',
        body: '前景服務啟動中...',
        notificationLayout: NotificationLayout.Default,
        locked: true,
        autoDismissible: false,
        icon: 'resource://drawable/ic_stat_name',
      ),
    );

    service.setAutoStartOnBootMode(true);

    // Setup service state change listeners
    service.on(ServiceEvent.setAsForeground.name).listen((event) => service.setAsForegroundService());
    service.on(ServiceEvent.setAsBackground.name).listen((event) => service.setAsBackgroundService());
    service.on(ServiceEvent.removePosition.name).listen((event) {
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setLatLng();
    });

    // Define the periodic location update task
    Future<void> updateLocation() async {
      _locationUpdateTimer?.cancel();
      if (!await service.isForegroundService()) return;

      // Get current position and location info
      final position = await locationService.androidGetLocation();
      service.invoke(ServiceEvent.sendPosition.name, position.toJson());

      final latitude = position.lat.toString();
      final longitude = position.lng.toString();
      final locationName =
          position.code == null
              ? '服務區域外'
              : '${Global.location[position.code.toString()]?.city}${Global.location[position.code.toString()]?.town}';

      // Handle FCM notification if position changed
      final fcmToken = Preference.notifyToken;
      if (position.change && fcmToken.isNotEmpty) {
        final response = await ExpTech().updateDeviceLocation(token: fcmToken, lat: latitude, lng: longitude);
        TalkerManager.instance.debug(response);
      }

      // Update notification with current position
      const notificationTitle = '自動定位中';
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final notificationBody = '$timestamp\n$latitude,$longitude $locationName';

      service.invoke(ServiceEvent.sendDebug.name, {'notifyBody': notificationBody});
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 888,
          channelKey: 'my_foreground',
          title: notificationTitle,
          body: notificationBody,
          notificationLayout: NotificationLayout.Default,
          locked: true,
          autoDismissible: false,
        ),
      );
      service.setForegroundNotificationInfo(title: notificationTitle, content: notificationBody);

      final double dist = position.latlng.to(
        LatLng(GlobalProviders.location.oldLatitude ?? 0, GlobalProviders.location.oldLongitude ?? 0),
      );

      int time = 15;

      if (dist > 30) {
        time = 5;
      } else if (dist > 10) {
        time = 10;
      }

      GlobalProviders.location.setOldLongitude(position.lng);
      GlobalProviders.location.setOldLatitude(position.lat);

      _locationUpdateTimer = Timer.periodic(Duration(minutes: time), (timer) async => updateLocation());
    }

    // Start the periodic task
    updateLocation();
  }
}
