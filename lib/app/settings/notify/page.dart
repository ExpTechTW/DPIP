import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
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
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsNotifyPage extends StatefulWidget {
  const SettingsNotifyPage({super.key});

  static const name = 'notify';
  static const route = '/settings/$name';

  @override
  State<SettingsNotifyPage> createState() => _SettingsNotifyPageState();
}

class _SettingsNotifyPageState extends State<SettingsNotifyPage> {
  String getEewNotifyTypeName(EewNotifyType value) => switch (value) {
    EewNotifyType.localIntensityAbove4 => '所在地震度4以上',
    EewNotifyType.localIntensityAbove1 => '所在地震度1以上',
    EewNotifyType.all => '接收全部',
  };

  String getEarthquakeNotifyTypeName(EarthquakeNotifyType value) => switch (value) {
    EarthquakeNotifyType.off => '關閉',
    EarthquakeNotifyType.localIntensityAbove1 => '所在地震度1以上',
    EarthquakeNotifyType.all => '接收全部',
  };

  String getWeatherNotifyTypeName(WeatherNotifyType value) => switch (value) {
    WeatherNotifyType.off => '關閉',
    WeatherNotifyType.local => '接收所在地',
  };

  String getTsunamiNotifyTypeName(TsunamiNotifyType value) => switch (value) {
    TsunamiNotifyType.warningOnly => '只接收海嘯警報',
    TsunamiNotifyType.all => '海嘯消息、海嘯警報',
  };

  String getBasicNotifyTypeName(BasicNotifyType value) => switch (value) {
    BasicNotifyType.off => '關閉',
    BasicNotifyType.all => '接收全部',
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
      ExpTech().getNotify(token: Preference.notifyToken).then((value) {
        GlobalProviders.notification.apply(value);
        setState(() => isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsLocationModel, String?>(
      selector: (_, model) => model.code,
      builder: (context, code, child) {
        final enabled = code != null;

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
                    content: '請先設定所在地來使用通知功能',
                    trailing: TextButton(
                      onPressed: () => context.push(SettingsLocationPage.route),
                      child: const Text('設定'),
                    ),
                  ),
                ListSection(
                  title: '地震速報',
                  children: [
                    Selector<SettingsNotificationModel, EewNotifyType>(
                      selector: (_, model) => model.eew,
                      builder: (context, eew, child) {
                        return ListSectionTile(
                          title: context.i18n.notify_eew,
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
                  title: '地震',
                  children: [
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.monitor,
                      builder: (context, monitor, child) {
                        return ListSectionTile(
                          title: context.i18n.notify_monitor,
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
                          title: context.i18n.notify_report,
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
                          title: context.i18n.notify_intensity,
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
                  title: '天氣',
                  children: [
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.thunderstorm,
                      builder: (context, thunderstorm, child) {
                        return ListSectionTile(
                          title: context.i18n.notify_thunderstorm,
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
                          title: context.i18n.notify_advisory,
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
                          title: context.i18n.notify_evacuation,
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
                  title: '海嘯',
                  children: [
                    Selector<SettingsNotificationModel, TsunamiNotifyType>(
                      selector: (_, model) => model.tsunami,
                      builder: (context, tsunami, child) {
                        return ListSectionTile(
                          title: context.i18n.notify_tsunami,
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
                  title: '其他',
                  children: [
                    Selector<SettingsNotificationModel, BasicNotifyType>(
                      selector: (_, model) => model.announcement,
                      builder: (context, announcement, child) {
                        return ListSectionTile(
                          title: context.i18n.announcement,
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
