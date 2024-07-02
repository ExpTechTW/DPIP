import 'dart:async';
import 'dart:io';

import 'package:dpip/global.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

int last_location_update = DateTime.now().toUtc().millisecondsSinceEpoch;

class GetLocationResult {
  final Position position;
  final bool change;

  GetLocationResult(this.position, this.change);
}

@pragma('vm:entry-point')
Future<GetLocationResult> getLocation() async {
  final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  final positionlattemp = Global.preference.getDouble("loc-position-lat") ?? 0.0;
  final positionlontemp = Global.preference.getDouble("loc-position-lon") ?? 0.0;
  bool positionchange = false;

  if ((positionlattemp == 0.0 && positionlontemp == 0.0) ||
      (positionlattemp != position.latitude && positionlontemp != position.longitude)) {
    await Global.preference.setDouble("loc-position-lat", position.latitude);
    await Global.preference.setDouble("loc-position-lon", position.longitude);
  }

  double distance = Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);

  int now = DateTime.now().toUtc().millisecondsSinceEpoch;

  if (distance >= 250 && now - last_location_update > 300000) {
    last_location_update = now;
    positionchange = true;
    print('距離: $distance');
  } else {
    print('距離: $distance');
  }

  return GetLocationResult(position, positionchange);
}

class LocationResult {
  final String cityTown;
  final bool change;

  LocationResult(this.cityTown, this.change);
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
    // print('縣市: $city');
    // print('鄉鎮市區: $town');
  }
  return locationGet;
}

class LocationStatus {
  final String locstatus;
  final bool islocstatus;

  LocationStatus(this.locstatus, this.islocstatus);
}

Future<LocationStatus> requestLocationAlwaysPermission() async {
  String locstatus = "";
  bool islocGranted = false;
  if (Platform.isAndroid) {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      print('位置權限已授予');

      status = await Permission.locationAlways.request();
      if (status.isGranted) {
        print('背景位置權限已授予');
        islocGranted = true;
      } else {
        print('位置權限被拒絕');
        locstatus = "拒絕";
      }
    } else if (status.isDenied) {
      print('位置權限被拒絕');

      status = await Permission.locationAlways.request();
      if (status.isGranted) {
        print('背景位置權限已授予');
        islocGranted = true;
      } else {
        print('位置權限被拒絕');
        locstatus = "拒絕";
      }
    } else if (status.isPermanentlyDenied) {
      print('位置權限被永久拒絕');

      status = await Permission.locationAlways.request();
      if (status.isGranted) {
        print('背景位置權限已授予');
        islocGranted = true;
      } else if (status.isDenied) {
        print('位置權限被拒絕');

        status = await Permission.location.request();

        if (status.isGranted) {
          print('背景位置權限已授予');
          islocGranted = true;
        } else if (status.isDenied) {
          print('位置權限被拒絕');
          locstatus = "拒絕";
        } else if (status.isPermanentlyDenied) {
          print('位置權限被永久拒絕');
          locstatus = "永久拒絕";
        }
      } else if (status.isPermanentlyDenied) {
        print('位置權限被拒絕');
        locstatus = "拒絕";
      }
    }
    // } else if (Platform.isIOS) {
    //   const urlIOS = 'app-settings:';
    //   final uriIOS = Uri.parse(urlIOS);
    //   if (await canLaunchUrl(uriIOS)) {
    //     await launchUrl(uriIOS);
    //     islocGranted = true;
    //   }
  }

  return LocationStatus(locstatus, islocGranted);
}
