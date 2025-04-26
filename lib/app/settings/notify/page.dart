import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
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
            Consumer<SettingsNotificationModel>(
              builder: (context, model, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsListTile(
                      title: context.i18n.emergency_earthquake_warning,
                      subtitle: Text(getEewNotifyTypeName(model.eew)),
                      onTap: () async {
                        final result = await openEewNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.emergency_earthquake_warning,
                          groupValue: model.eew,
                        );
                        if (result == null) return;
                        model.setEew(result);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '地震',
          children: [
            Consumer<SettingsNotificationModel>(
              builder: (context, model, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsListTile(
                      title: context.i18n.monitor,
                      subtitle: Text(getEarthquakeNotifyTypeName(model.monitor)),
                      onTap: () async {
                        final result = await openEarthquakeNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.monitor,
                          groupValue: model.monitor,
                        );
                        if (result == null) return;
                        model.setMonitor(result);
                      },
                    ),
                    SettingsListTile(
                      title: context.i18n.report,
                      subtitle: Text(getEarthquakeNotifyTypeName(model.report)),
                      onTap: () async {
                        final result = await openEarthquakeNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.report,
                          groupValue: model.report,
                        );
                        if (result == null) return;
                        model.setReport(result);
                      },
                    ),
                    SettingsListTile(
                      title: context.i18n.sound_int_report_minor,
                      subtitle: Text(getEarthquakeNotifyTypeName(model.intensity)),
                      onTap: () async {
                        final result = await openEarthquakeNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.sound_int_report_minor,
                          groupValue: model.intensity,
                        );
                        if (result == null) return;
                        model.setIntensity(result);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '天氣',
          children: [
            Consumer<SettingsNotificationModel>(
              builder: (context, model, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsListTile(
                      title: context.i18n.sound_rain_instant,
                      subtitle: Text(getWeatherNotifyTypeName(model.thunderstorm)),
                      onTap: () async {
                        final result = await openWeatherNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.sound_rain_instant,
                          groupValue: model.thunderstorm,
                        );
                        if (result == null) return;
                        model.setThunderstorm(result);
                      },
                    ),
                    SettingsListTile(
                      title: context.i18n.sound_weather_alert,
                      subtitle: Text(getWeatherNotifyTypeName(model.weatherAdvisory)),
                      onTap: () async {
                        final result = await openWeatherNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.sound_weather_alert,
                          groupValue: model.weatherAdvisory,
                        );
                        if (result == null) return;
                        model.setWeatherAdvisory(result);
                      },
                    ),
                    SettingsListTile(
                      title: context.i18n.sound_evacuation,
                      subtitle: Text(getWeatherNotifyTypeName(model.evacuation)),
                      onTap: () async {
                        final result = await openWeatherNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.sound_evacuation,
                          groupValue: model.evacuation,
                        );
                        if (result == null) return;
                        model.setEvacuation(result);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '海嘯',
          children: [
            Consumer<SettingsNotificationModel>(
              builder: (context, model, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsListTile(
                      title: context.i18n.tsunami_alert_sound,
                      subtitle: Text(getTsunamiNotifyTypeName(model.tsunami)),
                      onTap: () async {
                        final result = await openTsunamiNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.tsunami_alert_sound,
                          groupValue: model.tsunami,
                        );
                        if (result == null) return;
                        model.setTsunami(result);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SettingsListSection(
          title: '其他',
          children: [
            Consumer<SettingsNotificationModel>(
              builder: (context, model, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsListTile(
                      title: context.i18n.announcement,
                      subtitle: Text(getBasicNotifyTypeName(model.announcement)),
                      onTap: () async {
                        final result = await openBasicNotifyTypeSelectorDialog(
                          context,
                          title: context.i18n.announcement,
                          groupValue: model.announcement,
                        );
                        if (result == null) return;
                        model.setAnnouncement(result);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
