import 'dart:io';

import 'package:dpip/core/utils.dart';
import 'package:dpip/global.dart';
import 'package:dpip/main.dart';
import 'package:dpip/view/setting/ios/cupertino_city_page.dart';
import 'package:dpip/view/setting/ios/cupertino_town_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LocationSettingsPage extends StatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  State<LocationSettingsPage> createState() => _LocationSettingsPageState();
}

class _LocationSettingsPageState extends State<LocationSettingsPage> {
  String? currentTown = Global.preference.getString("loc-town");
  String? currentCity = Global.preference.getString("loc-city");
  bool isLocationAutoSetEnabled = Global.preference.getBool("loc-auto") ?? false;

  Future<void> setCityLocation(String? value) async {
    print(value);
    if (value == null) return;

    if (currentCity != null) {
      if (currentTown != null) {
        unsubscribe("$currentCity-$currentTown");
      }
    }

    setState(() {
      currentCity = value;
      currentTown = Global.region[value]!.keys.first;
    });

    await Global.preference.setString("loc-city", currentCity!);
    await Global.preference.setString("loc-town", currentTown!);

    // subscribe new location topic
    await messaging.subscribeToTopic(safeBase64Encode(currentCity!));
    await messaging.subscribeToTopic(safeBase64Encode("$currentCity$currentTown"));
    subscribe("$currentCity-$currentTown");
  }

  Future<void> setTownLocation(String? value) async {
    if (value == null) return;
    if (currentTown != null) {
      await unsubscribe("$currentCity-$currentTown");
    }
    setState(() {
      currentTown = value;
    });

    await Global.preference.setString("loc-town", currentTown!);
    subscribe("$currentCity-$currentTown");
  }

  Future<void> unsubscribe(String location) async {
    await messaging.unsubscribeFromTopic(safeBase64Encode("${location}_typhoon"));
    await messaging.unsubscribeFromTopic(safeBase64Encode("${location}_notify_work_and_class_status"));
    await messaging.unsubscribeFromTopic(safeBase64Encode("${location}_wind"));
    await messaging.unsubscribeFromTopic(safeBase64Encode("${location}_heat"));
    await messaging.unsubscribeFromTopic(safeBase64Encode("${location}_rainfall"));
    await messaging.unsubscribeFromTopic(safeBase64Encode("${location}_thunderstorm"));
    await messaging.unsubscribeFromTopic(safeBase64Encode("${location}_rts"));
  }

  Future<void> subscribe(String location) async {
    await messaging.subscribeToTopic(safeBase64Encode("${location}_typhoon"));
    await messaging.subscribeToTopic(safeBase64Encode("${location}_notify_work_and_class_status"));
    await messaging.subscribeToTopic(safeBase64Encode("${location}_wind"));
    await messaging.subscribeToTopic(safeBase64Encode("${location}_heat"));
    await messaging.subscribeToTopic(safeBase64Encode("${location}_rainfall"));
    await messaging.subscribeToTopic(safeBase64Encode("${location}_thunderstorm"));
    await messaging.subscribeToTopic(safeBase64Encode("${location}_rts"));
    print(location);
  }

  Future<void> toggleLocationAutoSet(bool value) async {
    setState(() {
      isLocationAutoSetEnabled = value;
    });
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
              trailing: Switch(
                value: isLocationAutoSetEnabled,
                onChanged: null,
              ),
              enabled: false,
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
          ],
        ),
      );
    }
  }
}
