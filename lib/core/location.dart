import 'dart:async';
import 'dart:io';

import 'package:dpip/global.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

StreamSubscription<Position>? positionStreamSubscription;
Timer? restartTimer;

class GetLocationPosition {
  double latitude;
  double longitude;
  String country;

  GetLocationPosition(this.latitude, this.longitude, this.country);

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
    };
  }
}

class GetLocationResult {
  final GetLocationPosition position;
  final bool change;

  GetLocationResult(this.position, this.change);

  Map<String, dynamic> toJson() {
    return {
      'position': position.toJson(),
      'change': change,
    };
  }
}

class LocationResult {
  final String cityTown;
  final bool change;

  LocationResult(this.cityTown, this.change);
}

class LocationStatus {
  final String locstatus;
  final bool islocstatus;

  LocationStatus(this.locstatus, this.islocstatus);
}

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

  Future<LocationResult> getLatLngLocation(double latitude, double longitude) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    LocationResult locationGet = LocationResult('', false);
    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first;
      String? city;
      String? town;
      String? code;

      if (Platform.isIOS) {
        city = placemark.subAdministrativeArea;
        town = placemark.locality;
      } else if (Platform.isAndroid) {
        city = placemark.administrativeArea;
        town = placemark.subAdministrativeArea;
        code = placemark.postalCode;
      }

      String citytown = '$city $town $code';
      String citytowntemp = Global.preference.getString("loc-position-country") ?? "";

      if (citytowntemp == "" || citytowntemp != citytown) {
        await Global.preference.setString("loc-position-country", citytown);
        locationGet = LocationResult(citytown, true);
      } else {
        locationGet = LocationResult(citytowntemp, false);
      }
    }
    return locationGet;
  }

  @pragma('vm:entry-point')
  Future<GetLocationResult> androidGetLocation() async {
    int lastLocationUpdate =
        Global.preference.getInt("last-location-update") ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;
    int nowtemp = now - lastLocationUpdate;
    bool positionchange = false;
    final positionlattemp = Global.preference.getDouble("loc-position-lat") ?? 0.0;
    final positionlontemp = Global.preference.getDouble("loc-position-lon") ?? 0.0;
    final positioncountrytemp = Global.preference.getString("loc-position-country") ?? "";
    GetLocationPosition positionlast = GetLocationPosition(positionlattemp, positionlontemp, positioncountrytemp);

    if (nowtemp > 300000 || nowtemp == 0) {
      Global.preference.setInt("last-location-update", now);
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LocationResult country = await getLatLngLocation(position.latitude, position.longitude);
      positionlast = GetLocationPosition(position.latitude, position.longitude, country.cityTown);
      double distance =
          Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
      if (distance >= 250 || nowtemp == 0) {
        Global.preference.setDouble("loc-position-lat", position.latitude);
        Global.preference.setDouble("loc-position-lon", position.longitude);
        Global.preference.setDouble("user-lat", position.latitude);
        Global.preference.setDouble("user-lon", position.longitude);
        positionchange = true;
        print('距離: $distance 更新位置');
      } else {
        print('距離: $distance 不更新位置');
      }
    } else {
      print('間距: $nowtemp 不更新位置');
    }

    return GetLocationResult(positionlast, positionchange);
  }
}
