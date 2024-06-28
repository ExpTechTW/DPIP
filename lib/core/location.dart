import 'dart:async';
import 'dart:io';

import 'package:dpip/global.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<Position> getLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    return position;
}

class LocationResult {
  final String cityTown;
  final bool change;

  LocationResult(this.cityTown, this.change);
}

Future<LocationResult> getLocationcitytown(double latitude, double longitude) async {
  List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
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

      return LocationResult(citytown, true);
    }

    // print('縣市: $city');
    // print('鄉鎮市區: $town');
    return LocationResult(citytown, false);
  }
  return LocationResult("", false);
}

Future<bool> requestLocationAlwaysPermission() async {
  PermissionStatus status = await Permission.location.request();

  if (status.isGranted) {
    print('位置權限已授予');

    status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print('背景位置權限已授予');
      return true;
    }
  } else if (status.isDenied) {
    print('位置權限被拒絕');

    status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print('背景位置權限已授予');
      return true;
    }
  } else if (status.isPermanentlyDenied) {
    status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print('背景位置權限已授予');
      return true;
    } else if (status.isPermanentlyDenied) {
      print('位置權限被永久拒絕');
      await openAppSettings();
    }
  }

  return false;
}