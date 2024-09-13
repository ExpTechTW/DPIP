import "dart:async";
import "dart:io";

import "package:autostarter/autostarter.dart";
import "package:disable_battery_optimization/disable_battery_optimization.dart";
import "package:dpip/global.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:permission_handler/permission_handler.dart";

import "../../../core/service.dart";
import "../../location_selector/location_selector.dart";

final stateSettingsLocationView = _SettingsLocationViewState();

typedef PositionUpdateCallback = void Function();

class SettingsLocationView extends StatefulWidget {
  final Function(String?, String?)? onPositionUpdate;

  const SettingsLocationView({super.key, this.onPositionUpdate});

  @override
  State<SettingsLocationView> createState() => _SettingsLocationViewState();

  static PositionUpdateCallback? _activeCallback;

  static void setActiveCallback(PositionUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updatePosition() {
    _activeCallback?.call();
  }
}

class _SettingsLocationViewState extends State<SettingsLocationView> with WidgetsBindingObserver {
  static const platform = MethodChannel("com.exptech.dpip/location");
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  PermissionStatus? notificationPermission;
  PermissionStatus? locationPermission;
  PermissionStatus? locationAlwaysPermission;
  bool? autoStartPermission;
  bool? batteryOptimizationPermission;

  String? city;
  String? town;
  int code = -1;

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
              "${context.i18n.auto_location_permission_required}${status.isPermanentlyDenied ? context.i18n.please_allow_notification_permission : ""}",
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
              "${context.i18n.location_permission_needed}${status.isPermanentlyDenied ? context.i18n.please_allow_location_permission : ""}",
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
      final permissionType = Platform.isAndroid ? context.i18n.always_allow : context.i18n.always;

      final status = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: Text("$permissionType${context.i18n.location_permission}"),
                content: Text(context.i18n.improve_auto_location_experience(permissionType.toString())),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    child: Text(context.i18n.cancel),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  FilledButton(
                    child: Text(context.i18n.confirm),
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
      if (isAvailable == null || !isAvailable) return true;

      bool? status = await Autostarter.checkAutoStartState();
      if (status == null) return true;
      if (status) return status;

      if (!mounted) return true;

      String contentText =
          (num == 0) ? context.i18n.auto_start_permission_info : context.i18n.auto_start_permission_experience;

      return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: Text(context.i18n.auto_start_permission),
                content: Text(contentText),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    child: Text(context.i18n.cancel),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  FilledButton(
                    child: Text(context.i18n.confirm),
                    onPressed: () async {
                      await Autostarter.getAutoStartPermission(newTask: true);

                      if (!context.mounted) return;
                      Navigator.pop(context, false);
                    },
                  ),
                ],
              );
            },
          ) ??
          false;
    } catch (err) {
      return false;
    }
  }

  Future<bool> androidCheckBatteryOptimizationPermission(int num) async {
    if (Platform.isIOS) return true;
    try {
      bool status = await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
      if (status) return true;
      if (!mounted) return true;

      String contentText =
          (num == 0) ? context.i18n.auto_location_experience_info : context.i18n.unlimited_permission_experience_info;

      return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: Text(context.i18n.power_saving_strategy),
                content: Text(contentText),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    child: Text(context.i18n.cancel),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  FilledButton(
                    child: Text(context.i18n.confirm),
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
    } catch (err) {
      return false;
    }
  }

  Future toggleAutoLocation() async {
    if (Platform.isIOS) {
      try {
        await platform.invokeMethod("toggleLocation", {"isEnabled": !isAutoLocatingEnabled});
      } catch (e) {
        return;
      }
    } else if (Platform.isAndroid) {
      androidstopBackgroundService(isAutoLocatingEnabled);
    }

    Global.preference.remove("user-code");
    Global.preference.remove("user-lat");
    Global.preference.remove("user-lon");

    if (isAutoLocatingEnabled) {
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
      autoStartPermission = autoStart;

      if (!autoStart) return;

      bool batteryOptimization = await androidCheckBatteryOptimizationPermission(0);
      batteryOptimizationPermission = batteryOptimization;

      if (!batteryOptimization) return;

      if (Platform.isAndroid) {
        androidStartBackgroundService(false);
      }

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

    code = Global.preference.getInt("user-code") ?? -1;
    if (code != -1) {
      city = Global.location[code.toString()]?.city;
      town = Global.location[code.toString()]?.town;
    }
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
        setState(() {
          locationAlwaysPermission = value;
        });
      },
    );
    setState(() async {
      autoStartPermission = await Autostarter.checkAutoStartState() ?? false;
      try {
        batteryOptimizationPermission = await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
      } catch (err) {
        batteryOptimizationPermission = false;
      }
    });
  }

  void sendpositionUpdate() {
    if (mounted) {
      code = Global.preference.getInt("user-code") ?? -1;
      if (code != -1) {
        city = Global.location[code.toString()]?.city;
        town = Global.location[code.toString()]?.town;
      }
      setState(() {});
      widget.onPositionUpdate?.call(city, town);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionType = Platform.isAndroid ? context.i18n.always_allow : context.i18n.always;
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              tileColor: isAutoLocatingEnabled ? context.colors.primaryContainer : context.colors.surfaceContainer,
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
                        context.i18n.auto_location_permission_upgrade_needed(permissionType.toString()),
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
                        context.i18n.notification_permission_denied,
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
          if (autoStartPermission != null)
            Visibility(
              visible: isAutoLocatingEnabled && !autoStartPermission!,
              maintainAnimation: true,
              maintainState: true,
              child: AnimatedOpacity(
                opacity: isAutoLocatingEnabled && !autoStartPermission! ? 1 : 0,
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
                        context.i18n.autoStart_permission_denied,
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                    TextButton(
                      child: Text(context.i18n.settings),
                      onPressed: () async {
                        await Autostarter.getAutoStartPermission(newTask: true);
                      },
                    ),
                  ]),
                ),
              ),
            ),
          if (batteryOptimizationPermission != null)
            Visibility(
              visible: isAutoLocatingEnabled && !batteryOptimizationPermission!,
              maintainAnimation: true,
              maintainState: true,
              child: AnimatedOpacity(
                opacity: isAutoLocatingEnabled && !batteryOptimizationPermission! ? 1 : 0,
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
                        context.i18n.batteryOptimization_permission_denied,
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                    TextButton(
                      child: Text(context.i18n.settings),
                      onPressed: () {
                        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
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
              if (!context.mounted) return;

              await Navigator.of(
                context,
                rootNavigator: true,
              ).push(
                MaterialPageRoute(
                  builder: (context) => LocationSelectorRoute(city: null, town: town),
                ),
              );

              setState(() {
                sendpositionUpdate();
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
              if (!context.mounted) return;

              await Navigator.of(
                context,
                rootNavigator: true,
              ).push(
                MaterialPageRoute(
                  builder: (context) => LocationSelectorRoute(city: city, town: town),
                ),
              );

              setState(() {
                sendpositionUpdate();
              });
            },
          )
        ],
      ),
    );
  }
}
