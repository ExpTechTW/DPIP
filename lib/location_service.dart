import 'dart:async';
import 'dart:io';
import 'package:dpip/global.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? positionStreamSubscription;

  void startPositionStream() async {
    if (positionStreamSubscription == null) {
      final positionStream = geolocatorPlatform.getPositionStream(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.medium,
                distanceFilter: 500,
                forceLocationManager: false,
                intervalDuration: const Duration(minutes: 5),
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
                showBackgroundLocationIndicator: false,
                allowBackgroundLocationUpdates: true,
              ),
      );
      positionStreamSubscription = positionStream.handleError((error) async {
        await positionStreamSubscription?.cancel();
        positionStreamSubscription = null;
      }).listen((Position? position) {
        if (position != null) {
          String lat = position.latitude.toStringAsFixed(4);
          String lon = position.longitude.toStringAsFixed(4);
          String coordinate = '$lat,$lon';
          FirebaseMessaging.instance.getToken().then((value) {
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

  void stopPositionStream() async {
    if (positionStreamSubscription != null) {
      await positionStreamSubscription?.cancel();
      positionStreamSubscription = null;
      print('位置已停止');
    }
  }
}
