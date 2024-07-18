import 'dart:async';
import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GetLocationPosition {
  double latitude;
  double longitude;
  String country;

  GetLocationPosition(this.latitude, this.longitude, this.country);
}

class GetLocationResult {
  final GetLocationPosition position;
  final bool change;

  GetLocationResult(this.position, this.change);
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
  StreamSubscription<Position>? positionStreamSubscription;
  Timer? restartTimer;

  void iosStartPositionStream() async {
    if (positionStreamSubscription != null) return;
    final positionStream = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.medium,
        activityType: ActivityType.other,
        distanceFilter: 250,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
        allowBackgroundLocationUpdates: true,
      ),
    );
    positionStreamSubscription = positionStream.handleError((error) async {
      print('位置流錯誤: $error');
      iosStopPositionStream();
      restartTimer = Timer(const Duration(minutes: 2), iosStartPositionStream);
    }).listen((Position? position) async {
      if (position != null) {
        final positionlattemp = Global.preference.getDouble("loc-position-lat") ?? 0.0;
        final positionlontemp = Global.preference.getDouble("loc-position-lon") ?? 0.0;
        double distance =
            Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
        if (distance >= 250) {
          Global.preference.setDouble("loc-position-lat", position.latitude);
          Global.preference.setDouble("loc-position-lon", position.longitude);
          LocationResult locationResult = await getLatLngLocation(position.latitude, position.longitude);
          print('新位置: ${position}');
          print('城市和鄉鎮: ${locationResult.cityTown}');

          String lat = position.latitude.toStringAsFixed(4);
          String lon = position.longitude.toStringAsFixed(4);
          String? fcmToken = Global.preference.getString("fcm-token");
          if (fcmToken != null) {
            final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
            print(body);
          }
          print('距離: $distance 更新位置');
        } else {
          print('距離: $distance 不更新位置');
        }
      }
      iosStopPositionStream();
      restartTimer = Timer(const Duration(minutes: 2), iosStartPositionStream);
    });
    print('位置流已開啟');
  }

  void iosStopPositionStream() {
    positionStreamSubscription?.cancel();
    positionStreamSubscription = null;
    print('位置流已停止');
    restartTimer?.cancel();
  }

  Future<LocationResult> getLatLngLocation(double latitude, double longitude) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    LocationResult locationGet = LocationResult('', false);
    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first;
      String? city;
      String? town;

      if (Platform.isIOS) {
        city = placemark.subAdministrativeArea;
        town = placemark.locality;
      } else if (Platform.isAndroid) {
        city = placemark.administrativeArea;
        town = placemark.subAdministrativeArea;
      }

      String citytown = '$city $town';
      String citytowntemp = Global.preference.getString("loc-city-town") ?? "";

      if (citytowntemp == "" || citytowntemp != citytown) {
        await Global.preference.setString("loc-city-town", citytown);
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
