import "dart:async";
import "dart:io";

import "package:autostarter/autostarter.dart";
import "package:disable_battery_optimization/disable_battery_optimization.dart";
import "package:dpip/app/settings/_widgets/list_section.dart";
import "package:dpip/app/settings/_widgets/list_tile.dart";
import "package:dpip/core/service.dart";
import "package:dpip/global.dart";
import "package:dpip/models/settings/location.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/log.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:permission_handler/permission_handler.dart";
import "package:provider/provider.dart";

final stateSettingsLocationView = _SettingsLocationPageState();

typedef PositionUpdateCallback = void Function();

class SettingsLocationPage extends StatefulWidget {
  final Function(String?, String?)? onPositionUpdate;

  const SettingsLocationPage({super.key, this.onPositionUpdate});

  @override
  State<SettingsLocationPage> createState() => _SettingsLocationPageState();
}

const platform = MethodChannel("com.exptech.dpip/location");

class _SettingsLocationPageState extends State<SettingsLocationPage> with WidgetsBindingObserver {
  PermissionStatus? notificationPermission;
  PermissionStatus? locationPermission;
  PermissionStatus? locationAlwaysPermission;
  bool? autoStartPermission;
  bool? batteryOptimizationPermission;

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

      final status =
          await showDialog<bool>(
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
    if (!Platform.isAndroid) return true;

    try {
      bool? isAvailable = await Autostarter.isAutoStartPermissionAvailable();
      if (isAvailable == null || !isAvailable) return true;

      bool? status = await Autostarter.checkAutoStartState();
      if (status == null || status) return true;

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
      TalkerManager.instance.error(err);
      return false;
    }
  }

  Future<bool> androidCheckBatteryOptimizationPermission(int num) async {
    if (!Platform.isAndroid) return true;

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
      TalkerManager.instance.error(err);
      return false;
    }
  }

  Future toggleAutoLocation() async {
    final isAuto = context.read<SettingsLocationModel>().auto;

    if (!isAuto) {
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

      androidStopBackgroundService(!isAuto);

      if (!isAuto) {
        androidStartBackgroundService(false);
      }
    }

    if (Platform.isIOS) {
      await platform.invokeMethod("toggleLocation", {"isEnabled": !isAuto}).catchError((_) {});
    }

    if (!mounted) return;

    context.read<SettingsLocationModel>().setAuto(!isAuto);
    context.read<SettingsLocationModel>().setCode(null);
    context.read<SettingsLocationModel>().setLongitude(null);
    context.read<SettingsLocationModel>().setLatitude(null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    permissionStatusUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    permissionStatusUpdate();
  }

  void permissionStatusUpdate() {
    Permission.notification.status.then((value) {
      setState(() {
        notificationPermission = value;
      });
    });
    Permission.location.status.then((value) {
      setState(() {
        locationPermission = value;
      });
    });
    Permission.locationAlways.status.then((value) {
      setState(() {
        locationAlwaysPermission = value;
      });
    });
    if (Platform.isAndroid) {
      Future<void> checkAutoStart() async {
        final autoStart = await Autostarter.checkAutoStartState();
        if (mounted) {
          setState(() {
            autoStartPermission = autoStart ?? false;
          });
        }
      }

      Future<void> checkBatteryOptimization() async {
        final batteryOptimization = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
        if (mounted) {
          setState(() {
            batteryOptimizationPermission = batteryOptimization ?? false;
          });
        }
      }

      checkAutoStart();
      checkBatteryOptimization();
    }
  }

  void updateLocation(String? code) {
    final city = Global.location[code.toString()]?.city;
    final town = Global.location[code.toString()]?.town;

    widget.onPositionUpdate?.call(city, town);
  }

  @override
  Widget build(BuildContext context) {
    final permissionType = Platform.isAndroid ? context.i18n.always_allow : context.i18n.always;
    return ListView(
      children: [
        SettingsListSection(
          children: [
            Selector<SettingsLocationModel, bool>(
              selector: (context, model) => model.auto,
              builder: (context, auto, child) {
                return SettingsListTile(
                  title: context.i18n.settings_location_auto,
                  subtitle: Text('自動更新所在地'),
                  icon: Symbols.my_location_rounded,
                  trailing: Switch(value: auto, onChanged: (value) => toggleAutoLocation()),
                );
              },
            ),
          ],
        ),
        SettingsListTextSection(icon: Symbols.info_rounded, content: context.i18n.settings_location_auto_description),
        if (locationAlwaysPermission != null)
          Selector<SettingsLocationModel, bool>(
            selector: (context, model) => model.auto,
            builder: (context, auto, child) {
              return Visibility(
                visible: auto && !locationAlwaysPermission!.isGranted,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: auto && !locationAlwaysPermission!.isGranted ? 1 : 0,
                  curve: const Interval(0.2, 1, curve: Easing.standard),
                  duration: Durations.medium2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Symbols.warning_rounded, color: context.colors.error),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.i18n.auto_location_permission_upgrade_needed(permissionType.toString()),
                            style: TextStyle(color: context.colors.error),
                          ),
                        ),
                        TextButton(child: Text(context.i18n.settings), onPressed: () => openAppSettings()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (notificationPermission != null)
          Selector<SettingsLocationModel, bool>(
            selector: (context, model) => model.auto,
            builder: (context, auto, child) {
              return Visibility(
                visible: auto && !notificationPermission!.isGranted,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: auto && !notificationPermission!.isGranted ? 1 : 0,
                  curve: const Interval(0.2, 1, curve: Easing.standard),
                  duration: Durations.medium2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Symbols.warning_rounded, color: context.colors.error),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.i18n.notification_permission_denied,
                            style: TextStyle(color: context.colors.error),
                          ),
                        ),
                        TextButton(child: Text(context.i18n.settings), onPressed: () => openAppSettings()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (Platform.isAndroid && autoStartPermission != null)
          Selector<SettingsLocationModel, bool>(
            selector: (context, model) => model.auto,
            builder: (context, auto, child) {
              return Visibility(
                visible: auto && !autoStartPermission!,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: auto && !autoStartPermission! ? 1 : 0,
                  curve: const Interval(0.2, 1, curve: Easing.standard),
                  duration: Durations.medium2,
                  child: SettingsListTextSection(
                    icon: Symbols.warning_rounded,
                    iconColor: context.colors.error,
                    content: context.i18n.autoStart_permission_denied,
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: Text(context.i18n.settings),
                      onPressed: () => Autostarter.getAutoStartPermission(newTask: true),
                    ),
                  ),
                ),
              );
            },
          ),
        if (batteryOptimizationPermission != null && Platform.isAndroid)
          Selector<SettingsLocationModel, bool>(
            selector: (context, model) => model.auto,
            builder: (context, auto, child) {
              return Visibility(
                visible: auto && !batteryOptimizationPermission!,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: auto && !batteryOptimizationPermission! ? 1 : 0,
                  curve: const Interval(0.2, 1, curve: Easing.standard),
                  duration: Durations.medium2,
                  child: SettingsListTextSection(
                    icon: Symbols.warning_rounded,
                    iconColor: context.colors.error,
                    content: context.i18n.batteryOptimization_permission_denied,
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: Text(context.i18n.settings),
                      onPressed: () {
                        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        SettingsListSection(
          title: context.i18n.settings_location,
          children: [
            Selector<SettingsLocationModel, ({bool auto, String? code})>(
              selector: (context, model) => (auto: model.auto, code: model.code),
              builder: (context, data, child) {
                final (:auto, :code) = data;
                final city = Global.location[code]?.city;

                return SettingsListTile(
                  title: context.i18n.location_city,
                  subtitle: Text(city ?? context.i18n.location_Not_set),
                  icon: Symbols.location_city_rounded,
                  trailing: Icon(Symbols.chevron_right_rounded),
                  enabled: !auto,
                  onTap: () async {
                    bool autoStart = await androidCheckAutoStartPermission(1);
                    if (!autoStart) return;

                    bool batteryOptimization = await androidCheckBatteryOptimizationPermission(1);
                    if (!batteryOptimization) return;

                    if (!context.mounted) return;

                    context.push('/settings/location/select');
                  },
                );
              },
            ),
            Selector<SettingsLocationModel, ({bool auto, String? code})>(
              selector: (context, model) => (auto: model.auto, code: model.code),
              builder: (context, data, child) {
                final (:auto, :code) = data;

                final city = Global.location[code]?.city;
                final town = Global.location[code]?.town;

                return SettingsListTile(
                  title: context.i18n.location_town,
                  subtitle: Text(town ?? context.i18n.location_Not_set),
                  icon: Symbols.forest_rounded,
                  trailing: Icon(Symbols.chevron_right_rounded),
                  enabled: !auto && city != null,
                  onTap: () async {
                    bool autoStart = await androidCheckAutoStartPermission(1);
                    if (!autoStart) return;

                    bool batteryOptimization = await androidCheckBatteryOptimizationPermission(1);
                    if (!batteryOptimization) return;

                    if (!context.mounted) return;

                    context.push('/settings/location/select/$city');
                  },
                );
              },
            ),
          ],
        ),
        if (autoStartPermission != null && Platform.isAndroid)
          Selector<SettingsLocationModel, ({bool auto, String? code})>(
            selector: (context, model) => (auto: model.auto, code: model.code),
            builder: (context, data, child) {
              final (:auto, :code) = data;

              return Visibility(
                visible: !auto && code != null && !autoStartPermission!,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: !auto && code != null && !autoStartPermission! ? 1 : 0,
                  curve: const Interval(0.2, 1, curve: Easing.standard),
                  duration: Durations.medium2,
                  child: SettingsListTextSection(
                    icon: Symbols.warning_rounded,
                    iconColor: context.colors.error,
                    content: context.i18n.autoStart_permission_denied,
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: Text(context.i18n.settings),
                      onPressed: () async {
                        await Autostarter.getAutoStartPermission(newTask: true);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        if (batteryOptimizationPermission != null && Platform.isAndroid)
          Selector<SettingsLocationModel, ({bool auto, String? code})>(
            selector: (context, model) => (auto: model.auto, code: model.code),
            builder: (context, data, child) {
              final (:auto, :code) = data;

              return Visibility(
                visible: !auto && code != null && !batteryOptimizationPermission!,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: !auto && code != null && !batteryOptimizationPermission! ? 1 : 0,
                  curve: const Interval(0.2, 1, curve: Easing.standard),
                  duration: Durations.medium2,
                  child: SettingsListTextSection(
                    icon: Symbols.warning_rounded,
                    iconColor: context.colors.error,
                    content: context.i18n.batteryOptimization_permission_denied,
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: Text(context.i18n.settings),
                      onPressed: () {
                        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
