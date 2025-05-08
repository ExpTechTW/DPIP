import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/location_to_code.dart';
import 'package:dpip/utils/log.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

StreamSubscription<Position>? positionStreamSubscription;
Timer? restartTimer;

class GetLocationResult {
  final bool change;
  final int? code;
  final double? lat;
  final double? lng;

  GetLocationResult({required this.change, this.code, this.lat, this.lng});

  factory GetLocationResult.fromJson(Map<String, dynamic> json) {
    return GetLocationResult(
      change: json['change'] as bool,
      code: json['code'] as int?,
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'change': change, 'lat': lat, 'lng': lng};
  }

  LatLng get latlng => LatLng(lat ?? 0, lng ?? 0);
}

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

  @pragma('vm:entry-point')
  Future<GetLocationResult> androidGetLocation() async {
    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      TalkerManager.instance.warning('位置服務未啟用');
      return GetLocationResult(change: false, code: null, lat: 0, lng: 0);
    }

    bool hasLocationChanged = false;
    final lastLatitude = GlobalProviders.location.latitude ?? 0;
    final lastLongitude = GlobalProviders.location.longitude ?? 0;

    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    final currentLocation = GeoJsonHelper.checkPointInPolygons(currentPosition.latitude, currentPosition.longitude);

    final distanceInMeters = Geolocator.distanceBetween(
      lastLatitude,
      lastLongitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    if (distanceInMeters >= 250) {
      GlobalProviders.location.setLatitude(currentPosition.latitude);
      GlobalProviders.location.setLongitude(currentPosition.longitude);
      GlobalProviders.location.setCode(currentLocation?.code.toString());
      hasLocationChanged = true;
      TalkerManager.instance.debug('距離: $distanceInMeters 更新位置');
    } else {
      TalkerManager.instance.debug('距離: $distanceInMeters 不更新位置');
    }

    return GetLocationResult(
      change: hasLocationChanged,
      code: currentLocation?.code,
      lat: currentPosition.latitude,
      lng: currentPosition.longitude,
    );
  }
}
