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

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/datetime.dart';
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

  /// Preference keys for storing location update intervals
  static const String _kPrefKeyUpdateInterval = 'location_update_interval';
  static const String _kPrefKeyLastDistance = 'location_last_distance';
  static const String _kPrefKeyShowNotification = 'location_show_notification';

  /// Dynamic update intervals based on movement
  static const Duration kMinUpdateInterval = Duration(minutes: 5);     // 最小間隔：5分鐘
  static const Duration kMaxUpdateInterval = Duration(hours: 2);       // 最大間隔：2小時
  static const Duration kDefaultUpdateInterval = Duration(minutes: 10); // 預設間隔：10分鐘

  /// Distance thresholds for interval adjustment (in meters)
  static const double kHighMovementThreshold = 1000;  // 移動超過1km，認為是高移動
  static const double kLowMovementThreshold = 100;    // 移動少於100m，認為是低移動

  /// Whether to show notification (default: false for silent mode)
  static bool get showNotification => Preference.instance.getBool(_kPrefKeyShowNotification) ?? false;
  static set showNotification(bool value) => Preference.instance.setBool(_kPrefKeyShowNotification, value);

  /// Platform channel for iOS
  static const platform = MethodChannel('com.exptech.dpip/location');

  /// Whether the background service is available on the current platform
  static bool get avaliable => Platform.isAndroid || Platform.isIOS;

  /// Initializes the background location service.
  ///
  /// Sets up the AlarmManager for periodic location updates.
  ///
  /// Will start the service if automatic location updates are enabled.
  ///
  /// **Important**: This method should be called on every app startup to ensure
  /// the alarm is restored after device reboot (as rescheduleOnReboot may not
  /// be reliable on all devices).
  static Future<void> initalize() async {
    if (!Platform.isAndroid) return;

    TalkerManager.instance.info('👷 initializing location service');

    // Log all available GPS accuracy types
    await _logAvailableAccuracyTypes();

    try {
      await AndroidAlarmManager.initialize();
      TalkerManager.instance.info('👷 service initialized');
    } catch (e, s) {
      TalkerManager.instance.error('👷 initializing location service FAILED', e, s);
    }

    // Always attempt to restore the alarm if location auto is enabled
    // This ensures the service continues after device reboot
    if (Preference.locationAuto == true) {
      TalkerManager.instance.info('👷 location auto is enabled, ensuring alarm is scheduled');
      await start();
    }
  }

  /// Logs all available GPS accuracy types and their capabilities
  static Future<void> _logAvailableAccuracyTypes() async {
    TalkerManager.instance.info('👷 === GPS Accuracy Types Info ===');

    // Check location service status
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    TalkerManager.instance.info('👷 Location service enabled: $isLocationEnabled');

    if (!isLocationEnabled) {
      TalkerManager.instance.warning('👷 Location service is disabled, cannot test accuracy types');
      TalkerManager.instance.info('👷 === End GPS Accuracy Types Info ===');
      return;
    }

    // Check and request permissions if needed
    LocationPermission permission = await Geolocator.checkPermission();
    TalkerManager.instance.info('👷 Location permission status: $permission');

    if (permission == LocationPermission.denied) {
      TalkerManager.instance.info('👷 Requesting location permission...');
      permission = await Geolocator.requestPermission();
      TalkerManager.instance.info('👷 Permission request result: $permission');
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      TalkerManager.instance.warning('👷 Location permission not granted, cannot test accuracy types');
      TalkerManager.instance.info('👷 === End GPS Accuracy Types Info ===');
      return;
    }

    // Test only the accuracy levels we actually use in production
    final accuracyTypes = {
      'low': LocationAccuracy.low,
      'medium': LocationAccuracy.medium,
    };

    TalkerManager.instance.info('👷 Testing accuracy types used in production...');

    for (final entry in accuracyTypes.entries) {
      final name = entry.key;
      final accuracy = entry.value;

      try {
        TalkerManager.instance.info('👷 Testing: $name ($accuracy)');

        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            timeLimit: const Duration(seconds: 10),
          ),
        ).timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException('Timeout after 12s'),
        );

        TalkerManager.instance.info(
          '👷   ✓ $name: SUCCESS - accuracy=${position.accuracy.toStringAsFixed(1)}m, '
          'lat=${position.latitude.toStringAsFixed(6)}, lng=${position.longitude.toStringAsFixed(6)}, '
          'speed=${position.speed.toStringAsFixed(1)}m/s, altitude=${position.altitude.toStringAsFixed(1)}m',
        );
      } on TimeoutException catch (e) {
        TalkerManager.instance.warning('👷   ⏱ $name: TIMEOUT - $e');
      } on PermissionDeniedException {
        TalkerManager.instance.error('👷   ✗ $name: PERMISSION_DENIED');
        break; // No point testing other accuracy levels
      } catch (e) {
        final errorType = e.runtimeType;
        TalkerManager.instance.warning('👷   ✗ $name: FAILED - $errorType: $e');
      }

      // Add small delay between tests to avoid overwhelming the GPS
      await Future.delayed(const Duration(milliseconds: 500));
    }

    TalkerManager.instance.info('👷 === End GPS Accuracy Types Info ===');
  }

  // ==================== Private Helper Methods ====================

  /// Gets the current update interval from SharedPreferences.
  static Duration _getUpdateInterval() {
    final minutes = Preference.instance.getInt(_kPrefKeyUpdateInterval);
    return minutes != null ? Duration(minutes: minutes) : kDefaultUpdateInterval;
  }

  /// Saves the update interval to SharedPreferences.
  static Future<void> _setUpdateInterval(Duration interval) async {
    await Preference.instance.setInt(_kPrefKeyUpdateInterval, interval.inMinutes);
  }

  /// Stores the last movement distance for debugging purposes.
  static Future<void> _setLastDistance(double distance) async {
    await Preference.instance.setDouble(_kPrefKeyLastDistance, distance);
  }

  /// Calculates the next update interval based on movement distance.
  ///
  /// Strategy:
  /// - **High movement** (≥1000m): 5 minutes - Fast updates for moving users
  /// - **Medium movement** (100m-1000m): 10 minutes - Balanced updates for walking
  /// - **Low movement** (<100m): Gradually increase to 2 hours - Battery saving for stationary users
  static Duration _calculateNextInterval(double? distanceInMeters) {
    if (distanceInMeters == null) return kDefaultUpdateInterval;

    if (distanceInMeters >= kHighMovementThreshold) {
      return kMinUpdateInterval; // High movement: 5 min
    }

    if (distanceInMeters >= kLowMovementThreshold) {
      return kDefaultUpdateInterval; // Medium movement: 10 min
    }

    // Low movement: Gradually increase interval
    final currentInterval = _getUpdateInterval();
    final newInterval = Duration(minutes: currentInterval.inMinutes + 10);
    return newInterval > kMaxUpdateInterval ? kMaxUpdateInterval : newInterval;
  }

  /// Starts the background location service.
  ///
  /// Schedules the first alarm with default interval. Subsequent alarms will be dynamically adjusted.
  ///
  /// **Note**: On Android 12+, the SCHEDULE_EXACT_ALARM permission is required.
  /// If the permission is not granted, the alarm may not fire at the exact time,
  /// but will still work with less precision.
  static Future<void> start() async {
    if (!avaliable) return;

    TalkerManager.instance.info('👷 starting location service');

    try {
      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': true});
        return;
      }

      // Cancel any existing alarm first to avoid duplicates
      await AndroidAlarmManager.cancel(kAlarmId);

      // Reset to default interval on start
      await _setUpdateInterval(kDefaultUpdateInterval);

      // Schedule one-time alarm with default interval
      // The task will reschedule itself dynamically based on movement
      // Note: If SCHEDULE_EXACT_ALARM permission is not granted (Android 12+),
      // the alarm will still work but with less precision
      await AndroidAlarmManager.oneShot(
        kDefaultUpdateInterval,
        kAlarmId,
        LocationService._$task,
        wakeup: true,
        exact: true,
        rescheduleOnReboot: true,
      );

      TalkerManager.instance.info('👷 location service started with ${kDefaultUpdateInterval.inMinutes}min interval');
    } catch (e, s) {
      TalkerManager.instance.error('👷 starting location service FAILED', e, s);

      // If exact alarm fails, try with inexact alarm as fallback
      if (e.toString().contains('SCHEDULE_EXACT_ALARM')) {
        TalkerManager.instance.warning('👷 exact alarm permission not granted, trying inexact alarm');
        try {
          await AndroidAlarmManager.oneShot(
            kDefaultUpdateInterval,
            kAlarmId,
            LocationService._$task,
            wakeup: true,
            rescheduleOnReboot: true,
            // exact: false is the default, so omitted
          );
          TalkerManager.instance.info('👷 location service started with inexact alarm');
        } catch (e2, s2) {
          TalkerManager.instance.error('👷 starting inexact alarm also FAILED', e2, s2);
        }
      }
    }
  }

  /// Reschedules the next alarm with the specified interval.
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

      TalkerManager.instance.info('👷 rescheduled alarm with ${interval.inMinutes}min interval');
    } catch (e, s) {
      TalkerManager.instance.error('👷 rescheduling alarm FAILED', e, s);
    }
  }

  /// Stops the background location service by canceling the periodic alarm.
  static Future<void> stop() async {
    if (!avaliable) return;

    TalkerManager.instance.info('👷 stopping location service');

    try {
      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': false});
        return;
      }

      await AndroidAlarmManager.cancel(kAlarmId);

      // Dismiss notification
      await AwesomeNotifications().dismiss(kNotificationId);

      TalkerManager.instance.info('👷 location service stopped');
    } catch (e, s) {
      TalkerManager.instance.error('👷 stopping location service FAILED', e, s);
    }
  }

}

/// The background location service.
///
/// This service is used to get the current location of the device in the background using AlarmManager.
///
/// All property prefixed with `_$` are isolated from the main app.
@pragma('vm:entry-point')
class LocationService {
  LocationService._();

  /// The last known location coordinates
  static LatLng? _$location;

  /// Cached GeoJSON data for location lookups
  static GeoJSONFeatureCollection? _$geoJsonData;

  /// Cached location data mapping
  static Map<String, Location>? _$locationData;

  /// The main task function that gets called periodically by AlarmManager.
  ///
  /// Gets the current location of the device and updates preferences and notification.
  @pragma('vm:entry-point')
  static Future<void> _$task() async {
    try {
      DartPluginRegistrant.ensureInitialized();

      await Preference.init();
      await AppLocalizations.load();
      await LocationNameLocalizations.load();

      if (Preference.locationAuto != true) {
        await LocationServiceManager.stop();
        return;
      }

      // Check location permission before attempting to get GPS
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        TalkerManager.instance.warning('⚙️::BackgroundLocationService location permission not granted, stopping service');
        await LocationServiceManager.stop();
        return;
      }

      // Check if location service is enabled
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        TalkerManager.instance.warning('⚙️::BackgroundLocationService location service is disabled, skipping this update');
        // Don't stop the service, just skip this update (user might enable GPS later)
        await LocationServiceManager._rescheduleAlarm(LocationServiceManager.kDefaultUpdateInterval);
        return;
      }

      // Show silent notification to indicate processing
      await _$showProcessingNotification();

      // Load data if not already loaded
      _$geoJsonData ??= await Global.loadTownGeojson();
      _$locationData ??= await Global.loadLocationData();

      // Get current position and location info
      final coordinates = await _$getDeviceGeographicalLocation();

      if (coordinates == null) {
        await _$updatePosition(null);
        // Dismiss notification after processing
        await _$dismissNotification();
        return;
      }

      final previousLocation = _$location;

      final distanceInMeters = previousLocation != null ? coordinates.to(previousLocation) : null;

      // Calculate and schedule next update based on movement
      final nextInterval = LocationServiceManager._calculateNextInterval(distanceInMeters);
      await LocationServiceManager._setUpdateInterval(nextInterval);

      // Store distance for interval calculation
      if (distanceInMeters != null) {
        await LocationServiceManager._setLastDistance(distanceInMeters);
      }

      if (distanceInMeters == null || distanceInMeters >= 250) {
        await _$updatePosition(coordinates, nextUpdateIn: nextInterval);
      } else {
        // Still update notification with next update time even if position hasn't changed significantly
        await _$updatePosition(coordinates, nextUpdateIn: nextInterval);
      }

      // Update device location on server (directly from background isolate)
      final fcmToken = Preference.notifyToken;
      if (fcmToken.isNotEmpty) {
        try {
          await ExpTech().updateDeviceLocation(token: fcmToken, coordinates: coordinates);
          TalkerManager.instance.info('⚙️::BackgroundLocationService location updated on server');
        } catch (e, s) {
          TalkerManager.instance.error('⚙️::BackgroundLocationService failed to update location on server', e, s);
        }
      }

      // Reschedule the alarm with the calculated interval
      await LocationServiceManager._rescheduleAlarm(nextInterval);

      TalkerManager.instance.info(
        '⚙️::BackgroundLocationService next update in ${nextInterval.inMinutes}min (distance: ${distanceInMeters?.toStringAsFixed(0) ?? "unknown"}m)',
      );

      // Dismiss notification after processing
      await _$dismissNotification();
    } catch (e, s) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService task FAILED', e, s);

      // Dismiss notification on error
      await _$dismissNotification();

      // On error, retry with default interval
      try {
        await LocationServiceManager._rescheduleAlarm(LocationServiceManager.kDefaultUpdateInterval);
      } catch (_) {
        // Ignore reschedule errors
      }
    }
  }

  /// Shows a silent notification to indicate GPS processing.
  ///
  /// This notification is completely silent (no sound, no vibration) and will be
  /// automatically dismissed after GPS processing completes.
  @pragma('vm:entry-point')
  static Future<void> _$showProcessingNotification() async {
    try {
      // Note: The 'background' channel must be configured with enableSound: false
      // and enableVibration: false to ensure completely silent notifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: LocationServiceManager.kNotificationId,
          channelKey: 'background',  // Must be a silent channel
          title: '正在更新位置'.i18n,
          body: '取得 GPS 位置中...',
          icon: 'resource://drawable/ic_stat_name',
          badge: 0,
        ),
      );
    } catch (e, s) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService failed to show notification', e, s);
    }
  }

  /// Dismisses the GPS processing notification.
  @pragma('vm:entry-point')
  static Future<void> _$dismissNotification() async {
    try {
      // Try both dismiss and cancel to ensure notification is removed
      // dismiss() removes from notification tray
      await AwesomeNotifications().dismiss(LocationServiceManager.kNotificationId);

      // cancel() removes from scheduled notifications (backup method)
      await AwesomeNotifications().cancel(LocationServiceManager.kNotificationId);

      // On some devices (like Pixel), we need to also dismiss all notifications in the channel
      // as a workaround for sticky notifications
      await AwesomeNotifications().dismissNotificationsByChannelKey('background');
    } catch (e, s) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService failed to dismiss notification', e, s);
    }
  }

  /// Gets the current geographical location of the device using a smart, battery-efficient strategy.
  ///
  /// **Multi-tier location strategy** (from most to least battery-efficient):
  /// 1. **Last Known Position** - Uses cached location (0% battery cost)
  /// 2. **Low Accuracy** - Network-based location (minimal battery, ~100-500m accuracy)
  /// 3. **Medium Accuracy** - Balanced GPS + Network (~10-100m accuracy)
  /// 4. **High Accuracy** - Full GPS (highest battery, ~5-10m accuracy)
  ///
  /// The strategy progressively falls back to higher accuracy only when:
  /// - Previous method fails or times out
  /// - Previous result is too old or inaccurate
  ///
  /// Returns null if location services are disabled or all attempts fail.
  @pragma('vm:entry-point')
  static Future<LatLng?> _$getDeviceGeographicalLocation() async {
    // Check permission first (this shouldn't fail since we check in _$task, but double-check for safety)
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      TalkerManager.instance.warning('⚙️::BackgroundLocationService location permission not granted');
      return null;
    }

    // Check if location service is enabled
    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      TalkerManager.instance.warning('⚙️::BackgroundLocationService location service is not available');
      return null;
    }

    // Strategy 1: Try last known position first (FREE - no battery cost!)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // Check if last known position is recent enough (< 10 minutes old)
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 10 && lastKnown.accuracy <= 500) {
          return LatLng(lastKnown.latitude, lastKnown.longitude);
        }
      }
    } catch (e) {
      // Last known position unavailable, continue to next strategy
    }

    // Strategy 2: Try low accuracy (network-based) with timeout
    // This uses WiFi/Cell towers - very battery efficient
    try {
      final lowAccuracyPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // If accuracy is good enough (< 500m), use it
      if (lowAccuracyPosition.accuracy <= 500) {
        return LatLng(lowAccuracyPosition.latitude, lowAccuracyPosition.longitude);
      }
    } catch (e) {
      // Low accuracy failed, continue to next strategy
    }

    // Strategy 3: Fall back to medium accuracy (balanced GPS + Network)
    // Only use if low accuracy failed or was too inaccurate
    try {
      final mediumAccuracyPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LatLng(mediumAccuracyPosition.latitude, mediumAccuracyPosition.longitude);
    } catch (e) {
      // Medium accuracy failed, continue to last resort
    }

    // Strategy 4: Last resort - high accuracy GPS (most battery intensive)
    // Only reached if all previous strategies failed
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      return LatLng(currentPosition.latitude, currentPosition.longitude);
    } catch (e) {
      TalkerManager.instance.error('⚙️::BackgroundLocationService all location strategies failed', e);
      return null;
    }
  }

  /// Gets the location code for given coordinates by checking if they fall within polygon boundaries.
  ///
  /// Takes a target LatLng and checks if it falls within any polygon in the GeoJSON data. Returns the location code if
  /// found, null otherwise.
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

  /// Updates the current position.
  ///
  /// Saves the new position to preferences and optionally updates the notification.
  @pragma('vm:entry-point')
  static Future<void> _$updatePosition(LatLng? position, {Duration? nextUpdateIn}) async {
    _$location = position;

    final result = position != null ? _$getLocationFromCoordinates(position) : null;

    // Save position to preferences
    Preference.locationCode = result?.code;
    Preference.locationLatitude = position?.latitude;
    Preference.locationLongitude = position?.longitude;

    // Only show notification if enabled
    if (!LocationServiceManager.showNotification) {
      return;
    }

    // Build notification content
    final timestamp = DateTime.now().toDateTimeString();
    String locationText = '服務區域外'.i18n;

    if (position != null) {
      final latitude = position.latitude.toStringAsFixed(6);
      final longitude = position.longitude.toStringAsFixed(6);

      if (result != null) {
        locationText = '${result.location.cityWithLevel} ${result.location.townWithLevel} ($latitude, $longitude)';
      } else {
        locationText = '${'服務區域外'.i18n} ($latitude, $longitude)';
      }
    }

    // Add next update time if provided
    String content = locationText;
    if (nextUpdateIn != null) {
      content += '\n下次更新: ${nextUpdateIn.inMinutes}分鐘後';
    }

    // Create notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: LocationServiceManager.kNotificationId,
        channelKey: 'background',
        title: '自動定位中'.i18n,
        body: '$timestamp\n$content',
        icon: 'resource://drawable/ic_stat_name',
        badge: 0,
      ),
    );
  }
}
