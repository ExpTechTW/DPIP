import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/services.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Background location service with one-shot foreground runs triggered by AlarmManager.
///
/// Flow:
///  Alarm -> AndroidAlarmManager triggers LocationService._$task()
///  _$task():
///    - start native foreground service (notification shown by native)
///    - perform a single location update & upload
///    - stop native foreground service (notification removed)
///    - reschedule next alarm
class LocationServiceManager {
  LocationServiceManager._();

  static const int kAlarmId = 888888;
  static const int kNotificationId = 888999; // 前景服務通知 ID (native 使用)
  static const String _kPrefKeyUpdateInterval = 'location_update_interval';

  static const Duration kMinUpdateInterval = Duration(minutes: 5);
  static const Duration kMaxUpdateInterval = Duration(minutes: 60);
  static const Duration kDefaultUpdateInterval = Duration(minutes: 10);

  static const double kHighMovementThreshold = 1000;
  static const double kLowMovementThreshold = 100;

  /// 原生 method channel，用於啟動 / 停止前景服務（Kotlin 實作）
  static const platform = MethodChannel('com.exptech.dpip/location');

  static bool get available => Platform.isAndroid || Platform.isIOS;

  /// 初始化：只在 Android 平台（iOS 有另外處理）
  static Future<void> initalize() async {
    if (!Platform.isAndroid) return;

    if (Preference.locationAuto != true) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    try {
      await stop();
      await AndroidAlarmManager.initialize();
      // 先執行一次 task（跟你原本一樣，讓第一次更新立刻進行）
      await LocationService._$task();
      // 再排週期
      await start();
    } catch (e, s) {
      TalkerManager.instance.error('👷 location service initialization failed', e, s);
    }
  }

  static Duration _getUpdateInterval() {
    final minutes = Preference.instance.getInt(_kPrefKeyUpdateInterval);
    return minutes != null ? Duration(minutes: minutes) : kDefaultUpdateInterval;
  }

  static Future<void> _setUpdateInterval(Duration interval) async {
    await Preference.instance.setInt(_kPrefKeyUpdateInterval, interval.inMinutes);
  }

  static Duration _calculateNextInterval(double? distanceInMeters) {
    if (distanceInMeters == null) return kDefaultUpdateInterval;
    if (distanceInMeters >= kHighMovementThreshold) return kMinUpdateInterval;
    if (distanceInMeters >= kLowMovementThreshold) return kDefaultUpdateInterval;

    final currentInterval = _getUpdateInterval();
    final newInterval = Duration(minutes: currentInterval.inMinutes + 5);
    return newInterval > kMaxUpdateInterval ? kMaxUpdateInterval : newInterval;
  }

  /// Start the scheduling (does NOT start a long-running foreground service).
  ///
  /// It schedules the first Alarm (exact preferred; fallback to inexact).
  static Future<void> start() async {
    if (!available) return;
    try {
      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': true});
        return;
      }

      await AndroidAlarmManager.cancel(kAlarmId);
      await _setUpdateInterval(kDefaultUpdateInterval);
      try {
        await AndroidAlarmManager.oneShot(
          kDefaultUpdateInterval,
          kAlarmId,
          LocationService._$task,
          wakeup: true,
          exact: true,
          rescheduleOnReboot: true,
        );
      } catch (_) {
        await AndroidAlarmManager.oneShot(
          kDefaultUpdateInterval,
          kAlarmId,
          LocationService._$task,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      }
    } catch (e, s) {
      TalkerManager.instance.error('👷 start failed', e, s);
    }
  }

  /// Internal helper to reschedule next alarm for interval.
  static Future<void> _rescheduleAlarm(Duration interval) async {
    try {
      await AndroidAlarmManager.cancel(kAlarmId);
      await AndroidAlarmManager.oneShot(
        interval,
        kAlarmId,
        LocationService._$task,
        wakeup: true,
        exact: true,
        rescheduleOnReboot: true,
      );
    } catch (e, s) {
      TalkerManager.instance.error('👷 reschedule exact failed', e, s);
      await AndroidAlarmManager.oneShot(
        interval,
        kAlarmId,
        LocationService._$task,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    }
  }

  /// Stop whole scheduling and ensure foreground service is stopped.
  static Future<void> stop() async {
    if (!available) return;
    try {
      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': false});
        return;
      }

      await AndroidAlarmManager.cancel(kAlarmId);
      // 停止前景服務（若有在跑）
      try {
        await platform.invokeMethod('stopForegroundService');
      } catch (e, s) {
        // 忽略 native 停止失敗
        TalkerManager.instance.error('👷 stopForegroundService failed', e, s);
      }
      // 清理 Dart-side notifications（若你有用 awesome 建立過）
      try {
        await AwesomeNotifications().dismiss(kNotificationId);
      } catch (_) {}
    } catch (e, s) {
      TalkerManager.instance.error('👷 stopping location service FAILED', e, s);
    }
  }
}

@pragma('vm:entry-point')
class LocationService {
  LocationService._();

  static LatLng? _$location;
  static GeoJSONFeatureCollection? _$geoJsonData;
  static Map<String, Location>? _$locationData;

  /// This is the entry point for AlarmManager -> this task runs once,
  /// then it stops the native foreground service and reschedules the next alarm.
  @pragma('vm:entry-point')
  static Future<void> _$task() async {
    // We ensure native foreground service is started, perform one-shot update,
    // then stop native foreground service and reschedule next alarm.
    try {
      DartPluginRegistrant.ensureInitialized();

      await Preference.init();
      await AppLocalizations.load();
      await LocationNameLocalizations.load();

      try {
        final _ = Global.packageInfo;
      } catch (_) {
        Global.packageInfo = await PackageInfo.fromPlatform();
      }

      if (Preference.locationAuto != true) {
        await LocationServiceManager.stop();
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        TalkerManager.instance.warning(
          '⚙️::BackgroundLocationService location permission not granted, stopping service',
        );
        await LocationServiceManager.stop();
        return;
      }

      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        TalkerManager.instance.warning(
          '⚙️::BackgroundLocationService location service is disabled, skipping this update',
        );
        // reschedule next (use default interval)
        await LocationServiceManager._rescheduleAlarm(LocationServiceManager.kDefaultUpdateInterval);
        return;
      }

      // ---------- Start native foreground service (notification shown by native) ----------
      try {
        await LocationServiceManager.platform.invokeMethod('startForegroundService');
      } catch (e, s) {
        TalkerManager.instance.error('⚙️ failed to start native foreground service', e, s);
        // 無法啟動 native 前景服務仍繼續嘗試，但要注意後續 stop 可能失敗
      }

      // Load resources (geojson, location data)
      _$geoJsonData ??= await Global.loadTownGeojson();
      _$locationData ??= await Global.loadLocationData();

      // Try to get coordinates
      final coordinates = await _$getDeviceGeographicalLocation();
      if (coordinates == null) {
        await _$updatePosition(null);
        // Stop native foreground service and reschedule
        try {
          await LocationServiceManager.platform.invokeMethod('stopForegroundService');
        } catch (_) {}
        await LocationServiceManager._rescheduleAlarm(LocationServiceManager.kDefaultUpdateInterval);
        return;
      }

      final previousLocation = _$location;
      final distanceInMeters = previousLocation != null ? coordinates.to(previousLocation) : null;

      final nextInterval = LocationServiceManager._calculateNextInterval(distanceInMeters);
      await LocationServiceManager._setUpdateInterval(nextInterval);

      // Update position locally
      await _$updatePosition(coordinates);

      // Upload to server if token exists
      final fcmToken = Preference.notifyToken;
      if (fcmToken.isNotEmpty) {
        try {
          await ExpTech().updateDeviceLocation(token: fcmToken, coordinates: coordinates);
          TalkerManager.instance.info('⚙️::BackgroundLocationService location updated on server');
        } catch (e, s) {
          TalkerManager.instance.error('⚙️::BackgroundLocationService failed to update location on server', e, s);
        }
      }

      // Reschedule next alarm based on computed nextInterval
      await LocationServiceManager._rescheduleAlarm(nextInterval);

      TalkerManager.instance.info(
        '⚙️::BackgroundLocationService next update in ${nextInterval.inMinutes}min (distance: ${distanceInMeters?.toStringAsFixed(0) ?? "unknown"}m)',
      );

      // ---------- Done: stop native foreground service (notification removed) ----------
      try {
        await LocationServiceManager.platform.invokeMethod('stopForegroundService');
      } catch (e, s) {
        TalkerManager.instance.error('⚙️ failed to stop native foreground service', e, s);
      }
    } catch (e, s) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService task FAILED', e, s);

      // ensure we attempt to reschedule next alarm
      try {
        await LocationServiceManager._rescheduleAlarm(LocationServiceManager.kDefaultUpdateInterval);
      } catch (_) {}

      // ensure native service is stopped if something failed
      try {
        await LocationServiceManager.platform.invokeMethod('stopForegroundService');
      } catch (_) {}
    }
  }

  static ({String code, Location location})? _$getLocationFromCoordinates(LatLng target) {
    final geoJsonData = _$geoJsonData;
    final locationData = _$locationData;

    if (geoJsonData == null || locationData == null) return null;

    final features = geoJsonData.features;

    for (final feature in features) {
      if (feature == null) continue;

      final geometry = feature.geometry;
      if (geometry == null) continue;

      bool isInPolygon = false;

      if (geometry is GeoJSONPolygon) {
        final polygon = geometry.coordinates[0];

        bool isInside = false;
        int j = polygon.length - 1;
        for (int i = 0; i < polygon.length; i++) {
          final double xi = polygon[i][0];
          final double yi = polygon[i][1];
          final double xj = polygon[j][0];
          final double yj = polygon[j][1];

          final bool intersect =
              ((yi > target.latitude) != (yj > target.latitude)) &&
              (target.longitude < (xj - xi) * (target.latitude - yi) / (yj - yi) + xi);
          if (intersect) isInside = !isInside;

          j = i;
        }
        isInPolygon = isInside;
      }

      if (geometry is GeoJSONMultiPolygon) {
        final multiPolygon = geometry.coordinates;

        for (final polygonCoordinates in multiPolygon) {
          final polygon = polygonCoordinates[0];

          bool isInside = false;
          int j = polygon.length - 1;
          for (int i = 0; i < polygon.length; i++) {
            final double xi = polygon[i][0];
            final double yi = polygon[i][1];
            final double xj = polygon[j][0];
            final double yj = polygon[j][1];

            final bool intersect =
                ((yi > target.latitude) != (yj > target.latitude)) &&
                (target.longitude < (xj - xi) * (target.latitude - yi) / (yj - yi) + xi);
            if (intersect) isInside = !isInside;

            j = i;
          }

          if (isInside) {
            isInPolygon = true;
            break;
          }
        }
      }

      if (isInPolygon) {
        final code = feature.properties!['CODE']?.toString();
        if (code == null) return null;

        final location = locationData[code];
        if (location == null) return null;

        return (code: code, location: location);
      }
    }

    return null;
  }

  @pragma('vm:entry-point')
  static Future<void> _$updatePosition(LatLng? position) async {
    _$location = position;

    final result = position != null ? _$getLocationFromCoordinates(position) : null;

    Preference.locationCode = result?.code;
    Preference.locationLatitude = position?.latitude;
    Preference.locationLongitude = position?.longitude;
  }

  @pragma('vm:entry-point')
  static Future<LatLng?> _$getDeviceGeographicalLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      TalkerManager.instance.warning('⚙️::BackgroundLocationService location permission not granted');
      return null;
    }

    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      TalkerManager.instance.warning('⚙️::BackgroundLocationService location service is not available');
      return null;
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 10 && lastKnown.accuracy <= 500) {
          return LatLng(lastKnown.latitude, lastKnown.longitude);
        }
      }
    } catch (_) {}

    try {
      final lowAccuracyPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );

      if (lowAccuracyPosition.accuracy <= 500) {
        return LatLng(lowAccuracyPosition.latitude, lowAccuracyPosition.longitude);
      }
    } catch (_) {}

    try {
      final mediumAccuracyPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
      );

      return LatLng(mediumAccuracyPosition.latitude, mediumAccuracyPosition.longitude);
    } catch (_) {}

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 30)),
      );

      return LatLng(currentPosition.latitude, currentPosition.longitude);
    } catch (e) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService all location strategies failed', e);
      return null;
    }
  }
}
