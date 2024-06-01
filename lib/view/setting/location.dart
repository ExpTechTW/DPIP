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
import 'package:carp_background_location/carp_background_location.dart';
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
  late StreamSubscription<LocationDto> positionStreamSubscription;
  String? backgroundLocationData;
  bool isLocationAutoSetEnabled = Global.preference.getBool("loc-auto") ?? false;

  @override
  void initState() {
    super.initState();
    startListening();
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
    bool isEnabled = await LocationManager().isRunning;
    // bool isPermissionGranted = await checkLocationPermission();

    // if (!isPermissionGranted) {
    //   print('初次檢查時沒權限');
    //   isEnabled = false;
    // } else {
    //   isEnabled = true;
    // }
    setState(() {
      isLocationAutoSetEnabled = isEnabled;
      print(isLocationAutoSetEnabled);
      if (isLocationAutoSetEnabled) {
        getLocation();
      }
    });
  }

  Future<void> getLocation() async {
    if (!isLocationAutoSetEnabled) {
      if (positionStreamSubscription != null) {
        setState(() {
          positionStreamSubscription.cancel();
        });
      }
      return;
    }

    try {
      // bool isPermissionGranted = await checkLocationPermission();
      // if (!isPermissionGranted) {
      //   print('檢查時沒權限');
      //   if (!isLocationAutoSetEnabled) {
      //     if (positionStreamSubscription != null) {
      //       setState(() {
      //         positionStreamSubscription.cancel();
      //       });
      //     }
      //   }
      //   return;
      // }

      if (Platform.isAndroid || Platform.isIOS) {
        positionStreamSubscription = LocationManager().locationStream.listen((LocationDto location) async {
          if (location != null) {
            String lat = location.latitude.toStringAsFixed(4);
            String lon = location.longitude.toStringAsFixed(4);
            String coordinate = '$lat,$lon';
            setState(() {
              backgroundLocationData = '背景$coordinate';
            });
            messaging.getToken().then((value) {
              Global.api
                  .postNotifyLocation(
                "0.0.0",
                Platform.isAndroid ? "Android" : "iOS",
                coordinate,
                value!,
              )
                  .then((value) {
                setState(() {
                  backgroundLocationData = '$backgroundLocationData \n $value';
                });
              }).catchError((error) {
                setState(() {
                  backgroundLocationData = '$backgroundLocationData \n ${error.toString()}';
                });
              });
            }).catchError((error) {
              print(error);
            });
          }
        });
      }

      LocationDto location = await LocationManager().getCurrentLocation();
      String lat = location.latitude.toString();
      String lon = location.longitude.toString();
      setState(() {
        currentLocation = 'Lat: $lat, Lng: $lon';
        print(currentLocation);
      });
      await Global.preference.setString("loc-lat", lat);
      await Global.preference.setString("loc-lon", lon);

      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        if (Platform.isIOS) {
          String? city = placemark.subAdministrativeArea;
          String? town = placemark.locality;

          setState(() {
            currentCity = city;
            currentTown = town;
          });
        } else if (Platform.isAndroid) {
          String? city = placemark.administrativeArea;
          String? town = placemark.subAdministrativeArea;

          setState(() {
            currentCity = city;
            currentTown = town;
          });
        }

        print('縣市: $currentCity');
        print('鄉鎮市區: $currentTown');

        await Global.preference.setString("loc-city", currentCity!);
        await Global.preference.setString("loc-town", currentTown!);
      }
    } catch (e) {
      print('無法取得位置: $e');
    }
  }

  void startListening() {
    positionStreamSubscription = LocationManager().locationStream.listen((LocationDto location) {
      setState(() {
        currentLocation = 'Lat: ${location.latitude}, Lng: ${location.longitude}';
      });
    }, onError: (dynamic error) {
      setState(() {
        currentLocation = 'Could not get location: $error';
      });
    });
  }

  void stopListening() {
    positionStreamSubscription.cancel();
  }

  @override
  void dispose() {
    super.dispose();
    stopListening();
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
              trailing: CupertinoSwitch(
                value: isLocationAutoSetEnabled,
                onChanged: null,
              ),
              onTap: () async {
                toggleLocationAutoSet(await openLocationSettings());
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
              subtitle: const Text("使用手機定位自動設定所在地\n⚠ 此功能目前還在製作中"),
              trailing: Switch(
                value: isLocationAutoSetEnabled,
                onChanged: (value) {
                  if (value) {
                    setState(() async {
                      toggleLocationAutoSet(await openLocationSettings());
                    });
                  } else {
                    setState(() {
                      isLocationAutoSetEnabled = value;
                      if (positionStreamSubscription != null) {
                        setState(() {
                          positionStreamSubscription.cancel();
                        });
                      }
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
