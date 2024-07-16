import 'dart:async';
import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @pragma('vm:entry-point')
  Future<GetLocationResult> getLocation() async {
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
      await Global.preference.setInt("last-location-update", now);
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LocationResult country = await getLatLngLocation(position.latitude, position.longitude);
      positionlast = GetLocationPosition(position.latitude, position.longitude, country.cityTown);
      await Global.preference.setString("loc-position-country", country.cityTown);
      double distance =
          Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
      if (distance >= 250 || nowtemp == 0) {
        await Global.preference.setDouble("loc-position-lat", position.latitude);
        await Global.preference.setDouble("loc-position-lon", position.longitude);
        positionchange = true;
        print('距離: $distance 間距: $nowtemp 更新位置');
      } else {
        print('距離: $distance 間距: $nowtemp 不更新位置');
      }
    } else {
      print('間距: $nowtemp 不更新位置');
    }

    return GetLocationResult(positionlast, positionchange);
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

  void startPositionStream() async {
    if (await openLocationSettings(true)) {
      if (positionStreamSubscription == null) {
        final positionStream = Geolocator.getPositionStream(
          locationSettings: AppleSettings(
            accuracy: LocationAccuracy.medium,
            activityType: ActivityType.other,
            distanceFilter: 250,
            pauseLocationUpdatesAutomatically: true,
            showBackgroundLocationIndicator: false,
            allowBackgroundLocationUpdates: true,
          ),
        );
        positionStreamSubscription = positionStream.handleError((error) async {
          print('位置流錯誤: $error');
          await positionStreamSubscription?.cancel();
          positionStreamSubscription = null;
        }).listen((Position? position) async {
          if (position != null) {
            final positionlattemp = Global.preference.getDouble("loc-position-lat") ?? 0.0;
            final positionlontemp = Global.preference.getDouble("loc-position-lon") ?? 0.0;
            double distance =
                Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
            if (distance >= 250) {
              await Global.preference.setDouble("loc-position-lat", position.latitude);
              await Global.preference.setDouble("loc-position-lon", position.longitude);
              LocationResult locationResult = await getLatLngLocation(position.latitude, position.longitude);
              print('新位置: ${position}');
              print('城市和鄉鎮: ${locationResult.cityTown}');

              String lat = position.latitude.toStringAsFixed(4);
              String lon = position.longitude.toStringAsFixed(4);
              String fcmToken = Global.preference.getString("fcm-token") ?? "";
              if (fcmToken != "") {
                final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
                print(body);
              }
              print('距離: $distance 更新位置');
            } else {
              print('距離: $distance 不更新位置');
            }
          }
          restartTimer = Timer(const Duration(minutes: 1), startPositionStream);
          stopPositionStream();
        });
        print('位置流已開啟');
      }
    }
  }

  void stopPositionStream() {
    positionStreamSubscription?.cancel();
    positionStreamSubscription = null;
    print('位置流已停止');
  }

  Future<bool> openLocationSettings(bool openSettings) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (openSettings) {
        await Geolocator.openLocationSettings();
        return await Geolocator.isLocationServiceEnabled();
      }
      return false;
    }
    return true;
  }

  Future<LocationStatus> requestLocationAlwaysPermission() async {
    String locstatus = "";
    bool islocGranted = false;

    if (Platform.isIOS) {
      PermissionStatus status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        status = await Permission.locationAlways.request();
        if (status.isGranted) {
          print('背景位置權限已授予');
          islocGranted = true;
        } else {
          print('背景位置權限被拒絕');
          locstatus = "拒絕";
        }
      } else {
        print('位置權限被拒絕');
        locstatus = "拒絕";
      }
    } else if (Platform.isAndroid) {
      PermissionStatus status = await Permission.location.request();
      if (status.isGranted) {
        status = await Permission.locationAlways.request();
        if (status.isGranted) {
          print('背景位置權限已授予');
          islocGranted = true;
        } else {
          print('背景位置權限被拒絕');
          locstatus = "拒絕";
        }
      } else {
        print('位置權限被拒絕');
        locstatus = "拒絕";
      }
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

  Future<PermissionStatus> requestLocationPermission(int value) async {
    if (Platform.isIOS) {
      switch (value) {
        case 0:
          return await Permission.location.status;
        case 1:
          return await Permission.location.request();
        case 2:
          return await Permission.location.request();
        case 3:
          return await Permission.locationAlways.request();
        default:
          return await Permission.location.status;
      }
    } else {
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
  }

  Future<int> showLocationPermissionDialog(int value, PermissionStatus status, BuildContext context) async {
    int retry = 0;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Symbols.error),
          title: Text("${(value >= 1) ? "無法" : "請求"}取得位置權限"),
          content: getLocationDialogContent(value, status),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                retry = 3;
                Navigator.pop(context);
              },
            ),
            getLocationActionButton(value, status, (shouldRetry) {
              retry = shouldRetry;
              Navigator.pop(context);
            }),
          ],
        );
      },
    );
    return retry;
  }

  Widget getLocationDialogContent(int value, PermissionStatus status) {
    if (value == 0) {
      return const Text("自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。");
    } else if (value == 3) {
      return Text("自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「位置」權限後再試一次。" : ""}");
    } else {
      return Text(
        "為了獲得更好的自動定位體驗，您需要將位置權限提升至「${(Platform.isAndroid) ? "一律允許" : "永遠"}」以讓 DPIP 在背景自動設定所在地資訊。",
      );
    }
  }

  Widget getLocationActionButton(int value, PermissionStatus status, Function(int) onPressed) {
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
}
