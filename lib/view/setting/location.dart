import 'dart:async';
import 'dart:io';

import 'package:dpip/core/utils.dart';
import 'package:dpip/global.dart';
import 'package:dpip/main.dart';
import 'package:dpip/view/setting/location_utils.dart';
import 'package:dpip/view/setting/ios/cupertino_city_page.dart';
import 'package:dpip/view/setting/ios/cupertino_town_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  String? BackgroundLocationData;
  bool isLocationAutoSetEnabled = Global.preference.getBool("loc-auto") ?? false;

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? serviceStatusStream;

  @override
  void initState() {
    super.initState();
    checkLocationPermissionAndSyncSwitchState();
  }

  Future<void> setCityLocation(String? value) async {
    if (value == null) return;
    // unsubscribe old location topic
    if (currentCity != null) {
      await messaging.unsubscribeFromTopic(safeBase64Encode(currentCity!));
      if (currentTown != null) {
        await messaging.unsubscribeFromTopic(safeBase64Encode("$currentCity$currentTown"));
      }
    }

    setState(() {
      currentCity = value;
      currentTown = Global.region[value]?.keys.first;
    });

    await Global.preference.setString("loc-city", currentCity!);
    await Global.preference.setString("loc-town", currentTown!);

    // subscribe new location topic
    await messaging.subscribeToTopic(safeBase64Encode(currentCity!));
    await messaging.subscribeToTopic(safeBase64Encode("$currentCity$currentTown"));
  }

  Future<void> setTownLocation(String? value) async {
    if (value == null) return;

    if (currentTown != null) {
      await messaging.unsubscribeFromTopic(safeBase64Encode("$currentCity$currentTown"));
    }

    setState(() {
      currentTown = value;
    });

    await Global.preference.setString("loc-town", currentTown!);
    await messaging.subscribeToTopic(safeBase64Encode("$currentCity$currentTown"));
  }

  Future<void> checkLocationPermissionAndSyncSwitchState() async {
    bool isEnabled = false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      print('初次檢查時沒權限');
      isEnabled = false;
    } else {
      isEnabled = true;
    }
    setState(() {
      isLocationAutoSetEnabled = isEnabled;
      print(isLocationAutoSetEnabled);
      if (isLocationAutoSetEnabled) {
        getLocation();
      }
    });
  }

  Future<void> getLocation() async {
    if (!isLocationAutoSetEnabled) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        print('檢查時沒權限');
        return;
      }

      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      print('服務: $isLocationServiceEnabled');
      if (!isLocationServiceEnabled) {
        return;
      }

      serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
        if (status == ServiceStatus.enabled) {
          print('服務啟用');
          if (_positionStreamSubscription != null) {
            setState(() {
              _positionStreamSubscription?.cancel();
              _positionStreamSubscription = null;
            });
          }
        } else {
          print('服務未啟用');
        }
      });

      if (_positionStreamSubscription == null) {
        if (Platform.isAndroid) {
          final positionStream = _geolocatorPlatform.getPositionStream(
              locationSettings: AndroidSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 1,
                  forceLocationManager: false,
                  intervalDuration: const Duration(seconds: 1),
                  //(Optional) Set foreground notification config to keep the app alive
                  //when going to the background
                  foregroundNotificationConfig: const ForegroundNotificationConfig(
                    notificationText: "服務中...",
                    notificationTitle: "DPIP 背景定位",
                    notificationChannelName: '背景定位',
                    enableWifiLock: true,
                    enableWakeLock: true,
                    setOngoing: false,
                  )));
          _positionStreamSubscription = positionStream.handleError((error) {
            _positionStreamSubscription?.cancel();
            _positionStreamSubscription = null;
          }).listen((Position? position) async {
            if (position != null) {
              String? lat = position.latitude.toStringAsFixed(4);
              String? lon = position.longitude.toStringAsFixed(4);
              String? coordinate = '$lat,$lon';
              setState(() {
                BackgroundLocationData = '背景$coordinate';
              });
              messaging.getToken().then((value) {
                Global.api
                    .postNotifyLocation(
                  "0.0.0",
                  "Android",
                  coordinate,
                  value!,
                )
                    .then((value) {
                  setState(() {
                    BackgroundLocationData = '$BackgroundLocationData \n $value';
                  });
                }).catchError((error) {
                  setState(() {
                    BackgroundLocationData = '$BackgroundLocationData \n ${error.toString()}';
                  });
                });
              }).catchError((error) {
                print(error);
              });
            }
          });
        } else if (Platform.isIOS) {
          final positionStream = _geolocatorPlatform.getPositionStream(
              locationSettings: AppleSettings(
            accuracy: LocationAccuracy.high,
            activityType: ActivityType.otherNavigation,
            distanceFilter: 100,
            pauseLocationUpdatesAutomatically: true,
            // Only set to true if our app will be started up in the background.
            showBackgroundLocationIndicator: false,
          ));
          _positionStreamSubscription = positionStream.handleError((error) {
            _positionStreamSubscription?.cancel();
            _positionStreamSubscription = null;
          }).listen((Position? position) async {
            if (position != null) {
              String? lat = position.latitude.toStringAsFixed(4);
              String? lon = position.longitude.toStringAsFixed(4);
              String? coordinate = '$lat,$lon';
              setState(() {
                BackgroundLocationData = '背景$coordinate';
              });
              messaging.getToken().then((value) {
                Global.api
                    .postNotifyLocation(
                  "0.0.0",
                  "Ios",
                  coordinate,
                  value!,
                )
                    .then((value) {
                  setState(() {
                    BackgroundLocationData = '$BackgroundLocationData \n $value';
                  });
                }).catchError((error) {
                  setState(() {
                    BackgroundLocationData = '$BackgroundLocationData \n ${error.toString()}';
                  });
                });
              }).catchError((error) {
                print(error);
              });
            }
          });
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      String? lat = position.latitude.toString();
      String? lon = position.longitude.toString();
      setState(() {
        currentLocation = 'Lat: $lat, Lng: $lon';
        print(currentLocation);
      });
      await Global.preference.setString("loc-lat", lat);
      await Global.preference.setString("loc-lon", lon);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        if (Platform.isIOS) {
          String? city = placemark.subAdministrativeArea;
          String? town = placemark.locality;

          setState(() {
            currentCity = city;
            currentTown = town;
            print('縣市: $currentCity');
            print('鄉鎮市區: $currentTown');
            await Global.preference.setString("loc-city", currentCity!);
            await Global.preference.setString("loc-town", currentTown!);
          });
        } else {
          String? city = placemark.administrativeArea;
          String? town = placemark.subAdministrativeArea;

          setState(() {
            currentCity = city;
            currentTown = town;
            print('縣市: $currentCity');
            print('鄉鎮市區: $currentTown');
            await Global.preference.setString("loc-city", currentCity!);
            await Global.preference.setString("loc-town", currentTown!);
          });
        }
      }
    } catch (e) {
      print('無法取得位置: $e');
    }
  }

  Future<void> toggleLocationAutoSet(bool value) async {
    setState(() {
      isLocationAutoSetEnabled = value;
      if (isLocationAutoSetEnabled) {
        getLocation();
      }
    });
    await Global.preference.setBool("loc-auto", isLocationAutoSetEnabled);
  }

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
                subtitle: const Text("使用手機定位自動設定所在地"),
                onTap: () {
                  openLocationSettings();
                },
              ),
              CupertinoListSection(
                header: const Text("所在地"),
                children: [
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.building_2_fill),
                    title: const Text('縣市'),
                    additionalInfo: Text(currentCity ?? "尚未設定"),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.push<String>(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => CupertinoCityPage(city: currentCity ?? "縣市"),
                        ),
                      ).then(setCityLocation);
                    },
                  ),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.tree),
                    title: const Text('鄉鎮市區'),
                    additionalInfo: Text(currentTown ?? "尚未設定"),
                    trailing: const CupertinoListTileChevron(),
                    onTap: currentCity != null
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
                  CupertinoListTile(
                    title: const Text('背景資料'),
                    subtitle: Text(BackgroundLocationData ?? "無資料"),
                    onTap: () async {
                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                      String? lat = position.latitude.toStringAsFixed(4);
                      String? lon = position.longitude.toStringAsFixed(4);
                      String? coordinate = '$lat,$lon';
                      setState(() {
                        BackgroundLocationData = '當前$coordinate';
                      });
                      messaging.getToken().then((value) {
                        Global.api
                            .postNotifyLocation(
                          "0.0.0",
                          "Ios",
                          coordinate,
                          value!,
                        )
                            .then((value) {
                          setState(() {
                            BackgroundLocationData = '$BackgroundLocationData \n $value';
                          });
                        }).catchError((error) {
                          setState(() {
                            BackgroundLocationData = '$BackgroundLocationData \n ${error.toString()}';
                          });
                        });
                      }).catchError((error) {
                        print(error);
                      });
                      await Global.preference.setString("loc-lat", lat);
                      await Global.preference.setString("loc-lon", lon);
                    },
                  ),
                ],
              ),
            ],
          ));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("所在地"),
        ),
        body: ListView(
          children: [
            ListTile(
              title: const Text("自動設定"),
              subtitle: const Text("使用手機定位自動設定所在地\n⚠ 此功能目前還在製作中"),
              onTap: () async {
                toggleLocationAutoSet(await openLocationSettings());
              },
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
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消"))],
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
            ListTile(
              title: const Text('背景資料'),
              subtitle: Text(BackgroundLocationData ?? "無資料"),
              onTap: () async {
                Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                String? lat = position.latitude.toStringAsFixed(4);
                String? lon = position.longitude.toStringAsFixed(4);
                String? coordinate = '$lat,$lon';
                setState(() {
                  BackgroundLocationData = '當前$coordinate';
                });
                messaging.getToken().then((value) {
                  Global.api
                      .postNotifyLocation(
                    "0.0.0",
                    "Android",
                    coordinate,
                    value!,
                  )
                      .then((value) {
                    setState(() {
                      BackgroundLocationData = '$BackgroundLocationData \n $value';
                    });
                  }).catchError((error) {
                    setState(() {
                      BackgroundLocationData = '$BackgroundLocationData \n ${error.toString()}';
                    });
                  });
                }).catchError((error) {
                  print(error);
                });
                await Global.preference.setString("loc-lat", lat);
                await Global.preference.setString("loc-lon", lon);
              },
            ),
          ],
        ),
      );
    }
  }
}
