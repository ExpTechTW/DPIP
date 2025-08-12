import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/notify/(1.eew)/eew/page.dart';
import 'package:dpip/app/settings/notify/(2.earthquake)/intensity/page.dart';
import 'package:dpip/app/settings/notify/(2.earthquake)/monitor/page.dart';
import 'package:dpip/app/settings/notify/(2.earthquake)/report/page.dart';
import 'package:dpip/app/settings/notify/(3.weather)/advisory/page.dart';
import 'package:dpip/app/settings/notify/(3.weather)/evacuation/page.dart';
import 'package:dpip/app/settings/notify/(3.weather)/thunderstorm/page.dart';
import 'package:dpip/app/settings/notify/(4.tsunami)/tsunami/page.dart';
import 'package:dpip/app/settings/notify/(5.basic)/announcement/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class SettingsNotifyPage extends StatefulWidget {
  const SettingsNotifyPage({super.key});

  static const name = 'notify';
  static const route = '/settings/$name';

  @override
  State<SettingsNotifyPage> createState() => _SettingsNotifyPageState();
}

class _SettingsNotifyPageState extends State<SettingsNotifyPage> {
  String getEewNotifyTypeName(EewNotifyType value) => switch (value) {
    EewNotifyType.localIntensityAbove4 => '所在地震度4以上'.i18n,
    EewNotifyType.localIntensityAbove1 => '所在地震度1以上'.i18n,
    EewNotifyType.all => '接收全部'.i18n,
  };

  String getEarthquakeNotifyTypeName(EarthquakeNotifyType value) => switch (value) {
    EarthquakeNotifyType.off => '關閉'.i18n,
    EarthquakeNotifyType.localIntensityAbove1 => '所在地震度1以上'.i18n,
    EarthquakeNotifyType.all => '接收全部'.i18n,
  };

  String getWeatherNotifyTypeName(WeatherNotifyType value) => switch (value) {
    WeatherNotifyType.off => '關閉'.i18n,
    WeatherNotifyType.local => '接收所在地'.i18n,
  };

  String getTsunamiNotifyTypeName(TsunamiNotifyType value) => switch (value) {
    TsunamiNotifyType.warningOnly => '只接收海嘯警報'.i18n,
    TsunamiNotifyType.all => '海嘯消息、海嘯警報'.i18n,
  };

  String getBasicNotifyTypeName(BasicNotifyType value) => switch (value) {
    BasicNotifyType.off => '關閉'.i18n,
    BasicNotifyType.all => '接收全部'.i18n,
  };

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (Preference.notifyEew == null ||
        Preference.notifyMonitor == null ||
        Preference.notifyReport == null ||
        Preference.notifyIntensity == null ||
        Preference.notifyThunderstorm == null ||
        Preference.notifyWeatherAdvisory == null ||
        Preference.notifyEvacuation == null ||
        Preference.notifyTsunami == null ||
        Preference.notifyAnnouncement == null) {
      setState(() => isLoading = true);
      ExpTech()
          .getNotify(token: Preference.notifyToken)
          .then((value) {
            GlobalProviders.notification.apply(value);
            setState(() => isLoading = false);
          })
          .catchError((error) {
            if (error.toString().contains('401')) {
              if (GlobalProviders.location.coordinates != null) {
                Future.delayed(const Duration(seconds: 2), () {
                  ExpTech()
                      .updateDeviceLocation(
                        token: Preference.notifyToken,
                        coordinates: GlobalProviders.location.coordinates!,
                      )
                      .then((_) {
                        if (mounted) {
                          context.pop();
                        }
                      })
                      .catchError((updateError) {
                        print('Failed to update location: $updateError');
                      });
                });
              }
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsLocationModel, String?>(
      selector: (_, model) => model.code,
      builder: (context, code, child) {
        final enabled = code != null || (Preference.locationAuto ?? false);

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: isLoading ? 1 : 0,
                duration: Durations.short4,
                child: const LinearProgressIndicator(year2023: false),
              ),
            ),
            ListView(
              padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
              children: [
                if (!enabled)
                  SettingsListTextSection(
                    icon: Symbols.warning_rounded,
                    content: '請先設定所在地來使用通知功能'.i18n,
                    trailing: TextButton(
                      onPressed: () => context.push(SettingsLocationPage.route),
                      child: Text('設定'.i18n),
                    ),
                  ),
                ListSection(
                  title: '地震速報'.i18n,
                  children: [
                    Selector<SettingsNotificationModel, EewNotifyType>(
                      selector: (_, model) => model.eew,
                      builder: (context, eew, child) {
                        return ListSectionTile(
                          title: '緊急地震速報'.i18n,
                          subtitle: Text(getEewNotifyTypeName(eew)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.crisis_alert_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyEewPage.route),
                        );
                      },
                    ),
                  ],
                ),
                ListSection(
                  title: '地震'.i18n,
                  children: [
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.monitor,
                      builder: (context, monitor, child) {
                        return ListSectionTile(
                          title: '強震監視器'.i18n,
                          subtitle: Text(getEarthquakeNotifyTypeName(monitor)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.monitor_heart_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyMonitorPage.route),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.report,
                      builder: (context, report, child) {
                        return ListSectionTile(
                          title: '地震報告'.i18n,
                          subtitle: Text(getEarthquakeNotifyTypeName(report)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.docs_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyReportPage.route),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.intensity,
                      builder: (context, intensity, child) {
                        return ListSectionTile(
                          title: '震度速報'.i18n,
                          subtitle: Text(getEarthquakeNotifyTypeName(intensity)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.summarize_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyIntensityPage.route),
                        );
                      },
                    ),
                  ],
                ),
                ListSection(
                  title: '天氣'.i18n,
                  children: [
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.thunderstorm,
                      builder: (context, thunderstorm, child) {
                        return ListSectionTile(
                          title: '雷雨即時訊息'.i18n,
                          subtitle: Text(getWeatherNotifyTypeName(thunderstorm)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.thunderstorm_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyThunderstormPage.route),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.weatherAdvisory,
                      builder: (context, weatherAdvisory, child) {
                        return ListSectionTile(
                          title: '天氣警特報'.i18n,
                          subtitle: Text(getWeatherNotifyTypeName(weatherAdvisory)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.warning_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyAdvisoryPage.route),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.evacuation,
                      builder: (context, evacuation, child) {
                        return ListSectionTile(
                          title: '防災資訊'.i18n,
                          subtitle: Text(getWeatherNotifyTypeName(evacuation)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.directions_run_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyEvacuationPage.route),
                        );
                      },
                    ),
                  ],
                ),
                ListSection(
                  title: '海嘯'.i18n,
                  children: [
                    Selector<SettingsNotificationModel, TsunamiNotifyType>(
                      selector: (_, model) => model.tsunami,
                      builder: (context, tsunami, child) {
                        return ListSectionTile(
                          title: '海嘯資訊'.i18n,
                          subtitle: Text(getTsunamiNotifyTypeName(tsunami)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.tsunami_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyTsunamiPage.route),
                        );
                      },
                    ),
                  ],
                ),
                ListSection(
                  title: '其他'.i18n,
                  children: [
                    Selector<SettingsNotificationModel, BasicNotifyType>(
                      selector: (_, model) => model.announcement,
                      builder: (context, announcement, child) {
                        return ListSectionTile(
                          title: '公告'.i18n,
                          subtitle: Text(getBasicNotifyTypeName(announcement)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          icon: Symbols.campaign_rounded,
                          enabled: !isLoading && enabled,
                          onTap: () => context.push(SettingsNotifyAnnouncementPage.route),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
