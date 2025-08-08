import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/log.dart';

class PositionEvent {
  final LatLng? coordinates;
  final String? code;

  PositionEvent(this.coordinates, this.code);

  factory PositionEvent.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List<dynamic>?;
    final code = json['code'] as String?;

    return PositionEvent(coordinates != null ? LatLng(coordinates[0] as double, coordinates[1] as double) : null, code);
  }

  Map<String, dynamic> toJson() {
    return {'coordinates': coordinates?.toJson(), 'code': code};
  }
}

/// Events emitted by the background service.
final class LocationServiceEvent {
  /// Event emitted when a new position is set in the background service.
  /// Contains the updated location coordinates.
  static const position = 'position';

  /// Method event to stop the service.
  static const stop = 'stop';
}

/// Background location service.
///
/// This class is responsible for managing the background location service.
/// It is used to handle start and stop the service.
class LocationServiceManager {
  LocationServiceManager._();

  /// The notification ID used for the background service notification
  static const kNotificationId = 888888;

  /// Instance of the background service
  static FlutterBackgroundService? instance;

  /// Platform channel for iOS
  static const platform = MethodChannel('com.exptech.dpip/location');

  /// Whether the background service is available on the current platform
  static bool get avaliable => Platform.isAndroid || Platform.isIOS;

  /// Initializes the background location service.
  ///
  /// Configures the service with Android specific settings.
  /// Sets up a listener for position updates that reloads preferences and updates device location.
  ///
  /// Will starts the service if automatic location updates are enabled.
  static Future<void> initalize() async {
    if (instance != null || !avaliable) return;

    TalkerManager.instance.info('👷 initializing location service');

    final service = FlutterBackgroundService();

    try {
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: LocationService._$onStart,
          autoStart: false,
          isForegroundMode: false,
          foregroundServiceTypes: [AndroidForegroundType.location],
          notificationChannelId: 'background',
          initialNotificationTitle: 'DPIP',
          initialNotificationContent: '正在初始化自動定位服務...',
          foregroundServiceNotificationId: kNotificationId,
        ),
        // iOS is handled in native code
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: LocationService._$onStartIOS,
          onBackground: LocationService._$onStartIOS,
        ),
      );

      // Reloads the UI isolate's preference cache when a new position is set in the background service.
      service.on(LocationServiceEvent.position).listen((data) async {
        final event = PositionEvent.fromJson(data!);

        try {
          TalkerManager.instance.info('👷 location updated by service, reloading preferences');

          await Preference.reload();
          GlobalProviders.location.refresh();

          // Handle FCM notification
          final fcmToken = Preference.notifyToken;
          if (fcmToken.isNotEmpty && event.coordinates != null) {
            await ExpTech().updateDeviceLocation(token: fcmToken, coordinates: event.coordinates!);
          }

          TalkerManager.instance.info('👷 preferences reloaded');
        } catch (e, s) {
          TalkerManager.instance.error('👷 failed to update location', e, s);
        }
      });

      instance = service;
      TalkerManager.instance.info('👷 service initialized');
    } catch (e, s) {
      TalkerManager.instance.error('👷 initializing location service FAILED', e, s);
    }

    if (Preference.locationAuto == true) await start();
  }

  /// Starts the background location service.
  ///
  /// Initializes the service if not already initialized. Only starts if the service is not already running.
  static Future<void> start() async {
    if (!avaliable) return;

    TalkerManager.instance.info('👷 starting location service');

    try {
      final service = instance;
      if (service == null) throw Exception('Not initialized.');

      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': true});
        return;
      }

      if (await service.isRunning()) {
        TalkerManager.instance.warning('👷 location service is already running, skipping...');
        return;
      }

      await service.startService();
    } catch (e, s) {
      TalkerManager.instance.error('👷 starting location service FAILED', e, s);
    }
  }

  /// Stops the background location service by invoking the stop event.
  static Future<void> stop() async {
    if (!avaliable) return;

    TalkerManager.instance.info('👷 stopping location service');

    try {
      final service = instance;
      if (service == null) throw Exception('Not initialized.');

      if (Platform.isIOS) {
        await platform.invokeMethod('toggleLocation', {'isEnabled': false});
        return;
      }

      service.invoke(LocationServiceEvent.stop);
    } catch (e, s) {
      TalkerManager.instance.error('👷 stopping location service FAILED', e, s);
    }
  }
}

/// The background location service.
///
/// This service is used to get the current location of the device in the background and notify the main isolate to update the UI with the new location.
///
/// All property prefixed with `_$` are isolated from the main app.
@pragma('vm:entry-point')
class LocationService {
  LocationService._();

  /// The service instance
  static late AndroidServiceInstance _$service;

  /// The last known location coordinates
  static LatLng? _$location;

  /// Timer for scheduling periodic location updates
  static Timer? _$locationUpdateTimer;

  /// Cached GeoJSON data for location lookups
  static late GeoJSONFeatureCollection _$geoJsonData;

  /// Cached location data mapping
  static late Map<String, Location> _$locationData;

  /// Entry point for the background service.
  ///
  /// Sets up notifications, initializes required data, and starts periodic location updates.
  /// Updates the notification with current location information.
  /// Adjusts update frequency based on movement distance.
  @pragma('vm:entry-point')
  static Future<void> _$onStart(ServiceInstance service) async {
    if (service is! AndroidServiceInstance) return;
    _$service = service;

    DartPluginRegistrant.ensureInitialized();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: LocationServiceManager.kNotificationId,
        channelKey: 'background',
        title: 'DPIP',
        body: '自動定位服務啟動中...',
        locked: true,
        autoDismissible: false,
        icon: 'resource://drawable/ic_stat_name',
        badge: 0,
      ),
    );

    await _$service.setAsForegroundService();

    await Preference.init();
    _$geoJsonData = await Global.loadTownGeojson();
    _$locationData = await Global.loadLocationData();

    _$service.setAutoStartOnBootMode(true);

    _$service.on(LocationServiceEvent.stop).listen((data) async {
      try {
        TalkerManager.instance.info('⚙️::BackgroundLocationService stopping location service');

        // Cleanup timer
        _$locationUpdateTimer?.cancel();

        await _$service.setAutoStartOnBootMode(false);
        await _$service.stopSelf();

        TalkerManager.instance.info('⚙️::BackgroundLocationService location service stopped');
      } catch (e, s) {
        TalkerManager.instance.error('⚙️::BackgroundLocationService stopping location service FAILED', e, s);
      }
    });

    // Start the periodic location update task
    await _$task();
  }

  /// Entry point for ios background service.
  ///
  /// iOS background service is handled in native code.
  @pragma('vm:entry-point')
  static Future<bool> _$onStartIOS(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// The main tick function of the service.
  ///
  /// This function is used to get the current location of the device and update the notification.
  /// It is called periodically to check if the device has moved and update the notification accordingly.
  @pragma('vm:entry-point')
  static Future<void> _$task() async {
    if (!await _$service.isForegroundService()) return;

    final $perf = Stopwatch()..start();
    TalkerManager.instance.debug('⚙️::BackgroundLocationService task started');

    try {
      // Get current position and location info
      final coordinates = await _$getDeviceGeographicalLocation();

      if (coordinates == null) {
        _$updatePosition(_$service, null);
        return;
      }

      final previousLocation = _$location;

      final distanceInKm = previousLocation != null ? coordinates.to(previousLocation) : null;

      if (distanceInKm == null || distanceInKm >= 250) {
        TalkerManager.instance.debug('⚙️::BackgroundLocationService distance: $distanceInKm, updating position');
        _$updatePosition(_$service, coordinates);
      } else {
        TalkerManager.instance.debug('⚙️::BackgroundLocationService distance: $distanceInKm, not updating position');
      }

      // Determine the next update time based on the distance moved
      int nextUpdateInterval = 15;

      if (distanceInKm != null) {
        if (distanceInKm > 30) {
          nextUpdateInterval = 5;
        } else if (distanceInKm > 10) {
          nextUpdateInterval = 10;
        }
      }

      _$locationUpdateTimer?.cancel();
      _$locationUpdateTimer = Timer.periodic(Duration(minutes: nextUpdateInterval), (timer) => _$task());
    } catch (e, s) {
      $perf.stop();
      TalkerManager.instance.error(
        '⚙️::BackgroundLocationService task FAILED after ${$perf.elapsedMilliseconds}ms',
        e,
        s,
      );
    } finally {
      if ($perf.isRunning) {
        $perf.stop();
        TalkerManager.instance.debug('⚙️::BackgroundLocationService task completed in ${$perf.elapsedMilliseconds}ms');
      }
    }
  }

  /// Gets the current geographical location of the device.
  ///
  /// Returns null if location services are disabled.
  /// Uses medium accuracy for location detection.
  @pragma('vm:entry-point')
  static Future<LatLng?> _$getDeviceGeographicalLocation() async {
    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      TalkerManager.instance.warning('位置服務未啟用');
      return null;
    }

    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    return LatLng(currentPosition.latitude, currentPosition.longitude);
  }

  /// Gets the location code for given coordinates by checking if they fall within polygon boundaries.
  ///
  /// Takes a target LatLng and checks if it falls within any polygon in the GeoJSON data.
  /// Returns the location code if found, null otherwise.
  static ({String code, Location location})? _$getLocationFromCoordinates(LatLng target) {
    final features = _$geoJsonData.features;

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

        final location = _$locationData[code];
        if (location == null) return null;

        return (code: code, location: location);
      }
    }

    return null;
  }

  /// Updates the current position in the service.
  ///
  /// Invokes a position event with the new coordinates that can be listened to
  /// by the main app to update the UI.
  @pragma('vm:entry-point')
  static Future<void> _$updatePosition(ServiceInstance service, LatLng? position) async {
    _$location = position;

    final result = position != null ? _$getLocationFromCoordinates(position) : null;

    Preference.locationCode = result?.code;
    Preference.locationLatitude = position?.latitude;
    Preference.locationLongitude = position?.longitude;

    service.invoke(LocationServiceEvent.position, PositionEvent(position, result?.code).toJson());

    // Update notification with current position
    final timestamp = DateTime.now().toDateTimeString();
    String content = '服務區域外';

    if (position == null) {
      content = '服務區域外';
    } else {
      final latitude = position.latitude.toStringAsFixed(6);
      final longitude = position.longitude.toStringAsFixed(6);

      if (result == null) {
        content = '服務區域外 ($latitude, $longitude)';
      } else {
        content = '${result.location.city} ${result.location.town} ($latitude, $longitude)';
      }
    }

    const notificationTitle = '自動定位中';
    final notificationBody =
        '$timestamp\n'
        '$content';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: LocationServiceManager.kNotificationId,
        channelKey: 'background',
        title: notificationTitle,
        body: notificationBody,
        locked: true,
        autoDismissible: false,
        badge: 0,
      ),
    );

    _$service.setForegroundNotificationInfo(title: notificationTitle, content: notificationBody);
  }
}
