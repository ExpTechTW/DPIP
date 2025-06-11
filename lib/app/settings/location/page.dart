import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:autostarter/autostarter.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/app/settings/location/select/%5Bcity%5D/page.dart';
import 'package:dpip/app/settings/location/select/page.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';

final stateSettingsLocationView = _SettingsLocationPageState();

typedef PositionUpdateCallback = void Function();

class SettingsLocationPage extends StatefulWidget {
  static const route = '/settings/location';

  const SettingsLocationPage({super.key});

  @override
  State<SettingsLocationPage> createState() => _SettingsLocationPageState();
}

const platform = MethodChannel('com.exptech.dpip/location');

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
            title: const Text('無法取得通知權限'),
            content: Text(
              "'自動定位功能需要您允許 DPIP 使用通知權限才能正常運作。'${status.isPermanentlyDenied ? '請您到應用程式設定中找到並允許「通知」權限後再試一次。' : ""}",
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              if (status.isPermanentlyDenied)
                FilledButton(
                  child: const Text('設定'),
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                )
              else
                FilledButton(
                  child: const Text('再試一次'),
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
            title: const Text('無法取得位置權限'),
            content: Text(
              "'自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。'${status.isPermanentlyDenied ? '請您到應用程式設定中找到並允許「位置」權限後再試一次。' : ""}",
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              if (status.isPermanentlyDenied)
                FilledButton(
                  child: const Text('設定'),
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                )
              else
                FilledButton(
                  child: const Text('再試一次'),
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
      final permissionType = Platform.isAndroid ? '一律允許' : '永遠';

      final status =
          await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: Text('$permissionType 位置權限'),
                content: Text('為了獲得更好的自動定位體驗，您需要將位置權限提升至「$permissionType」以便讓 DPIP 在背景自動設定所在地資訊。'),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  FilledButton(
                    child: const Text('確定'),
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
      final bool? isAvailable = await Autostarter.isAutoStartPermissionAvailable();
      if (isAvailable == null || !isAvailable) return true;

      final bool? status = await Autostarter.checkAutoStartState();
      if (status == null || status) return true;

      if (!mounted) return true;

      final String contentText =
          (num == 0) ? '為了獲得更好的自動定位體驗，您需要給予「自啟動權限」以便讓 DPIP 在背景自動設定所在地資訊。' : '為了獲得更好的 DPIP 體驗，您需要給予「自啟動權限」以便讓 DPIP 在背景有正常接收警訊通知。';

      return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: const Text('自啟動權限'),
                content: Text(contentText),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  FilledButton(
                    child: const Text('確定'),
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
      final bool status = await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
      if (status) return true;

      if (!mounted) return true;

      final String contentText =
          (num == 0) ? '為了獲得更好的自動定位體驗，您需要給予「無限制」以便讓 DPIP 在背景自動設定所在地資訊。' : '為了獲得更好的 DPIP 體驗，您需要給予「無限制」以便讓 DPIP 在背景有正常接收警訊通知。';

      return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.my_location),
                title: const Text('省電策略'),
                content: Text(contentText),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  FilledButton(
                    child: const Text('確定'),
                    onPressed: () {
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

      final bool autoStart = await androidCheckAutoStartPermission(0);
      autoStartPermission = autoStart;
      if (!autoStart) return;

      final bool batteryOptimization = await androidCheckBatteryOptimizationPermission(0);
      batteryOptimizationPermission = batteryOptimization;
      if (!batteryOptimization) return;

      stopAndroidBackgroundService();

      if (!isAuto) {
        startAndroidBackgroundService(shouldInitialize: false);
      }
    }

    if (Platform.isIOS) {
      await platform.invokeMethod('toggleLocation', {'isEnabled': !isAuto}).catchError((_) {});
    }

    if (!mounted) return;

    context.read<SettingsLocationModel>().setAuto(!isAuto);
    context.read<SettingsLocationModel>().setCode(null);
    context.read<SettingsLocationModel>().setLatLng();
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

  @override
  Widget build(BuildContext context) {
    final permissionType = Platform.isAndroid ? '一律允許' : '永遠';

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          children: [
            Selector<SettingsLocationModel, bool>(
              selector: (context, model) => model.auto,
              builder: (context, auto, child) {
                return ListSectionTile(
                  title: '自動定位',
                  subtitle: const Text('自動更新所在地'),
                  icon: Symbols.my_location_rounded,
                  trailing: Switch(value: auto, onChanged: (value) => toggleAutoLocation()),
                );
              },
            ),
          ],
        ),
        const SettingsListTextSection(icon: Symbols.info_rounded, content: '自動定位功能將使用您的裝置上的 GPS，即使 DPIP 關閉或未在使用時，也會根據您的地理位置，自動更新您的所在地，提供即時的天氣和地震資訊，讓您隨時掌握當地最新狀況。'),
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
                            '自動定位功能需要將位置權限提升至「$permissionType」以在背景使用。',
                            style: TextStyle(color: context.colors.error),
                          ),
                        ),
                        TextButton(child: const Text('設定'), onPressed: () => openAppSettings()),
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
                            '通知功能已被拒絕，請移至設定允許權限。',
                            style: TextStyle(color: context.colors.error),
                          ),
                        ),
                        TextButton(child: const Text('設定'), onPressed: () => openAppSettings()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (Platform.isAndroid && false)
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
                    content: '自啟動權限已被拒絕，請移至設定允許權限。',
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: const Text('設定'),
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
                    content: '省電策略已被拒絕，請移至設定允許權限。',
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: const Text('設定'),
                      onPressed: () {
                        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ListSection(
          title: '所在地',
          children: [
            Selector<SettingsLocationModel, ({bool auto, String? code})>(
              selector: (context, model) => (auto: model.auto, code: model.code),
              builder: (context, data, child) {
                final (:auto, :code) = data;
                final city = Global.location[code]?.city;

                return ListSectionTile(
                  title: '縣市',
                  subtitle: Text(city ?? '尚未設定'),
                  icon: Symbols.location_city_rounded,
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  enabled: !auto,
                  onTap: () async {
                    final bool autoStart = await androidCheckAutoStartPermission(1);
                    if (!autoStart) return;

                    final bool batteryOptimization = await androidCheckBatteryOptimizationPermission(1);
                    if (!batteryOptimization) return;

                    if (!context.mounted) return;

                    context.push(SettingsLocationSelectPage.route);
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

                return ListSectionTile(
                  title: '鄉鎮',
                  subtitle: Text(town ?? '尚未設定'),
                  icon: Symbols.forest_rounded,
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  enabled: !auto && city != null,
                  onTap: () async {
                    if (city == null) return;

                    final bool autoStart = await androidCheckAutoStartPermission(1);
                    if (!autoStart) return;

                    final bool batteryOptimization = await androidCheckBatteryOptimizationPermission(1);
                    if (!batteryOptimization) return;

                    if (!context.mounted) return;

                    context.push(SettingsLocationSelectCityPage.route(city));
                  },
                );
              },
            ),
          ],
        ),
        if (false && Platform.isAndroid)
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
                    content: '自啟動權限已被拒絕，請移至設定允許權限。',
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: const Text('設定'),
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
                    content: '省電策略已被拒絕，請移至設定允許權限。',
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: const Text('設定'),
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
