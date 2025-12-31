import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
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

  String getEarthquakeNotifyTypeName(EarthquakeNotifyType value) =>
      switch (value) {
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

  bool get hasLocation =>
      GlobalProviders.location.coordinates != null ||
      GlobalProviders.location.code != null ||
      (Preference.locationAuto ?? false);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (!hasLocation) return;

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('伺服器排隊中，請稍候…'.i18n)));
        }
      });
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
                        TalkerManager.instance.error(
                          'Failed to update location: $updateError',
                        );
                      });
                });
              }
            }
          });
    }
  }

  Widget _buildIconContainer({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Symbols.notifications_rounded,
              color: context.colors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '通知設定'.i18n,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '自訂各類通知的接收方式'.i18n,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsLocationModel, String?>(
      selector: (_, model) => model.code,
      builder: (context, code, child) {
        final enabled = hasLocation;

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: isLoading && enabled ? 1 : 0,
                duration: Durations.short4,
                child: const LinearProgressIndicator(),
              ),
            ),
            ListView(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 16 + context.padding.bottom,
              ),
              children: [
                _buildHeader(context),
                if (!enabled)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.theme.extendedColors.amber.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.theme.extendedColors.amber
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Symbols.warning_rounded,
                            color: context.theme.extendedColors.amber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '尚未設定所在地'.i18n,
                                style: context.texts.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.theme.extendedColors.amber,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '請先設定所在地來使用通知功能'.i18n,
                                style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () =>
                                    const SettingsLocationRoute().push(context),
                                icon: const Icon(Symbols.location_on_rounded),
                                label: Text('設定所在地'.i18n),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SegmentedList(
                  label: Text('地震速報'.i18n),
                  children: [
                    Selector<SettingsNotificationModel, EewNotifyType>(
                      selector: (_, model) => model.eew,
                      builder: (context, eew, child) {
                        return SegmentedListTile(
                          isFirst: true,
                          isLast: true,
                          leading: _buildIconContainer(
                            icon: Symbols.crisis_alert_rounded,
                            color: Colors.red,
                          ),
                          title: Text('緊急地震速報'.i18n),
                          subtitle: Text(getEewNotifyTypeName(eew)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () =>
                              const SettingsNotifyEewRoute().push(context),
                        );
                      },
                    ),
                  ],
                ),
                SegmentedList(
                  label: Text('地震'.i18n),
                  children: [
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.monitor,
                      builder: (context, monitor, child) {
                        return SegmentedListTile(
                          isFirst: true,
                          leading: _buildIconContainer(
                            icon: Symbols.monitor_heart_rounded,
                            color: Colors.orange,
                          ),
                          title: Text('強震監視器'.i18n),
                          subtitle: Text(getEarthquakeNotifyTypeName(monitor)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () =>
                              const SettingsNotifyMonitorRoute().push(context),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.report,
                      builder: (context, report, child) {
                        return SegmentedListTile(
                          leading: _buildIconContainer(
                            icon: Symbols.docs_rounded,
                            color: Colors.blue,
                          ),
                          title: Text('地震報告'.i18n),
                          subtitle: Text(getEarthquakeNotifyTypeName(report)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () =>
                              const SettingsNotifyReportRoute().push(context),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, EarthquakeNotifyType>(
                      selector: (_, model) => model.intensity,
                      builder: (context, intensity, child) {
                        return SegmentedListTile(
                          isLast: true,
                          leading: _buildIconContainer(
                            icon: Symbols.summarize_rounded,
                            color: Colors.teal,
                          ),
                          title: Text('震度速報'.i18n),
                          subtitle: Text(
                            getEarthquakeNotifyTypeName(intensity),
                          ),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () => const SettingsNotifyIntensityRoute()
                              .push(context),
                        );
                      },
                    ),
                  ],
                ),
                SegmentedList(
                  label: Text('天氣'.i18n),
                  children: [
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.thunderstorm,
                      builder: (context, thunderstorm, child) {
                        return SegmentedListTile(
                          isFirst: true,
                          leading: _buildIconContainer(
                            icon: Symbols.thunderstorm_rounded,
                            color: Colors.purple,
                          ),
                          title: Text('雷雨即時訊息'.i18n),
                          subtitle: Text(
                            getWeatherNotifyTypeName(thunderstorm),
                          ),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () => const SettingsNotifyThunderstormRoute()
                              .push(context),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.weatherAdvisory,
                      builder: (context, weatherAdvisory, child) {
                        return SegmentedListTile(
                          leading: _buildIconContainer(
                            icon: Symbols.warning_rounded,
                            color: Colors.amber,
                          ),
                          title: Text('天氣警特報'.i18n),
                          subtitle: Text(
                            getWeatherNotifyTypeName(weatherAdvisory),
                          ),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () =>
                              const SettingsNotifyAdvisoryRoute().push(context),
                        );
                      },
                    ),
                    Selector<SettingsNotificationModel, WeatherNotifyType>(
                      selector: (_, model) => model.evacuation,
                      builder: (context, evacuation, child) {
                        return SegmentedListTile(
                          isLast: true,
                          leading: _buildIconContainer(
                            icon: Symbols.directions_run_rounded,
                            color: Colors.green,
                          ),
                          title: Text('防災資訊'.i18n),
                          subtitle: Text(getWeatherNotifyTypeName(evacuation)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () => const SettingsNotifyEvacuationRoute()
                              .push(context),
                        );
                      },
                    ),
                  ],
                ),
                SegmentedList(
                  label: Text('海嘯'.i18n),
                  children: [
                    Selector<SettingsNotificationModel, TsunamiNotifyType>(
                      selector: (_, model) => model.tsunami,
                      builder: (context, tsunami, child) {
                        return SegmentedListTile(
                          isFirst: true,
                          isLast: true,
                          leading: _buildIconContainer(
                            icon: Symbols.tsunami_rounded,
                            color: Colors.cyan,
                          ),
                          title: Text('海嘯資訊'.i18n),
                          subtitle: Text(getTsunamiNotifyTypeName(tsunami)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () =>
                              const SettingsNotifyTsunamiRoute().push(context),
                        );
                      },
                    ),
                  ],
                ),
                SegmentedList(
                  label: Text('其他'.i18n),
                  children: [
                    Selector<SettingsNotificationModel, BasicNotifyType>(
                      selector: (_, model) => model.announcement,
                      builder: (context, announcement, child) {
                        return SegmentedListTile(
                          isFirst: true,
                          isLast: true,
                          leading: _buildIconContainer(
                            icon: Symbols.campaign_rounded,
                            color: Colors.indigo,
                          ),
                          title: Text('公告'.i18n),
                          subtitle: Text(getBasicNotifyTypeName(announcement)),
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          enabled: !isLoading && enabled,
                          onTap: () => const SettingsNotifyAnnouncementRoute()
                              .push(context),
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
