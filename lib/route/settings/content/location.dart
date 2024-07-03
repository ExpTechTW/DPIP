import 'dart:async';

import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
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
  bool isAutoLocatingNotEnabled = false;
  PermissionStatus? notificationPermission;
  PermissionStatus? locationPermission;
  PermissionStatus? locationAlwaysPermission;

  String city = "";
  String town = "";

  Future<bool> requestLocationAlwaysPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  Future<bool> checkNotificationPermission(int value) async {
    PermissionStatus status;
    if (value == 0) {
      status = await Permission.notification.status;
    } else if (value == 1) {
      status = await Permission.notification.request();
    } else {
      status = await Permission.notification.status;
    }
    if (!mounted) return false;

    setState(() => notificationPermission = status);

    if (!status.isGranted) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Symbols.error),
            title: const Text("無法取得通知權限"),
            content: Text(
              "自動定位功能需要您允許 DPIP 使用通知權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「通知」權限後再試一次。" : ""}",
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              status.isPermanentlyDenied
                  ? FilledButton(
                      child: const Text("設定"),
                      onPressed: () {
                        openAppSettings();
                        Navigator.pop(context);
                      },
                    )
                  : FilledButton(
                      child: const Text("再試一次"),
                      onPressed: () {
                        value += 1;
                        checkNotificationPermission(value);
                        Navigator.pop(context);
                      },
                    ),
            ],
          );
        },
      );

      return false;
    }

    return true;
  }

  Future<bool> checkLocationPermission(int value) async {
    PermissionStatus status;
    bool result = false;
    bool shouldRetry = true;

    while (shouldRetry) {
      status = await _requestPermission(value);

      if (!mounted) return false;

      setState(() => locationPermission = status);

      if (!status.isGranted) {
        shouldRetry = await _showPermissionDialog(value, status);
        if (shouldRetry) {
          value += 1;
        }
      } else {
        result = true;
        shouldRetry = false;
      }
    }

    return result;
  }

  Future<PermissionStatus> _requestPermission(int value) async {
    switch (value) {
      case 0:
        return await Permission.location.status;
      case 1:
        return await Permission.location.request();
      case 2:
        return await Permission.location.status;
      case 3:
        return await Permission.locationAlways.request();
      case 4:
        return await Permission.locationAlways.status;
      default:
        return await Permission.location.request();
    }
  }

  Future<bool> _showPermissionDialog(int value, PermissionStatus status) async {
    bool retry = false;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Symbols.error),
          title: const Text("無法取得位置權限"),
          content: _getDialogContent(value, status),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                retry = false;
                Navigator.pop(context);
              },
            ),
            _getActionButton(value, status, (shouldRetry) {
              retry = shouldRetry;
              Navigator.pop(context);
            }),
          ],
        );
      },
    );
    return retry;
  }

  Widget _getDialogContent(int value, PermissionStatus status) {
    if (value == 0) {
      return const Text("自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。");
    } else if (value == 5) {
      return Text(
        "自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「位置」權限後再試一次。" : ""}"
      );
    } else {
      return const Text("為了獲得更好的自動定位體驗，您需要將位置權限提升至「一律允許」以讓 DPIP 在背景自動設定所在地資訊。");
    }
  }

  Widget _getActionButton(int value, PermissionStatus status, Function(bool) onPressed) {
    if (value == 5) {
      return FilledButton(
        child: const Text("設定"),
        onPressed: () {
          openAppSettings();
          onPressed(true);
        },
      );
    } else {
      return FilledButton(
        child: const Text("再試一次"),
        onPressed: () {
          onPressed(true);
        },
      );
    }
  }

  Future<bool> checkLocationAlwaysPermission() async {
    final status = await Permission.locationAlways.status;

    setState(() => locationAlwaysPermission = status);

    if (status.isGranted) {
      return true;
    } else {
      if (!mounted) return false;

      final status = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: const Text("一律允許位置權限"),
                content: const Text("為了獲得更好的自動定位體驗，您需要將位置權限提升至「一律允許」以讓 DPIP 在背景自動設定所在地資訊。"),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    child: const Text("取消"),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  FilledButton(
                    child: const Text("確定"),
                    onPressed: () async {
                      final status = await Permission.locationAlways.request();

                      setState(() => locationAlwaysPermission = status);

                      if (status.isPermanentlyDenied) {
                        openAppSettings();
                      }

                      if (!context.mounted) return;

                      Navigator.pop(context, status.isGranted);
                    },
                  ),
                ],
              );
            },
          ) ??
          false;

      return status;
    }
  }

  Future toggleAutoLocation() async {
    await stopBackgroundService();

    if (isAutoLocatingEnabled) {
      setState(() {
        isAutoLocatingNotEnabled = true;
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
      return;
    } else {
      final notification = await checkNotificationPermission(0);
      final location = await checkLocationPermission(0);
      print("notification $notification");
      print("location $location");

      if (!notification || !location) {
        setState(() {
          isAutoLocatingNotEnabled = true;
          isAutoLocatingEnabled = false;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
        });
        return;
      }

      await initializeService();

      setState(() {
        isAutoLocatingNotEnabled = false;
        isAutoLocatingEnabled = true;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Permission.notification.status.then(
      (value) {
        setState(() {
          notificationPermission = value;
        });
      },
    );
    Permission.location.status.then(
      (value) {
        setState(() {
          locationPermission = value;
        });
      },
    );
    Permission.locationAlways.status.then(
      (value) {
        setState(() {
          locationAlwaysPermission = value;
        });
      },
    );
    if (!notificationPermission!.isGranted || !locationPermission!.isGranted || !locationAlwaysPermission!.isGranted) {
      setState(() {
        isAutoLocatingNotEnabled = true;
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
              onChanged: (value) => toggleAutoLocation(),
            ),
          ),
          if (locationAlwaysPermission != null)
            Visibility(
              visible: isAutoLocatingNotEnabled && !locationAlwaysPermission!.isGranted,
              maintainAnimation: true,
              maintainState: true,
              child: AnimatedOpacity(
                opacity: isAutoLocatingNotEnabled && !locationAlwaysPermission!.isGranted ? 1 : 0,
                curve: const Interval(0.2, 1, curve: Easing.standard),
                duration: Durations.medium2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Symbols.warning,
                        color: context.colors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "自動定位功能需要將位置權限提升至「一律允許」以在背景使用。",
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                    TextButton(
                      child: const Text("設定"),
                      onPressed: () async {
                        final status = await Permission.locationAlways.request();
                        if (status.isPermanentlyDenied) {
                          openAppSettings();
                        }
                      },
                    ),
                  ]),
                ),
              ),
            ),
          if (notificationPermission != null)
            Visibility(
              visible: isAutoLocatingNotEnabled && !notificationPermission!.isGranted,
              maintainAnimation: true,
              maintainState: true,
              child: AnimatedOpacity(
                opacity: isAutoLocatingNotEnabled && !notificationPermission!.isGranted ? 1 : 0,
                curve: const Interval(0.2, 1, curve: Easing.standard),
                duration: Durations.medium2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Symbols.warning,
                        color: context.colors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '通知功能已被拒絕，請移至設定允許權限',
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                    TextButton(
                      child: const Text("設定"),
                      onPressed: () async {
                        await openAppSettings();
                      },
                    ),
                  ]),
                ),
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
            title: Text("縣市"),
            subtitle: Text(city),
            enabled: !isAutoLocatingEnabled,
            onTap: () {},
          ),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Symbols.forest),
            ),
            title: Text("鄉鎮"),
            subtitle: Text(town),
            enabled: !isAutoLocatingEnabled,
            onTap: () {},
          )
        ],
      ),
    );
  }
}
