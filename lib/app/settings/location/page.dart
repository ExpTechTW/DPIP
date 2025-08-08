import 'dart:io';

import 'package:flutter/material.dart';

import 'package:autostarter/autostarter.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/settings/location/select/%5Bcity%5D/page.dart';
import 'package:dpip/app/settings/location/select/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';

final stateSettingsLocationView = _SettingsLocationPageState();

typedef PositionUpdateCallback = void Function();

class SettingsLocationPage extends StatefulWidget {
  static const route = '/settings/location';

  const SettingsLocationPage({super.key});

  @override
  State<SettingsLocationPage> createState() => _SettingsLocationPageState();
}

class _SettingsLocationPageState extends State<SettingsLocationPage> with WidgetsBindingObserver {
  PermissionStatus? notificationPermission;
  PermissionStatus? locationPermission;
  PermissionStatus? locationAlwaysPermission;
  bool autoStartPermission = true;
  bool batteryOptimizationPermission = true;

  Future<void> permissionStatusUpdate() async {
    final values = await Future.wait([
      Permission.notification.status,
      Permission.location.status,
      Permission.locationAlways.status,
      if (Platform.isAndroid) Autostarter.checkAutoStartState(),
      if (Platform.isAndroid) DisableBatteryOptimization.isBatteryOptimizationDisabled,
    ]);

    if (!mounted) return;

    setState(() {
      notificationPermission = values[0] as PermissionStatus?;
      locationPermission = values[1] as PermissionStatus?;
      locationAlwaysPermission = values[2] as PermissionStatus?;
      autoStartPermission = values[3] as bool? ?? true;
      batteryOptimizationPermission = values[4] as bool? ?? true;
    });
  }

  /// Shows a error dialog to the user with the given permission type.
  /// [type] can be either [Permission] or `"auto-start"`
  Future<void> showPermissionDialog(dynamic type) async {
    if (!mounted) return;
    if (type is! Permission && type is! String) return;

    final title = switch (type) {
      Permission.notification => '無法取得通知權限'.i18n,
      Permission.location => '無法取得位置權限'.i18n,
      Permission.locationAlways => '無法取得位置權限'.i18n,
      'auto-start' => '無法取得自啟動權限'.i18n,
      'battery-optimization' => '省電策略'.i18n,
      _ => '無法取得權限'.i18n,
    };

    final content = switch (type) {
      Permission.notification => '自動定位功能需要您允許 DPIP 使用通知權限才能正常運作。請您到應用程式設定中找到並允許「通知」權限後再試一次。'.i18n,
      Permission.location => '自動定位功能需要您允許 DPIP 使用位置權限才能正常運作。請您到應用程式設定中找到並允許「位置」權限後再試一次。'.i18n,
      Permission.locationAlways =>
        Platform.isIOS
            ? '自動定位功能需要您永遠允許 DPIP 使用位置權限才能正常運作。請您到應用程式設定中找到位置權限設定並選擇「永遠」後再試一次。'.i18n
            : '自動定位功能需要您一律允許 DPIP 使用位置權限才能正常運作。請您到應用程式設定中找到位置權限設定並選擇「一律允許」後再試一次。'.i18n,
      'auto-start' => '為了獲得更好的自動定位體驗，您需要給予「自啟動權限」以便讓 DPIP 在背景自動設定所在地資訊。'.i18n,
      'battery-optimization' => '為了獲得更好的自動定位體驗，您需要給予「無限制」以便讓 DPIP 在背景自動設定所在地資訊。'.i18n,
      _ => '自動定位功能需要您允許 DPIP 使用權限才能正常運作。請您到應用程式設定中找到並允許「權限」後再試一次。'.i18n,
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Symbols.error_rounded),
          title: Text(title),
          content: Text(content),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: Text('取消'.i18n),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FilledButton(
              child: Text('設定'.i18n),
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> requestPermissions() async {
    if (!await Permission.notification.request().isGranted) {
      TalkerManager.instance.warning('🧪 failed notification (NOTIFICATION) permission test');
      await showPermissionDialog(Permission.notification);
      return false;
    }

    if (!await Permission.location.request().isGranted) {
      TalkerManager.instance.warning('🧪 failed location (ACCESS_COARSE_LOCATION) permission test');
      showPermissionDialog(Permission.location);
      return false;
    }

    if (!await Permission.locationWhenInUse.request().isGranted) {
      TalkerManager.instance.warning('🧪 failed location when in use (ACCESS_FINE_LOCATION) permission test');
      showPermissionDialog(Permission.locationWhenInUse);
      return false;
    }

    if (!await Permission.locationAlways.request().isGranted) {
      TalkerManager.instance.warning('🧪 failed location always (ACCESS_BACKGROUND_LOCATION) permission test');
      showPermissionDialog(Permission.locationAlways);
      return false;
    }

    if (!Platform.isAndroid) return true;

    autoStart:
    {
      final available = await Autostarter.isAutoStartPermissionAvailable();
      if (available == null) break autoStart;

      final status = await DisableBatteryOptimization.isAutoStartEnabled;
      if (status == null || status) {
        batteryOptimizationPermission = true;
        break autoStart;
      }

      await DisableBatteryOptimization.showEnableAutoStartSettings(
        '自動啟動',
        '為了獲得更好的 DPIP 體驗，請依照步驟啟用自動啟動功能，以便讓 DPIP 在背景能正常接收資訊以及更新所在地。',
      );
    }

    batteryOptimization:
    {
      final status = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
      if (status == null || status) {
        batteryOptimizationPermission = true;
        break batteryOptimization;
      }

      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    }

    manufacturerBatteryOptimization:
    {
      final status = await DisableBatteryOptimization.isManufacturerBatteryOptimizationDisabled;
      if (status == null || status) break manufacturerBatteryOptimization;

      await DisableBatteryOptimization.showEnableAutoStartSettings(
        '省電策略',
        '為了獲得更好的 DPIP 體驗，請依照步驟關閉省電策略，以便讓 DPIP 在背景能正常接收資訊以及更新所在地。',
      );
    }

    setState(() {});
    return true;
  }

  Future toggleAutoLocation(bool shouldEnable) async {
    if (shouldEnable) {
      if (!await requestPermissions()) return;

      await BackgroundLocationServiceManager.start();
    } else {
      await BackgroundLocationServiceManager.stop();
    }

    GlobalProviders.location.setAuto(shouldEnable);
    GlobalProviders.location.setCode(null);
    GlobalProviders.location.setCoordinates(null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    permissionStatusUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    permissionStatusUpdate();
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
                  title: '自動更新'.i18n,
                  subtitle: Text('定期更新目前的所在地'.i18n),
                  icon: Symbols.my_location_rounded,
                  trailing: Switch(value: auto, onChanged: toggleAutoLocation),
                );
              },
            ),
          ],
        ),
        SettingsListTextSection(
          icon: Symbols.info_rounded,
          content: '自動定位功能將使用您的裝置上的 GPS，即使 DPIP 關閉或未在使用時，也會根據您的地理位置，自動更新您的所在地，提供即時的天氣和地震資訊，讓您隨時掌握當地最新狀況。'.i18n,
        ),
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
                        Expanded(child: Text('通知功能已被拒絕，請移至設定允許權限。', style: TextStyle(color: context.colors.error))),
                        TextButton(child: const Text('設定'), onPressed: () => openAppSettings()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (Platform.isAndroid)
          Selector<SettingsLocationModel, bool>(
            selector: (context, model) => model.auto,
            builder: (context, auto, child) {
              return Visibility(
                visible: auto && !autoStartPermission,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: auto && !autoStartPermission ? 1 : 0,
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
        if (Platform.isAndroid)
          Selector<SettingsLocationModel, bool>(
            selector: (context, model) => model.auto,
            builder: (context, auto, child) {
              return Visibility(
                visible: auto && !batteryOptimizationPermission,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: auto && !batteryOptimizationPermission ? 1 : 0,
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
          title: '所在地'.i18n,
          children: [
            Selector<SettingsLocationModel, ({bool auto, String? code})>(
              selector: (context, model) => (auto: model.auto, code: model.code),
              builder: (context, data, child) {
                final (:auto, :code) = data;
                final city = Global.location[code]?.city;

                return ListSectionTile(
                  title: '直轄市/縣市'.i18n,
                  subtitle: Text(city ?? '尚未設定'.i18n),
                  icon: Symbols.location_city_rounded,
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  enabled: !auto,
                  onTap: () => context.push(SettingsLocationSelectPage.route),
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
                  title: '鄉鎮市區'.i18n,
                  subtitle: Text(town ?? '尚未設定'.i18n),
                  icon: Symbols.forest_rounded,
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  enabled: !auto && city != null,
                  onTap: city == null ? null : () => context.push(SettingsLocationSelectCityPage.route(city)),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
