import 'dart:async';
import 'dart:io';

import 'package:autostarter/autostarter.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/service.dart';
import '../../location_selector/location_selector.dart';

final stateSettingsLocationView = _SettingsLocationViewState();

typedef PositionUpdateCallback = void Function(String?, String?);

class SettingsLocationView extends StatefulWidget {
  final Function(String?, String?)? onPositionUpdate;

  const SettingsLocationView({Key? key, this.onPositionUpdate}) : super(key: key);

  @override
  State<SettingsLocationView> createState() => _SettingsLocationViewState();

  static PositionUpdateCallback? _activeCallback;

  static void setActiveCallback(PositionUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updatePosition(String? city, String? town) {
    _activeCallback?.call(city, town);
  }
}

class _SettingsLocationViewState extends State<SettingsLocationView> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.exptech.dpip/location');
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  PermissionStatus? notificationPermission;
  PermissionStatus? locationPermission;
  PermissionStatus? locationAlwaysPermission;

  String? city = Global.preference.getString("location-city");
  String? town = Global.preference.getString("location-town");

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

  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return false;

    setState(() => notificationPermission = status);

    if (!status.isGranted) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Symbols.error),
            title: Text(context.i18n.unable_notification),
            content: Text(
              "自動定位功能需要您允許 DPIP 使用通知權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「通知」權限後再試一次。" : ""}",
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                child: Text(context.i18n.cancel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              status.isPermanentlyDenied
                  ? FilledButton(
                      child: Text(context.i18n.settings),
                      onPressed: () {
                        openAppSettings();
                        Navigator.pop(context);
                      },
                    )
                  : FilledButton(
                      child: Text(context.i18n.again),
                      onPressed: () {
                        checkNotificationPermission();
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

  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.request();
    if (!mounted) return false;

    setState(() => locationPermission = status);

    if (!status.isGranted) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Symbols.error),
            title: Text(context.i18n.unable_location),
            content: Text(
              "自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「位置」權限後再試一次。" : ""}",
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                child: Text(context.i18n.cancel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              status.isPermanentlyDenied
                  ? FilledButton(
                      child: Text(context.i18n.settings),
                      onPressed: () {
                        openAppSettings();
                        Navigator.pop(context);
                      },
                    )
                  : FilledButton(
                      child: Text(context.i18n.again),
                      onPressed: () {
                        checkLocationPermission();
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

  Future<bool> checkLocationAlwaysPermission() async {
    final status = await Permission.locationAlways.status;

    setState(() => locationAlwaysPermission = status);

    if (status.isGranted) {
      return true;
    } else {
      if (!mounted) return false;
      final permissionType = Platform.isAndroid ? "一律允許" : "永遠";

      final status = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: Text("$permissionType位置權限"),
                content: Text("為了獲得更好的自動定位體驗，您需要將位置權限提升至「$permissionType」以便讓 DPIP 在背景自動設定所在地資訊。"),
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

  Future<bool> androidCheckAutoStartPermission(int num) async {
    if (Platform.isIOS) return true;
    try {
      bool? isAvailable = await Autostarter.isAutoStartPermissionAvailable();
      if (isAvailable == true) {
        bool? status = await Autostarter.checkAutoStartState();
        if (status != null) {
          if (status == false) {
            String contentText = (num == 0)
                ? "為了獲得更好的自動定位體驗，您需要給予「自啟動權限」以便讓 DPIP 在背景自動設定所在地資訊。"
                : "為了獲得更好的 DPIP 體驗，您需要給予「自啟動權限」以便讓 DPIP 在背景有正常接收警訊通知。";
            return await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      icon: const Icon(Symbols.my_location),
                      title: const Text("自啟動權限"),
                      content: Text(contentText),
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
                            await Autostarter.getAutoStartPermission(newTask: true);
                            Navigator.pop(context, false);
                          },
                        ),
                      ],
                    );
                  },
                ) ??
                false;
          } else {
            return true;
          }
        } else {
          return true;
        }
      } else {
        return true;
      }
    } catch (err) {
      return false;
    }
  }

  Future<bool> androidCheckBatteryOptimizationPermission(int num) async {
    if (Platform.isIOS) return true;
    try {
      bool? isAvailable = await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
      if (isAvailable == false) {
        String contentText = (num == 0)
            ? "為了獲得更好的自動定位體驗，您需要給予「無限制」以便讓 DPIP 在背景自動設定所在地資訊。"
            : "為了獲得更好的 DPIP 體驗，您需要給予「無限制」以便讓 DPIP 在背景有正常接收警訊通知。";
        return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  icon: const Icon(Symbols.my_location),
                  title: const Text("省電策略"),
                  content: Text(contentText),
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
                        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                        Navigator.pop(context, false);
                      },
                    ),
                  ],
                );
              },
            ) ??
            false;
      } else {
        return true;
      }
    } catch (err) {
      return false;
    }
  }

  Future toggleAutoLocation() async {
    if (Platform.isIOS) {
      try {
        await platform.invokeMethod('toggleLocation', {'isEnabled': !isAutoLocatingEnabled});
      } catch (e) {
        return;
      }
    } else if (Platform.isAndroid) {
      androidstopBackgroundService(isAutoLocatingEnabled);
    }

    if (isAutoLocatingEnabled) {
      Global.preference.setDouble("user-lat", 0.0);
      Global.preference.setDouble("user-lon", 0.0);
      setState(() {
        isAutoLocatingEnabled = false;
      });
    } else {
      final notification = await checkNotificationPermission();
      if (!notification) return;

      final location = await checkLocationPermission();
      if (!location) return;

      await checkLocationAlwaysPermission();

      bool autoStart = await androidCheckAutoStartPermission(0);

      if (!autoStart) return;

      bool batteryOptimization = await androidCheckBatteryOptimizationPermission(0);

      if (!batteryOptimization) return;

      if (Platform.isAndroid) {
        androidStartBackgroundService(false);
      }

      Global.preference.remove("location-city");
      Global.preference.remove("location-town");

      city = null;
      town = null;

      setState(() {
        isAutoLocatingEnabled = true;
      });
    }

    Global.preference.setBool("auto-location", isAutoLocatingEnabled);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    permissionStatusUpdate();
    SettingsLocationView.setActiveCallback(sendpositionUpdate);
  }

  @override
  void dispose() {
    SettingsLocationView.clearActiveCallback();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    permissionStatusUpdate();
  }

  void permissionStatusUpdate() {
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
        print(value);
        setState(() {
          locationAlwaysPermission = value;
        });
      },
    );
  }

  void sendpositionUpdate(String? cityUpdate, String? townUpdate) {
    if (mounted) {
      setState(() {
        city = cityUpdate;
        town = townUpdate;
      });
      widget.onPositionUpdate?.call(city, town);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              // FIXME: workaround waiting for upstream PR to merge
              // https://github.com/material-foundation/flutter-packages/pull/599
              tileColor: isAutoLocatingEnabled ? context.colors.primaryContainer : context.colors.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                context.i18n.settings_location_auto,
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
              visible: isAutoLocatingEnabled && !locationAlwaysPermission!.isGranted,
              maintainAnimation: true,
              maintainState: true,
              child: AnimatedOpacity(
                opacity: isAutoLocatingEnabled && !locationAlwaysPermission!.isGranted ? 1 : 0,
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
                        "自動定位功能需要將位置權限提升至「${(Platform.isAndroid) ? "一律允許" : "永遠"}」以在背景使用。",
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                    TextButton(
                      child: Text(context.i18n.settings),
                      onPressed: () {
                        openAppSettings();
                      },
                    ),
                  ]),
                ),
              ),
            ),
          if (notificationPermission != null)
            Visibility(
              visible: isAutoLocatingEnabled && !notificationPermission!.isGranted,
              maintainAnimation: true,
              maintainState: true,
              child: AnimatedOpacity(
                opacity: isAutoLocatingEnabled && !notificationPermission!.isGranted ? 1 : 0,
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
                      child: Text(context.i18n.settings),
                      onPressed: () {
                        openAppSettings();
                      },
                    ),
                  ]),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Symbols.info),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.i18n.settings_location_auto_description),
              )
            ]),
          ),
          ListTileGroupHeader(title: context.i18n.settings_location),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.location_city),
            ),
            title: Text(context.i18n.location_city),
            subtitle: Text(city ?? context.i18n.location_Not_set),
            enabled: !isAutoLocatingEnabled,
            onTap: () async {
              bool autoStart = await androidCheckAutoStartPermission(1);

              if (!autoStart) return;

              bool batteryOptimization = await androidCheckBatteryOptimizationPermission(1);

              if (!batteryOptimization) return;

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
            title: Text(context.i18n.location_town),
            subtitle: Text(town ?? context.i18n.location_Not_set),
            enabled: !isAutoLocatingEnabled && city != null,
            onTap: () async {
              bool autoStart = await androidCheckAutoStartPermission(1);

              if (!autoStart) return;

              bool batteryOptimization = await androidCheckBatteryOptimizationPermission(1);

              if (!batteryOptimization) return;

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
      ),
    );
  }
}
