import 'dart:async';
import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

class GetLocationResult {
  final Position position;
  final bool change;

  GetLocationResult(this.position, this.change);
}

class LocationResult {
  final String cityTown;
  final bool change;

  LocationResult(this.cityTown, this.change);
}

@pragma('vm:entry-point')
Future<GetLocationResult> getLocation() async {
  final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  final positionlattemp = Global.preference.getDouble("loc-position-lat") ?? 0.0;
  final positionlontemp = Global.preference.getDouble("loc-position-lon") ?? 0.0;
  bool positionchange = false;

  double distance = Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);

  int lastLocationUpdate = Global.preference.getInt("last-location-update") ?? DateTime.now().toUtc().millisecondsSinceEpoch;
  int now = DateTime.now().toUtc().millisecondsSinceEpoch;
  int nowtemp = now - lastLocationUpdate;

  if (nowtemp == 0) {
    await Global.preference.setInt("last-location-update", now);
  }

  if (positionlattemp == 0.0 && positionlontemp == 0.0) {
    await Global.preference.setDouble("loc-position-lat", position.latitude);
    await Global.preference.setDouble("loc-position-lon", position.longitude);
    positionchange = true;
    print('距離: $distance 間距: $nowtemp 初始');
  }

  if (distance >= 250 && nowtemp > 300000) {
    await Global.preference.setDouble("loc-position-lat", position.latitude);
    await Global.preference.setDouble("loc-position-lon", position.longitude);
    await Global.preference.setInt("last-location-update", now);
    positionchange = true;
    print('距離: $distance 間距: $nowtemp 確定');
  } else {
    print('距離: $distance 間距: $nowtemp');
  }

  return GetLocationResult(position, positionchange);
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

final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;
StreamSubscription<Position>? positionStreamSubscription;
Position? lastPosition;

void startPositionStream() async {
  if (await openLocationSettings(true)) {
    if (positionStreamSubscription == null) {
      final positionStream = Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.medium,
          activityType: ActivityType.other,
          pauseLocationUpdatesAutomatically: true,
          showBackgroundLocationIndicator: false,
          allowBackgroundLocationUpdates: true,
        ),
      );
      positionStreamSubscription = positionStream.handleError((error) async {
        await positionStreamSubscription?.cancel();
        positionStreamSubscription = null;
      }).listen((Position? position) async {
        if (position != null && shouldUpdatePosition(position)) {
          lastPosition = position;

          GetLocationResult result = await getLocation();
          if (result.change) {
            LocationResult locationResult = await getLatLngLocation(result.position.latitude, result.position.longitude);
            print('新位置: ${result.position}');
            print('城市和鄉鎮: ${locationResult.cityTown}');
          }
          String lat = result.position.latitude.toStringAsFixed(4);
          String lon = result.position.longitude.toStringAsFixed(4);
          String fcmToken = Global.preference.getString("fcm-token") ?? "";
          if (result.change && fcmToken != "") {
            final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
            print(body);
          }
        }
      });
      print('位置已開啟');
    }
  }
}

void stopPositionStream() {
  positionStreamSubscription?.cancel();
  positionStreamSubscription = null;
}

Future<bool> openLocationSettings(bool openSettings) async {
  return true;
}

bool shouldUpdatePosition(Position position) {
  return true;
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

Future<PermissionStatus> requestnotificationPermission(int value) async {
  switch (value) {
    case 0:
      return await Permission.notification.status;
    case 1:
      return await Permission.notification.request();
    default:
      return await Permission.notification.status;
  }
}

Future<int> shownotificationPermissionDialog(int value, PermissionStatus status, BuildContext context) async {
  int retry = 0;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: const Icon(Symbols.error),
        title: Text("${(value >= 1) ? "無法" : "請求"}取得通知權限"),
        content: Text(
          "自動定位功能需要您允許 DPIP 使用通知權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「通知」權限後再試一次。" : ""}",
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: const Text("取消"),
            onPressed: () {
              retry = 3;
              Navigator.pop(context);
            },
          ),
          getnotificationActionButton(value, status, (shouldRetry) {
            retry = shouldRetry;
            Navigator.pop(context);
          }),
        ],
      );
    },
  );
  return retry;
}

Widget getnotificationActionButton(int value, PermissionStatus status, Function(int) onPressed) {
  if (value == 2) {
    return FilledButton(
      child: const Text("設定"),
      onPressed: () {
        openAppSettings();
        onPressed(2);
      },
    );
  } else {
    return FilledButton(
      child: Text((value >= 1) ? "再試一次" : "請求權限"),
      onPressed: () {
        onPressed(1);
      },
    );
  }
}

Future<PermissionStatus> requestlocationPermission(int value) async {
  switch (value) {
    case 0:
      return await Permission.locationAlways.status;
    case 1:
      return await Permission.locationAlways.request();
    case 2:
      return await Permission.location.request();
    case 3:
      return await Permission.locationAlways.request();
    default:
      return await Permission.locationAlways.status;
  }
}

Future<int> showlocationPermissionDialog(int value, PermissionStatus status, BuildContext context) async {
  int retry = 0;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: const Icon(Symbols.error),
        title: Text("${(value >= 1) ? "無法" : "請求"}取得位置權限"),
        content: getlocationDialogContent(value, status),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: const Text("取消"),
            onPressed: () {
              retry = 3;
              Navigator.pop(context);
            },
          ),
          getlocationActionButton(value, status, (shouldRetry) {
            retry = shouldRetry;
            Navigator.pop(context);
          }),
        ],
      );
    },
  );
  return retry;
}

Widget getlocationDialogContent(int value, PermissionStatus status) {
  if (value == 0) {
    return const Text("自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。");
  } else if (value == 3) {
    return Text(
      "自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「位置」權限後再試一次。" : ""}"
    );
  } else {
    return Text(
        Platform.isAndroid
            ? "為了獲得更好的自動定位體驗，您需要將位置權限提升至「一律允許」以讓 DPIP 在背景自動設定所在地資訊。"
            : "為了獲得更好的自動定位體驗，您需要將位置權限提升至「永遠」以讓 DPIP 在背景自動設定所在地資訊。",
    );
  }
}

Widget getlocationActionButton(int value, PermissionStatus status, Function(int) onPressed) {
  if (value == 3) {
    return FilledButton(
      child: const Text("設定"),
      onPressed: () {
        openAppSettings();
        onPressed(2);
      },
    );
  } else {
    return FilledButton(
      child: Text((value >= 1) ? "再試一次" : "請求權限"),
      onPressed: () {
        onPressed(1);
      },
    );
  }
}