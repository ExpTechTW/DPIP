import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dpip/core/i18n.dart';
import 'package:flutter/services.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/log.dart';

/// Background location service.
///
/// This class is responsible for managing the background location service using AlarmManager.
class LocationServiceManager {
  LocationServiceManager._();

  /// The alarm ID used for periodic location updates
  static const int kAlarmId = 888888;

  /// The notification ID used for location updates notification
  static const int kNotificationId = 888888;

  static const String _kPrefKeyUpdateInterval = 'location_update_interval';

  static const Duration kMinUpdateInterval = Duration(minutes: 5);
  static const Duration kMaxUpdateInterval = Duration(minutes: 60);
  static const Duration kDefaultUpdateInterval = Duration(minutes: 10);

  static const double kHighMovementThreshold = 1000;
  static const double kLowMovementThreshold = 100;

  /// Platform channel for iOS
  static const platform = MethodChannel('com.exptech.dpip/location');

  /// Whether the background service is available on the current platform
  static bool get available => Platform.isAndroid || Platform.isIOS;

  static Future<void> initalize() async {
    if (!Platform.isAndroid) return;

    if (Preference.locationAuto != true) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      await AndroidAlarmManager.initialize();
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

    if (distanceInMeters >= kHighMovementThreshold) {
      return kMinUpdateInterval;
    }

    if (distanceInMeters >= kLowMovementThreshold) {
      return kDefaultUpdateInterval;
    }

    final currentInterval = _getUpdateInterval();
    final newInterval = Duration(minutes: currentInterval.inMinutes + 5);
    return newInterval > kMaxUpdateInterval ? kMaxUpdateInterval : newInterval;
  }

  static Future<void> start() async {
    if (!available) return;

    try {
      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': true});
        return;
      }

      await AndroidAlarmManager.cancel(kAlarmId);
      await _setUpdateInterval(kDefaultUpdateInterval);

      await AndroidAlarmManager.oneShot(
        kDefaultUpdateInterval,
        kAlarmId,
        LocationService._$task,
        wakeup: true,
        exact: true,
        rescheduleOnReboot: true,
      );
    } catch (e, s) {
      TalkerManager.instance.error('👷 starting location service FAILED', e, s);

      if (e.toString().contains('SCHEDULE_EXACT_ALARM')) {
        try {
          await AndroidAlarmManager.oneShot(
            kDefaultUpdateInterval,
            kAlarmId,
            LocationService._$task,
            wakeup: true,
            rescheduleOnReboot: true,
          );
        } catch (e2, s2) {
          TalkerManager.instance.error('👷 starting inexact alarm also FAILED', e2, s2);
        }
      }
    }
  }

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
      TalkerManager.instance.error('👷 rescheduling alarm FAILED', e, s);
    }
  }

  static Future<void> stop() async {
    if (!available) return;

    try {
      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': false});
        return;
      }

      await AndroidAlarmManager.cancel(kAlarmId);
      await AwesomeNotifications().dismiss(kNotificationId);
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

  @pragma('vm:entry-point')
  static Future<void> _$task() async {
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
        await LocationServiceManager._rescheduleAlarm(LocationServiceManager.kDefaultUpdateInterval);
        return;
      }

      await _$showProcessingNotification();

      _$geoJsonData ??= await Global.loadTownGeojson();
      _$locationData ??= await Global.loadLocationData();
      final coordinates = await _$getDeviceGeographicalLocation();

      if (coordinates == null) {
        await _$updatePosition(null);
        await _$dismissNotification();
        return;
      }

      final previousLocation = _$location;
      final distanceInMeters = previousLocation != null ? coordinates.to(previousLocation) : null;

      final nextInterval = LocationServiceManager._calculateNextInterval(distanceInMeters);
      await LocationServiceManager._setUpdateInterval(nextInterval);

      await _$updatePosition(coordinates);

      final fcmToken = Preference.notifyToken;
      if (fcmToken.isNotEmpty) {
        try {
          await ExpTech().updateDeviceLocation(token: fcmToken, coordinates: coordinates);
          TalkerManager.instance.info('⚙️::BackgroundLocationService location updated on server');
        } catch (e, s) {
          TalkerManager.instance.error('⚙️::BackgroundLocationService failed to update location on server', e, s);
        }
      }

      await LocationServiceManager._rescheduleAlarm(nextInterval);

      TalkerManager.instance.info(
        '⚙️::BackgroundLocationService next update in ${nextInterval.inMinutes}min (distance: ${distanceInMeters?.toStringAsFixed(0) ?? "unknown"}m)',
      );

      await _$dismissNotification();
    } catch (e, s) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService task FAILED', e, s);

      await _$dismissNotification();

      try {
        await LocationServiceManager._rescheduleAlarm(LocationServiceManager.kDefaultUpdateInterval);
      } catch (_) {}
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _$showProcessingNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: LocationServiceManager.kNotificationId,
          channelKey: 'background',
          title: '正在更新位置'.i18n,
          body: '取得 GPS 位置中...'.i18n,
          icon: 'resource://drawable/ic_stat_name',
          badge: 0,
        ),
      );
    } catch (e, s) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService failed to show notification', e, s);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _$dismissNotification() async {
    try {
      await AwesomeNotifications().dismiss(LocationServiceManager.kNotificationId);
      await AwesomeNotifications().cancel(LocationServiceManager.kNotificationId);
      await AwesomeNotifications().dismissNotificationsByChannelKey('background');
    } catch (e, s) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService failed to dismiss notification', e, s);
    }
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
}
