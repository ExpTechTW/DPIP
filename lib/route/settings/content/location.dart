import 'dart:async';
import 'dart:io';

import 'package:dpip/core/location.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/location_selector/location_selector.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsLocationView extends StatefulWidget {
  const SettingsLocationView({super.key});

  @override
  State<SettingsLocationView> createState() => _SettingsLocationViewState();
}

class _SettingsLocationViewState extends State<SettingsLocationView> {
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  PermissionStatus? notificationPermission;
  PermissionStatus? locationAlwaysPermission;

  String? city = Global.preference.getString("location-city");
  String? town = Global.preference.getString("location-town");

  Future<int> checkNotificationPermission(int value) async {
    PermissionStatus status;
    int result = 0;
    bool shouldRetry = true;
    int statusRetry = 0;

    while (shouldRetry) {
      status = await requestnotificationPermission(value);

      if (!mounted) return 0;

      setState(() => locationAlwaysPermission = status);

      if (!status.isGranted) {
        statusRetry = await shownotificationPermissionDialog(value, status, context);
        if (statusRetry == 1) {
          value += 1;
        } else if (statusRetry == 2) {
          result = 2;
          shouldRetry = false;
        } else if (statusRetry == 3) {
          result = 3;
          shouldRetry = false;
        }
      } else if (status.isGranted && value >= 0) {
        result = 1;
        shouldRetry = false;
      } else {
        value += 1;
      }
    }

    return result;
  }

  Future<int> checkLocationPermission(int value) async {
    PermissionStatus status;
    int result = 0;
    bool shouldRetry = true;
    int statusRetry = 0;

    while (shouldRetry) {
      status = await requestlocationPermission(value);

      if (!mounted) return 0;

      setState(() => locationAlwaysPermission = status);

      if (!status.isGranted) {
        statusRetry = await showlocationPermissionDialog(value, status, context);
        if (statusRetry == 1) {
          value += 1;
        } else if (statusRetry == 2) {
          result = 2;
          shouldRetry = false;
        } else if (statusRetry == 3) {
          result = 3;
          shouldRetry = false;
        }
      } else if (status.isGranted && value >= 3) {
        result = 1;
        shouldRetry = false;
      } else {
        value += 1;
      }
    }

    return result;
  }

  Future toggleAutoLocation(bool value) async {
    await stopBackgroundService();

    if (!value) {
      setState(() {
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
      return;
    } else {
      final notification = await checkNotificationPermission(0);
      print("notification $notification");
      final location = await checkLocationPermission(0);
      print("location $location");

      if (notification == 2 || location == 2) {
        setState(() {
          isAutoLocatingEnabled = false;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
          toggleAutoLocation(value);
        });
        return;
      } else if (notification == 3 || location == 3) {
        setState(() {
          isAutoLocatingEnabled = false;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
        });
        return;
      }

      await startBackgroundService();

      setState(() {
        isAutoLocatingEnabled = true;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Permission.notification.status.then(
      (value) async {
        setState(() {
          notificationPermission = value;
        });
        if (!value.isGranted) {
          await stopBackgroundService();
          setState(() {
            isAutoLocatingEnabled = false;
            Global.preference.setBool("auto-location", isAutoLocatingEnabled);
          });
        }
      },
    );
    Permission.locationAlways.status.then(
      (value) async {
        setState(() {
          locationAlwaysPermission = value;
        });
        if (!value.isGranted) {
          await stopBackgroundService();
          setState(() {
            isAutoLocatingEnabled = false;
            Global.preference.setBool("auto-location", isAutoLocatingEnabled);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SwitchListTile(
            tileColor: isAutoLocatingEnabled ? context.colors.primaryContainer : context.colors.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              "啟用自動定位",
              style: TextStyle(
                color: isAutoLocatingEnabled ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            value: isAutoLocatingEnabled,
            onChanged: (value) => toggleAutoLocation(value),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.info),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text("自動定位功能將使用您的裝置上的 GPS ，根據您的地理位置，自動更新您的所在地，提供即時的天氣和地震資訊，讓您隨時掌握當地最新狀況。"),
            )
          ]),
        ),
        const ListTileGroupHeader(title: "所在地"),
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Symbols.location_city),
          ),
          title: const Text("縣市"),
          subtitle: Text(city ?? "尚未設定"),
          enabled: !isAutoLocatingEnabled,
          onTap: () async {
            await Navigator.of(
              context,
              rootNavigator: true,
            ).push(
              MaterialPageRoute(
                builder: (context) => LocationSelectorRoute(city: null, town: town),
              ),
            );

            setState(() {
              city = Global.preference.getString("location-city");
              town = Global.preference.getString("location-town");
            });
          },
        ),
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Symbols.forest),
          ),
          title: const Text("鄉鎮"),
          subtitle: Text(town ?? "尚未設定"),
          enabled: !isAutoLocatingEnabled && city != null,
          onTap: () async {
            await Navigator.of(
              context,
              rootNavigator: true,
            ).push(
              MaterialPageRoute(
                builder: (context) => LocationSelectorRoute(city: city, town: town),
              ),
            );

            setState(() {
              city = Global.preference.getString("location-city");
              town = Global.preference.getString("location-town");
            });
          },
        )
      ],
    );
  }
}
