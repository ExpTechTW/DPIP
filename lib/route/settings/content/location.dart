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

  Future<bool> checkNotificationPermission(int value) async {
    PermissionStatus status;
    bool result = false;
    bool shouldRetry = true;

    while (shouldRetry) {
      status = await _requestnotificationPermission(value);

      if (!mounted) return false;

      setState(() => locationPermission = status);

      if (!status.isGranted) {
        shouldRetry = await _shownotificationPermissionDialog(value, status);
        if (shouldRetry) {
          value += 1;
        }
      } else if (status.isGranted && value >= 0) {
        result = true;
        shouldRetry = false;
      } else {
        value += 1;
      }
    }

    return result;
  }

  Future<PermissionStatus> _requestnotificationPermission(int value) async {
    switch (value) {
      case 0:
        return await Permission.notification.status;
      case 1:
        return await Permission.notification.request();
      default:
        return await Permission.notification.status;
    }
  }

  Future<bool> _shownotificationPermissionDialog(int value, PermissionStatus status) async {
    bool retry = false;
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
                retry = false;
                Navigator.pop(context);
              },
            ),
            _getnotificationActionButton(value, status, (shouldRetry) {
              retry = shouldRetry;
              Navigator.pop(context);
            }),
          ],
        );
      },
    );
    return retry;
  }

  Widget _getnotificationActionButton(int value, PermissionStatus status, Function(bool) onPressed) {
    if (value == 2) {
      return FilledButton(
        child: const Text("設定"),
        onPressed: () {
          openAppSettings();
          onPressed(false);
        },
      );
    } else {
      return FilledButton(
        child: Text((value >= 1) ? "再試一次" : "請求權限"),
        onPressed: () {
          onPressed(true);
        },
      );
    }
  }

  Future<bool> checkLocationPermission(int value) async {
    PermissionStatus status;
    bool result = false;
    bool shouldRetry = true;

    while (shouldRetry) {
      status = await _requestlocationPermission(value);

      if (!mounted) return false;

      setState(() => locationPermission = status);

      if (!status.isGranted) {
        shouldRetry = await _showlocationPermissionDialog(value, status);
        if (shouldRetry) {
          value += 1;
        }
      } else if (status.isGranted && value >= 2) {
        result = true;
        shouldRetry = false;
      } else {
        value += 1;
      }
    }

    return result;
  }

  Future<PermissionStatus> _requestlocationPermission(int value) async {
    switch (value) {
      case 0:
        return await Permission.location.status;
      case 1:
        return await Permission.location.request();
      case 2:
        return await Permission.locationAlways.request();
      default:
        return await Permission.location.status;
    }
  }

  Future<bool> _showlocationPermissionDialog(int value, PermissionStatus status) async {
    bool retry = false;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Symbols.error),
          title: Text("${(value >= 1) ? "無法" : "請求"}取得位置權限"),
          content: _getlocationDialogContent(value, status),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                retry = false;
                Navigator.pop(context);
              },
            ),
            _getlocationActionButton(value, status, (shouldRetry) {
              retry = shouldRetry;
              Navigator.pop(context);
            }),
          ],
        );
      },
    );
    return retry;
  }

  Widget _getlocationDialogContent(int value, PermissionStatus status) {
    if (value == 0) {
      return const Text("自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。");
    } else if (value == 3) {
      return Text(
        "自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「位置」權限後再試一次。" : ""}"
      );
    } else {
      return const Text("為了獲得更好的自動定位體驗，您需要將位置權限提升至「一律允許」以讓 DPIP 在背景自動設定所在地資訊。");
    }
  }

  Widget _getlocationActionButton(int value, PermissionStatus status, Function(bool) onPressed) {
    if (value == 3) {
      return FilledButton(
        child: const Text("設定"),
        onPressed: () {
          openAppSettings();
          onPressed(false);
        },
      );
    } else {
      return FilledButton(
        child: Text((value >= 1) ? "再試一次" : "請求權限"),
        onPressed: () {
          onPressed(true);
        },
      );
    }
  }

  Future toggleAutoLocation(bool value) async {
    await stopBackgroundService();

    if (!value) {
      setState(() {
        isAutoLocatingNotEnabled = false;
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
      return;
    } else {
      final notification = await checkNotificationPermission(0);
      print("notification $notification");
      final location = await checkLocationPermission(0);
      print("location $location");

      if (!notification || !location) {
        setState(() {
          isAutoLocatingNotEnabled = true;
          isAutoLocatingEnabled = false;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
        });
        return;
      }

      await startBackgroundService();

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
      (value) async {
        setState(() {
          notificationPermission = value;
        });
        if (!value.isGranted) {
          await stopBackgroundService();
          setState(() {
            isAutoLocatingNotEnabled = false;
            isAutoLocatingEnabled = false;
            Global.preference.setBool("auto-location", isAutoLocatingEnabled);
          });
        }
      },
    );
    Permission.location.status.then(
      (value) async {
        setState(() {
          locationPermission = value;
        });
        if (!value.isGranted) {
          await stopBackgroundService();
          setState(() {
            isAutoLocatingNotEnabled = false;
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
            isAutoLocatingNotEnabled = false;
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
              onChanged: (value) => toggleAutoLocation(value),
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
