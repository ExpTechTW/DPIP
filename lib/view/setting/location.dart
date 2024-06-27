import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:dpip/core/utils.dart';
import 'package:dpip/global.dart';
import 'package:dpip/location_service.dart';
import 'package:dpip/main.dart';
import 'package:dpip/view/setting/location_utils.dart';
import 'package:dpip/view/setting/ios/cupertino_city_page.dart';
import 'package:dpip/view/setting/ios/cupertino_town_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSettingsPage extends StatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  State<LocationSettingsPage> createState() => _LocationSettingsPageState();
}

class _LocationSettingsPageState extends State<LocationSettingsPage> {
  String? currentTown = Global.preference.getString("loc-town");
  String? currentCity = Global.preference.getString("loc-city");
  String? currentLocation;
  String? backgroundLocationData;
  bool isLocationAutoSetEnabled = Global.preference.getBool("loc-auto") ?? false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  LocationService locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
    //
    // const InitializationSettings initializationSettings = InitializationSettings(
    //   android: initializationSettingsAndroid,
    // );
    //
    // flutterLocalNotificationsPlugin.initialize(initializationSettings);
    // checkLocationPermissionAndSyncSwitchState();
    toggleLocationAutoSet(isLocationAutoSetEnabled);
  }

  Future<void> setCityLocation(String? value) async {
    if (value == null) return;

    if (Platform.isIOS) {
      showLoadingDialog();
    }

    // unsubscribe old location topic
    // if (currentCity != null) {
    //   await messaging.unsubscribeFromTopic(safeBase64Encode(currentCity!));
    //   if (currentTown != null) {
    //     await messaging.unsubscribeFromTopic(safeBase64Encode("$currentCity$currentTown"));
    //   }
    // }

    // if (Platform.isAndroid) {
    //   showLoadingDialog();
    // }

    setState(() {
      currentCity = value;
      currentTown = Global.region[value]?.keys.first;
    });

    await Global.preference.setString("loc-city", currentCity!);
    await Global.preference.setString("loc-town", currentTown!);

    // subscribe new location topic
    // await messaging.subscribeToTopic(safeBase64Encode(currentCity!));
    // await messaging.subscribeToTopic(safeBase64Encode("$currentCity$currentTown"));

    final String response = await rootBundle.loadString('assets/region.json');
    final data = json.decode(response);

    if (data != null && data.containsKey(currentCity) && data[currentCity].containsKey(currentTown)) {
      final townData = data[currentCity][currentTown];
      String lat = townData['lat'].toStringAsFixed(4);
      String lon = townData['lon'].toStringAsFixed(4);
      String coordinate = '$lat,$lon';

      messaging.getToken().then((value) {
        Global.api.postNotifyLocation(Global.packageInfo.version, Platform.isAndroid ? "0" : "1", coordinate, value!);
      });
    }
    // Navigator.pop(context);
  }

  Future<void> setTownLocation(String? value) async {
    if (value == null) return;

    if (Platform.isIOS) {
      showLoadingDialog();
    }

    // if (currentTown != null) {
    //   await messaging.unsubscribeFromTopic(safeBase64Encode("$currentCity$currentTown"));
    // }

    // if (Platform.isAndroid) {
    //   showLoadingDialog();
    // }

    setState(() {
      currentTown = value;
    });

    await Global.preference.setString("loc-town", currentTown!);
    // await messaging.subscribeToTopic(safeBase64Encode("$currentCity$currentTown"));

    final String response = await rootBundle.loadString('assets/region.json');
    final data = json.decode(response);

    if (data != null && data.containsKey(currentCity) && data[currentCity].containsKey(currentTown)) {
      final townData = data[currentCity][currentTown];
      String lat = townData['lat'].toStringAsFixed(4);
      String lon = townData['lon'].toStringAsFixed(4);
      String coordinate = '$lat,$lon';

      messaging.getToken().then((value) {
        Global.api.postNotifyLocation(Global.packageInfo.version, Platform.isAndroid ? "0" : "1", coordinate, value!);
      });
    }
    // Navigator.pop(context);
  }

  void showLoadingDialog() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return const CupertinoAlertDialog(
            content: Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 24),
                Text("正在更新設定..."),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Text("正在更新設定..."),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> checkLocationPermissionAndSyncSwitchState() async {
    bool isEnabled = false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      print('初次檢查時沒權限');
      isEnabled = false;
    } else {
      if (permission == LocationPermission.always) {
        isEnabled = true;
      }
    }
    setState(() async {
      isLocationAutoSetEnabled = isEnabled;
      if (isLocationAutoSetEnabled) {
        locationService.startPositionStream();
        getLocation();
      }
    });
  }

  Future<void> getLocation() async {
    if (!isLocationAutoSetEnabled) return;

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);

      bool isInSpecifiedCountry = await checkIfInSpecifiedCountry(position.latitude, position.longitude);
      if (isInSpecifiedCountry) {
        await updateLocation(position);
      } else {
        print('位置不在指定的國家範圍內');
      }
    } catch (e) {
      print('無法取得位置: $e');
    }
  }

  Future<bool> checkIfInSpecifiedCountry(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String? country = placemark.country;
        if (country != 'Taiwan') {
          return true;
        }
      }
    } catch (e) {
      print('檢查國家時出錯: $e');
    }
    return false;
  }

  Future<void> updateLocation(Position position) async {
    String lat = position.latitude.toString();
    String lon = position.longitude.toString();

    await Global.preference.setString("loc-lat", lat);
    await Global.preference.setString("loc-lon", lon);

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
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

      setState(() {
        currentCity = city;
        currentTown = town;
      });

      print('縣市: $currentCity');
      print('鄉鎮市區: $currentTown');

      await Global.preference.setString("loc-city", currentCity!);
      await Global.preference.setString("loc-town", currentTown!);
    }
  }

  Future<void> toggleLocationAutoSet(bool value) async {
    setState(() {
      isLocationAutoSetEnabled = value;
      if (isLocationAutoSetEnabled) {
        locationService.startPositionStream();
        getLocation();
      } else {
        locationService.stopPositionStream();
      }
    });
    await fetchNotificationIcon();

    await Global.preference.setBool("loc-auto", isLocationAutoSetEnabled);
  }

  Future<Uint8List> fetchNotificationIcon() async {
    ByteData imageData = await rootBundle.load('assets/app_icon.png');
    return imageData.buffer.asUint8List();
  }

  // Future<void> showNotification() async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     'DPIP',
  //     '位置更新',
  //     channelDescription: '背景位置已更新。',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     showWhen: false,
  //     icon: 'ic_launcher',
  //   );
  //
  //   const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //   );
  //
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     '位置更新',
  //     '背景位置已更新。',
  //     platformChannelSpecifics,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("所在地"),
        ),
        child: ListView(
          children: [
            CupertinoListTile(
              title: const Text("自動設定"),
              subtitle: const Text("使用裝置定位自動設定所在地"),
              trailing: CupertinoSwitch(
                value: isLocationAutoSetEnabled,
                onChanged: (value) {
                  if (value) {
                    setState(() async {
                      toggleLocationAutoSet(await openLocationSettings(false));
                    });
                  } else {
                    setState(() {
                      toggleLocationAutoSet(false);
                    });
                  }
                },
              ),
            ),
            CupertinoListSection(
              header: const Text("所在地"),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.building_2_fill),
                  title: const Text('縣市'),
                  additionalInfo: Text(currentCity ?? "尚未設定"),
                  trailing: const CupertinoListTileChevron(),
                  onTap: !isLocationAutoSetEnabled
                      ? () {
                          Navigator.push<String>(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => CupertinoCityPage(city: currentCity ?? "縣市"),
                            ),
                          ).then(setCityLocation);
                        }
                      : null,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.tree),
                  title: const Text('鄉鎮市區'),
                  additionalInfo: Text(currentTown ?? "尚未設定"),
                  trailing: const CupertinoListTileChevron(),
                  onTap: !isLocationAutoSetEnabled && currentCity != null
                      ? () {
                          Navigator.push<String>(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => CupertinoTownPage(city: currentCity!, town: currentTown),
                            ),
                          ).then(setTownLocation);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("所在地"),
        ),
        body: ListView(
          children: [
            ListTile(
              title: const Text("自動設定"),
              subtitle: const Text("使用裝置定位自動設定所在地\n⚠ 此功能目前還在製作中"),
              trailing: Switch(
                value: isLocationAutoSetEnabled,
                onChanged: (value) {
                  if (value) {
                    setState(() async {
                      toggleLocationAutoSet(await openLocationSettings(false));
                    });
                  } else {
                    setState(() {
                      toggleLocationAutoSet(false);
                    });
                  }
                },
              ),
              enabled: true,
            ),
            ListTile(
              title: const Text('縣市'),
              subtitle: Text(currentCity ?? "尚未設定"),
              enabled: !isLocationAutoSetEnabled,
              onTap: () {
                List<String> cityList = Global.region.keys.toList();

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("縣市"),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
                    content: SizedBox(
                      width: double.minPositive,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cityList.length,
                        itemBuilder: (context, index) => RadioListTile(
                          value: cityList[index],
                          groupValue: currentCity,
                          title: Text(cityList[index]),
                          onChanged: (value) {
                            setCityLocation(value);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('鄉鎮市區'),
              subtitle: Text(currentTown ?? "尚未設定"),
              enabled: !isLocationAutoSetEnabled && currentCity != null,
              onTap: () {
                List<String> townList = Global.region[currentCity]!.keys.toList();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('鄉鎮市區'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
                    content: SizedBox(
                      width: double.minPositive,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: townList.length,
                        itemBuilder: (context, index) => RadioListTile(
                          value: townList[index],
                          groupValue: currentTown,
                          title: Text(townList[index]),
                          onChanged: (value) {
                            setTownLocation(value);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("取消"),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }
}
