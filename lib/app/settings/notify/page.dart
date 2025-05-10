import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/toast.dart';

class SettingsNotifyPage extends StatefulWidget {
  const SettingsNotifyPage({super.key});

  static const route = '/settings/notify';

  @override
  State<SettingsNotifyPage> createState() => _SettingsNotifyPageState();
}

class _SettingsNotifyPageState extends State<SettingsNotifyPage> {
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
              title: Text(getEewNotifyTypeName(EewNotifyType.all)),
              value: EewNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile(
              title: Text(getEewNotifyTypeName(EewNotifyType.localIntensityAbove1)),
              value: EewNotifyType.localIntensityAbove1,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile(
              title: Text(getEewNotifyTypeName(EewNotifyType.localIntensityAbove4)),
              value: EewNotifyType.localIntensityAbove4,
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
              title: Text(getEarthquakeNotifyTypeName(EarthquakeNotifyType.all)),
              value: EarthquakeNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: Text(getEarthquakeNotifyTypeName(EarthquakeNotifyType.localIntensityAbove1)),
              value: EarthquakeNotifyType.localIntensityAbove1,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: Text(getEarthquakeNotifyTypeName(EarthquakeNotifyType.off)),
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
              title: Text(getWeatherNotifyTypeName(WeatherNotifyType.local)),
              value: WeatherNotifyType.local,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: Text(getWeatherNotifyTypeName(WeatherNotifyType.off)),
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
              title: Text(getTsunamiNotifyTypeName(TsunamiNotifyType.all)),
              value: TsunamiNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: Text(getTsunamiNotifyTypeName(TsunamiNotifyType.warningOnly)),
              value: TsunamiNotifyType.warningOnly,
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
              title: Text(getBasicNotifyTypeName(BasicNotifyType.all)),
              value: BasicNotifyType.all,
              groupValue: groupValue,
              onChanged: (value) => Navigator.pop(context, value),
              visualDensity: VisualDensity.comfortable,
            ),
            RadioListTile(
              title: Text(getBasicNotifyTypeName(BasicNotifyType.off)),
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
    TsunamiNotifyType.warningOnly => '海嘯警報',
    TsunamiNotifyType.all => '海嘯消息、海嘯警報',
  };

  String getBasicNotifyTypeName(BasicNotifyType value) => switch (value) {
    BasicNotifyType.off => '關閉',
    BasicNotifyType.all => '接收全部',
  };

  void showSuccessToast(BuildContext context) {
    showToast(context, ToastWidget.text('已更新通知設定', icon: const Icon(Symbols.check_rounded)));
  }

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
                SettingsListSection(
                  title: '地震速報',
                  children: [
                    Selector<SettingsNotificationModel, EewNotifyType>(
                      selector: (_, model) => model.eew,
                      builder: (context, eew, child) {
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_eew,
                              subtitle: Text(getEewNotifyTypeName(eew)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.crisis_alert_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openEewNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_eew,
                                  groupValue: eew,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setEew(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
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
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_monitor,
                              subtitle: Text(getEarthquakeNotifyTypeName(monitor)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.earthquake_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openEarthquakeNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_monitor,
                                  groupValue: monitor,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setMonitor(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.report,
                      builder: (context, report, child) {
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_report,
                              subtitle: Text(getEarthquakeNotifyTypeName(report)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.docs_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openEarthquakeNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_report,
                                  groupValue: report,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setReport(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.intensity,
                      builder: (context, intensity, child) {
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_intensity,
                              subtitle: Text(getEarthquakeNotifyTypeName(intensity)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.summarize_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openEarthquakeNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_intensity,
                                  groupValue: intensity,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setIntensity(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
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
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_thunderstorm,
                              subtitle: Text(getWeatherNotifyTypeName(thunderstorm)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.thunderstorm_rounded,
                              enabled: enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openWeatherNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_thunderstorm,
                                  groupValue: thunderstorm,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setThunderstorm(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.weatherAdvisory,
                      builder: (context, weatherAdvisory, child) {
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_advisory,
                              subtitle: Text(getWeatherNotifyTypeName(weatherAdvisory)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.warning_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openWeatherNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_advisory,
                                  groupValue: weatherAdvisory,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setWeatherAdvisory(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.evacuation,
                      builder: (context, evacuation, child) {
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_evacuation,
                              subtitle: Text(getWeatherNotifyTypeName(evacuation)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.directions_run_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openWeatherNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_evacuation,
                                  groupValue: evacuation,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setEvacuation(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
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
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.notify_tsunami,
                              subtitle: Text(getTsunamiNotifyTypeName(tsunami)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.tsunami_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openTsunamiNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.notify_tsunami,
                                  groupValue: tsunami,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setTsunami(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
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
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SettingsListTile(
                              title: context.i18n.announcement,
                              subtitle: Text(getBasicNotifyTypeName(announcement)),
                              trailing: isLoading ? const LoadingIcon() : const Icon(Symbols.chevron_right_rounded),
                              icon: Symbols.campaign_rounded,
                              enabled: !isLoading && enabled,
                              onTap: () async {
                                if (isLoading || !enabled) return;

                                final result = await openBasicNotifyTypeSelectorDialog(
                                  context,
                                  title: context.i18n.announcement,
                                  groupValue: announcement,
                                );

                                if (!context.mounted || result == null) return;

                                setState(() => isLoading = true);
                                await context.read<SettingsNotificationModel>().setAnnouncement(result);
                                setState(() => isLoading = false);

                                if (!context.mounted) return;
                                showSuccessToast(context);
                              },
                            );
                          },
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
