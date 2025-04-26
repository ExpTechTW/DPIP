import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class SettingsNotifyPage extends StatelessWidget {
  const SettingsNotifyPage({super.key});

  Future<EewNotifyType?> openEewNotifyTypeSelectorDialog(
    BuildContext context, {
    required String title,
    required EewNotifyType groupValue,
  }) {
    return showDialog<EewNotifyType>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: [
            RadioListTile(
              title: const Text('所在地震度4以上'),
              value: EewNotifyType.localIntensityAbove4,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile(
              title: const Text('所在地震度1以上'),
              value: EewNotifyType.localIntensityAbove1,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile(
              title: const Text('全部'),
              value: EewNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        );
      },
    );
  }

  Future<EarthquakeNotifyType?> openEarthquakeNotifyTypeSelectorDialog(
    BuildContext context, {
    required String title,
    required EarthquakeNotifyType groupValue,
  }) {
    return showDialog<EarthquakeNotifyType>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: [
            RadioListTile(
              title: const Text('全部'),
              value: EarthquakeNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: const Text('所在地震度1以上'),
              value: EarthquakeNotifyType.localIntensityAbove1,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: const Text('關閉'),
              value: EarthquakeNotifyType.off,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
          ],
        );
      },
    );
  }

  Future<WeatherNotifyType?> openWeatherNotifyTypeSelectorDialog(
    BuildContext context, {
    required String title,
    required WeatherNotifyType groupValue,
  }) {
    return showDialog<WeatherNotifyType>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: [
            RadioListTile(
              title: const Text('接收所在地'),
              value: WeatherNotifyType.local,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: const Text('關閉'),
              value: WeatherNotifyType.off,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
          ],
        );
      },
    );
  }

  Future<TsunamiNotifyType?> openTsunamiNotifyTypeSelectorDialog(
    BuildContext context, {
    required String title,
    required TsunamiNotifyType groupValue,
  }) {
    return showDialog<TsunamiNotifyType>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: [
            RadioListTile(
              title: const Text('海嘯警報'),
              value: TsunamiNotifyType.warningOnly,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: const Text('海嘯警報、海嘯警報'),
              value: TsunamiNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
          ],
        );
      },
    );
  }

  Future<BasicNotifyType?> openBasicNotifyTypeSelectorDialog(
    BuildContext context, {
    required String title,
    required BasicNotifyType groupValue,
  }) {
    return showDialog<BasicNotifyType>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: [
            RadioListTile(
              title: const Text('全部'),
              value: BasicNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: const Text('關閉'),
              value: BasicNotifyType.off,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
          ],
        );
      },
    );
  }

  String getEewNotifyTypeName(EewNotifyType value) => switch (value) {
    EewNotifyType.localIntensityAbove4 => '所在地震度4以上',
    EewNotifyType.localIntensityAbove1 => '所在地震度1以上',
    EewNotifyType.all => '全部',
  };

  String getEarthquakeNotifyTypeName(EarthquakeNotifyType value) => switch (value) {
    EarthquakeNotifyType.all => '全部',
    EarthquakeNotifyType.localIntensityAbove1 => '所在地震度1以上',
    EarthquakeNotifyType.off => '關閉',
  };

  String getWeatherNotifyTypeName(WeatherNotifyType value) => switch (value) {
    WeatherNotifyType.off => '關閉',
    WeatherNotifyType.local => '接收所在地',
  };

  String getTsunamiNotifyTypeName(TsunamiNotifyType value) => switch (value) {
    TsunamiNotifyType.warningOnly => '海嘯警報',
    TsunamiNotifyType.all => '海嘯警報、海嘯警報',
  };

  String getBasicNotifyTypeName(BasicNotifyType value) => switch (value) {
    BasicNotifyType.off => '關閉',
    BasicNotifyType.all => '全部',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SettingsListSection(
          title: '地震速報',
          children: [
            Selector<SettingsNotificationModel, EewNotifyType>(
              selector: (_, model) => model.eew,
              builder: (context, eew, child) {
                return SettingsListTile(
                  title: context.i18n.emergency_earthquake_warning,
                  subtitle: Text(getEewNotifyTypeName(eew)),
                  icon: Symbols.crisis_alert_rounded,
                  onTap: () async {
                    final result = await openEewNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.emergency_earthquake_warning,
                      groupValue: eew,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setEew(result);
                  },
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '地震',
          children: [
            Selector<SettingsNotificationModel, EarthquakeNotifyType>(
              selector: (_, model) => model.monitor,
              builder: (context, monitor, child) {
                return SettingsListTile(
                  title: context.i18n.monitor,
                  subtitle: Text(getEarthquakeNotifyTypeName(monitor)),
                  icon: Symbols.earthquake_rounded,
                  onTap: () async {
                    final result = await openEarthquakeNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.monitor,
                      groupValue: monitor,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setMonitor(result);
                  },
                );
              },
            ),
            Selector<SettingsNotificationModel, EarthquakeNotifyType>(
              selector: (_, model) => model.report,
              builder: (context, report, child) {
                return SettingsListTile(
                  title: context.i18n.report,
                  subtitle: Text(getEarthquakeNotifyTypeName(report)),
                  icon: Symbols.docs_rounded,
                  onTap: () async {
                    final result = await openEarthquakeNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.report,
                      groupValue: report,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setReport(result);
                  },
                );
              },
            ),
            Selector<SettingsNotificationModel, EarthquakeNotifyType>(
              selector: (_, model) => model.intensity,
              builder: (context, intensity, child) {
                return SettingsListTile(
                  title: context.i18n.sound_int_report_minor,
                  subtitle: Text(getEarthquakeNotifyTypeName(intensity)),
                  icon: Symbols.summarize_rounded,
                  onTap: () async {
                    final result = await openEarthquakeNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.sound_int_report_minor,
                      groupValue: intensity,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setIntensity(result);
                  },
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '天氣',
          children: [
            Selector<SettingsNotificationModel, WeatherNotifyType>(
              selector: (_, model) => model.thunderstorm,
              builder: (context, thunderstorm, child) {
                return SettingsListTile(
                  title: context.i18n.sound_rain_instant,
                  subtitle: Text(getWeatherNotifyTypeName(thunderstorm)),
                  icon: Symbols.thunderstorm_rounded,
                  onTap: () async {
                    final result = await openWeatherNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.sound_rain_instant,
                      groupValue: thunderstorm,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setThunderstorm(result);
                  },
                );
              },
            ),
            Selector<SettingsNotificationModel, WeatherNotifyType>(
              selector: (_, model) => model.weatherAdvisory,
              builder: (context, weatherAdvisory, child) {
                return SettingsListTile(
                  title: context.i18n.sound_weather_alert,
                  subtitle: Text(getWeatherNotifyTypeName(weatherAdvisory)),
                  icon: Symbols.warning_rounded,
                  onTap: () async {
                    final result = await openWeatherNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.sound_weather_alert,
                      groupValue: weatherAdvisory,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setWeatherAdvisory(result);
                  },
                );
              },
            ),
            Selector<SettingsNotificationModel, WeatherNotifyType>(
              selector: (_, model) => model.evacuation,
              builder: (context, evacuation, child) {
                return SettingsListTile(
                  title: context.i18n.sound_evacuation,
                  subtitle: Text(getWeatherNotifyTypeName(evacuation)),
                  icon: Symbols.directions_run_rounded,
                  onTap: () async {
                    final result = await openWeatherNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.sound_evacuation,
                      groupValue: evacuation,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setEvacuation(result);
                  },
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '海嘯',
          children: [
            Selector<SettingsNotificationModel, TsunamiNotifyType>(
              selector: (_, model) => model.tsunami,
              builder: (context, tsunami, child) {
                return SettingsListTile(
                  title: context.i18n.tsunami_alert_sound,
                  subtitle: Text(getTsunamiNotifyTypeName(tsunami)),
                  icon: Symbols.tsunami_rounded,
                  onTap: () async {
                    final result = await openTsunamiNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.tsunami_alert_sound,
                      groupValue: tsunami,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setTsunami(result);
                  },
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '其他',
          children: [
            Selector<SettingsNotificationModel, BasicNotifyType>(
              selector: (_, model) => model.announcement,
              builder: (context, announcement, child) {
                return SettingsListTile(
                  title: context.i18n.announcement,
                  subtitle: Text(getBasicNotifyTypeName(announcement)),
                  icon: Symbols.campaign_rounded,
                  onTap: () async {
                    final result = await openBasicNotifyTypeSelectorDialog(
                      context,
                      title: context.i18n.announcement,
                      groupValue: announcement,
                    );
                    if (!context.mounted || result == null) return;
                    context.read<SettingsNotificationModel>().setAnnouncement(result);
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
