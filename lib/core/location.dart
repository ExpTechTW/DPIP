import "dart:async";

import "package:geolocator/geolocator.dart";

import "package:dpip/core/providers.dart";
import "package:dpip/utils/location_to_code.dart";
import "package:dpip/utils/log.dart";

StreamSubscription<Position>? positionStreamSubscription;
Timer? restartTimer;

class GetLocationResult {
  final int? code;
  final double? lat;
  final double? lng;
  final bool change;

  GetLocationResult(this.code, this.change, this.lat, this.lng);

  Map<String, dynamic> toJson() {
    return {"code": code, "change": change, "lat": lat, "lng": lng};
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

  @pragma("vm:entry-point")
  Future<GetLocationResult> androidGetLocation() async {
    bool hasLocationChanged = false;
    final lastLatitude = GlobalProviders.location.latitude ?? 0;
    final lastLongitude = GlobalProviders.location.longitude ?? 0;

    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      TalkerManager.instance.warning("位置服務未啟用");
      return GetLocationResult(null, false, 0, 0);
    }

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
      hasLocationChanged = true;
      TalkerManager.instance.debug("距離: $distanceInMeters 更新位置");
    } else {
      TalkerManager.instance.debug("距離: $distanceInMeters 不更新位置");
    }

    GlobalProviders.location.setCode(currentLocation?.code.toString());

    return GetLocationResult(
      currentLocation?.code,
      hasLocationChanged,
      currentPosition.latitude,
      currentPosition.longitude,
    );
  }
}
