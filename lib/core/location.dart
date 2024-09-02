import "dart:async";

import "package:dpip/global.dart";
import "package:dpip/util/log.dart";
import "package:geolocator/geolocator.dart";

import "package:dpip/util/location_to_code.dart";

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
    bool positionchange = false;
    final positionlattemp = Global.preference.getDouble("user-lat") ?? 0.0;
    final positionlontemp = Global.preference.getDouble("user-lon") ?? 0.0;

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    GeoJsonProperties? location = GeoJsonHelper.checkPointInPolygons(position.latitude, position.longitude);
    double distance =
        Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
    if (distance >= 250) {
      Global.preference.setDouble("user-lat", position.latitude);
      Global.preference.setDouble("user-lon", position.longitude);
      positionchange = true;
      TalkerManager.instance.debug("距離: $distance 更新位置");
    } else {
      TalkerManager.instance.debug("距離: $distance 不更新位置");
    }

    return GetLocationResult(location?.code, positionchange, position.latitude, position.longitude);
  }
}
