import 'dart:io';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/settings/location/select/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/toast.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
      // if (Platform.isAndroid) Autostarter.checkAutoStartState(),
      if (Platform.isAndroid) DisableBatteryOptimization.isBatteryOptimizationDisabled,
    ]);

    if (!mounted) return;

    setState(() {
      notificationPermission = values[0] as PermissionStatus?;
      locationPermission = values[1] as PermissionStatus?;
      locationAlwaysPermission = values[2] as PermissionStatus?;
      autoStartPermission = true;
      batteryOptimizationPermission = !Platform.isAndroid || (values[3] as bool? ?? true);
    });
  }

  /// Shows a error dialog to the user with the given permission type. [type] can be either [Permission] or
  /// `"auto-start"`
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
      // final available = await Autostarter.isAutoStartPermissionAvailable();
      // if (available == null) break autoStart;

      final status = await DisableBatteryOptimization.isAutoStartEnabled;
      if (status == null || status) {
        batteryOptimizationPermission = true;
        break autoStart;
      }

      await DisableBatteryOptimization.showEnableAutoStartSettings(
        '自動啟動'.i18n,
        '為了獲得更好的 DPIP 體驗，請依照步驟啟用自動啟動功能，以便讓 DPIP 在背景能正常接收資訊以及更新所在地。'.i18n,
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
        '省電策略'.i18n,
        '為了獲得更好的 DPIP 體驗，請依照步驟關閉省電策略，以便讓 DPIP 在背景能正常接收資訊以及更新所在地。'.i18n,
      );
    }

    setState(() {});
    return true;
  }

  Future toggleAutoLocation(bool shouldEnable) async {
    if (shouldEnable) {
      if (!await requestPermissions()) return;

      GlobalProviders.location.setAuto(shouldEnable);
      await LocationServiceManager.initalize();
    } else {
      await LocationServiceManager.stop();
      GlobalProviders.location.setAuto(shouldEnable);
    }
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
    final permissionType = Platform.isAndroid ? '一律允許'.i18n : '永遠'.i18n;

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
                            '自動定位功能需要將位置權限提升至「$permissionType」以在背景使用。'.i18n,
                            style: TextStyle(color: context.colors.error),
                          ),
                        ),
                        TextButton(child: Text('設定'.i18n), onPressed: () => openAppSettings()),
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
                          child: Text('通知功能已被拒絕，請移至設定允許權限。'.i18n, style: TextStyle(color: context.colors.error)),
                        ),
                        TextButton(child: Text('設定'.i18n), onPressed: () => openAppSettings()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        /* if (Platform.isAndroid)
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
                    content: '自啟動權限已被拒絕，請移至設定允許權限。'.i18n,
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: Text('設定'.i18n),
                      onPressed: () => Autostarter.getAutoStartPermission(newTask: true),
                    ),
                  ),
                ),
              );
            },
          ),*/
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
                    content: '省電策略已被拒絕，請移至設定允許權限。'.i18n,
                    contentColor: context.colors.error,
                    trailing: TextButton(
                      child: Text('設定'.i18n),
                      onPressed: () {
                        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        Consumer<SettingsLocationModel>(
          builder: (context, model, child) {
            String? loadingCode;

            return StatefulBuilder(
              builder: (context, setState) {
                return ListSection(
                  title: '所在地'.i18n,
                  children: [
                    ...model.favorited.map((code) {
                      final location = Global.location[code]!;
                      final isCurrentLoading = loadingCode == code;
                      final isSelected = code == model.code;

                      return ListSectionTile(
                        title: location.cityTownWithLevel,
                        subtitle: Text(
                          '$code・${location.lng.toStringAsFixed(2)}°E・${location.lat.toStringAsFixed(2)}°N',
                        ),
                        leading: isCurrentLoading
                            ? const LoadingIcon()
                            : Icon(isSelected ? Symbols.check_rounded : null, color: context.colors.primary),
                        trailing: IconButton(
                          icon: const Icon(Symbols.delete_rounded),
                          color: context.colors.error,
                          onPressed: isCurrentLoading ? null : () => model.unfavorite(code),
                        ),
                        enabled: !model.auto && loadingCode == null,
                        onTap: isSelected
                            ? null
                            : () async {
                                setState(() => loadingCode = code);
                                try {
                                  await ExpTech().updateDeviceLocation(
                                    token: Preference.notifyToken,
                                    coordinates: LatLng(location.lat, location.lng),
                                  );

                                  if (!context.mounted) return;
                                  model.setCode(code);
                                } catch (e, s) {
                                  if (!context.mounted) return;
                                  TalkerManager.instance.error('Failed to set location code', e, s);
                                  showToast(context, ToastWidget.text('設定所在地時發生錯誤，請稍候再試一次。'.i18n));
                                }
                                setState(() => loadingCode = null);
                              },
                      );
                    }),
                    ListSectionTile(
                      title: '新增地點'.i18n,
                      icon: Symbols.add_circle_rounded,
                      enabled: loadingCode == null,
                      onTap: () => context.push(SettingsLocationSelectPage.route),
                    ),
                  ],
                );
              },
            );
          },
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
