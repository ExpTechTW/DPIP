import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/asset_bundle.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/log.dart';

class PositionEvent {
  final LatLng? coordinates;

  PositionEvent(this.coordinates);

  factory PositionEvent.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List<dynamic>?;

    return PositionEvent(coordinates != null ? LatLng(coordinates[0] as double, coordinates[1] as double) : null);
  }

  Map<String, dynamic> toJson() {
    return {'coordinates': coordinates?.toJson()};
  }
}

/// Events emitted by the background service.
final class BackgroundLocationServiceEvent {
  /// Event emitted when a new position is set in the background service.
  /// Contains the updated location coordinates.
  static const position = 'position';

  /// Method event to stop the service.
  static const stop = 'stop';
}

/// Background location service.
///
/// This class is responsible for managing the background location service.
/// It is used to get the current location of the device inthe background and notify the main isolate to update the UI with the new location.
///
/// All property prefixed with `_$` are isolated from the main app.
@pragma('vm:entry-point')
class BackgroundLocationService {
  BackgroundLocationService._();

  /// The notification ID used for the background service notification
  static const kNotificationId = 888888;

  /// Instance of the background service
  static final instance = FlutterBackgroundService();

  /// Whether the background service has been initialized
  static bool initialized = false;

  /// Initializes the background location service.
  ///
  /// Configures the service with Android specific settings.
  /// Sets up a listener for position updates that reloads preferences and updates device location.
  ///
  /// Will starts the service if automatic location updates are enabled.
  static Future<void> initalize() async {
    if (initialized) return;

    TalkerManager.instance.info('⚙️ initializing location service');

    await instance.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _$onStart,
        isForegroundMode: true,
        foregroundServiceTypes: [AndroidForegroundType.location],
        notificationChannelId: 'background',
        initialNotificationTitle: 'DPIP',
        initialNotificationContent: '正在初始化自動定位服務...',
        foregroundServiceNotificationId: kNotificationId,
      ),
      // iOS is handled in native code
      iosConfiguration: IosConfiguration(),
    );

    // Reloads the UI isolate's preference cache when a new position is set in the background service.
    instance.on(BackgroundLocationServiceEvent.position).listen((data) {
      final event = PositionEvent.fromJson(data!);

      Preference.reload();

      // Handle FCM notification
      final fcmToken = Preference.notifyToken;
      if (fcmToken.isNotEmpty && event.coordinates != null) {
        ExpTech().updateDeviceLocation(token: fcmToken, coordinates: event.coordinates!);
      }
    });

    initialized = true;

    if (Preference.locationAuto == true) await start();
  }

  /// Starts the background location service.
  ///
  /// Initializes the service if not already initialized. Only starts if the service is not already running.
  static Future<void> start() async {
    if (!initialized) await initalize();
    TalkerManager.instance.info('⚙️ starting location service');

    if (await instance.isRunning()) {
      TalkerManager.instance.warning('⚙️ location service is already running, skipping...');
      return;
    }

    await instance.startService();
  }

  /// Stops the background location service by invoking the stop event.
  static Future<void> stop() async {
    if (!initialized) return;

    TalkerManager.instance.info('⚙️ stopping location service');
    instance.invoke(BackgroundLocationServiceEvent.stop);
  }

  /// The last known location coordinates
  static LatLng? _$location;

  /// Timer for scheduling periodic location updates
  static Timer? _$locationUpdateTimer;

  /// Cached GeoJSON data for location lookups
  static late Map<String, dynamic> _$geoJsonData;

  /// Cached location data mapping
  static late Map<String, Location> _$locationData;

  /// Entry point for the background service.
  ///
  /// Sets up notifications, initializes required data, and starts periodic location updates.
  /// Updates the notification with current location information.
  /// Adjusts update frequency based on movement distance.
  @pragma('vm:entry-point')
  static Future<void> _$onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is! AndroidServiceInstance) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: kNotificationId,
        channelKey: 'background',
        title: 'DPIP',
        body: '自動定位服務啟動中...',
        locked: true,
        autoDismissible: false,
        icon: 'resource://drawable/ic_stat_name',
      ),
    );

    await Preference.init();
    _$geoJsonData = await rootBundle.loadJson('assets/map/town.json');
    _$locationData = await Global.loadLocationData();

    service.setAutoStartOnBootMode(true);

    service.on(BackgroundLocationServiceEvent.stop).listen((data) {
      _$locationUpdateTimer?.cancel();
      service.stopSelf().then((_) {
        TalkerManager.instance.info('⚙️ location service stopped');
      });
    });

    // Define the periodic location update task
    Future<void> updateLocation() async {
      _$locationUpdateTimer?.cancel();
      if (!await service.isForegroundService()) return;

      // Get current position and location info
      final coordinates = await _$getDeviceGeographicalLocation(service);

      if (coordinates == null) {
        _$updatePosition(service, null);
        return;
      }

      final locationCode = _$getLocationFromCoordinates(coordinates);
      final lastLocation = _$location;

      final distanceInKm = lastLocation != null ? coordinates.to(lastLocation) : null;

      if (distanceInKm == null || distanceInKm >= 250) {
        TalkerManager.instance.debug('距離: $distanceInKm 更新位置');
        _$updatePosition(service, coordinates);
      } else {
        TalkerManager.instance.debug('距離: $distanceInKm 不更新位置');
      }

      final latitude = coordinates.latitude.toStringAsFixed(4);
      final longitude = coordinates.longitude.toStringAsFixed(4);

      final location = locationCode != null ? _$locationData[locationCode] : null;
      final locationName = location == null ? '服務區域外' : '${location.city} ${location.town}';

      // Update notification with current position
      const notificationTitle = '自動定位中';
      final timestamp = DateTime.now().toDateTimeString();
      final notificationBody =
          '$timestamp\n'
          '$locationName ($latitude, $longitude) ';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: kNotificationId,
          channelKey: 'background',
          title: notificationTitle,
          body: notificationBody,
          locked: true,
          autoDismissible: false,
          badge: 0,
        ),
      );
      service.setForegroundNotificationInfo(title: notificationTitle, content: notificationBody);

      int time = 15;

      if (distanceInKm != null) {
        if (distanceInKm > 30) {
          time = 5;
        } else if (distanceInKm > 10) {
          time = 10;
        }
      }

      _$location = coordinates;

      _$locationUpdateTimer = Timer.periodic(Duration(minutes: time), (timer) => updateLocation());
    }

    // Start the periodic task
    updateLocation();
  }

  /// Gets the current geographical location of the device.
  ///
  /// Returns null if location services are disabled.
  /// Uses medium accuracy for location detection.
  @pragma('vm:entry-point')
  static Future<LatLng?> _$getDeviceGeographicalLocation(ServiceInstance service) async {
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
  static String? _$getLocationFromCoordinates(LatLng target) {
    final features = (_$geoJsonData['features'] as List).cast<Map<String, dynamic>>();

    for (final feature in features) {
      final geometry = (feature['geometry'] as Map).cast<String, dynamic>();
      final type = geometry['type'] as String;

      if (type == 'Polygon' || type == 'MultiPolygon') {
        bool isInPolygon = false;

        if (type == 'Polygon') {
          final coordinates = ((geometry['coordinates'] as List)[0] as List).cast<List>();
          final List<List<double>> polygon =
              coordinates.map<List<double>>((coord) {
                return coord.map<double>((e) => (e as num).toDouble()).toList();
              }).toList();

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
        } else {
          final multiPolygon = (geometry['coordinates'] as List).cast<List<List>>();
          for (final polygonCoordinates in multiPolygon) {
            final coordinates = polygonCoordinates[0].cast<List>();
            final List<List<double>> polygon =
                coordinates.map<List<double>>((coord) {
                  return coord.map<double>((e) => (e as num).toDouble()).toList();
                }).toList();

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
          return (feature['properties'] as Map<String, dynamic>)['CODE'] as String;
        }
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
    service.invoke(BackgroundLocationServiceEvent.position, PositionEvent(position).toJson());
  }
}
