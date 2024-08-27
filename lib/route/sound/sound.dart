import "package:dpip/global.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:dpip/widget/settings/sound/sound_list_tile.dart";
import "package:flutter/material.dart";

class SoundRoute extends StatefulWidget {
  const SoundRoute({super.key});

  @override
  State<SoundRoute> createState() => _SettingsSoundViewState();
}

class _SettingsSoundViewState extends State<SoundRoute> {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  final backTransition = const Interval(0, 0.5, curve: Easing.emphasizedAccelerate);
  final forwardTransition = const Interval(0.5, 1, curve: Easing.emphasizedDecelerate);
  final monitor = Global.preference.getBool("monitor") ?? false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }

        Navigator.pop(context);
      },
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar.large(
                pinned: true,
                floating: true,
                title: Builder(
                  builder: (context) {
                    return Text(context.i18n.sound_test);
                  },
                ),
              )
            ];
          },
          body: ListView(
            padding: EdgeInsets.only(bottom: context.padding.bottom),
            controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
            children: [
              ListTileGroupHeader(title: context.i18n.eew_sound_title),
              SoundListTile(
                title: context.i18n.eew_alert_sound,
                subtitle: context.i18n.eew_alert_description_sound,
                type: "eew_alert",
              ),
              SoundListTile(
                title: context.i18n.eew_sound,
                subtitle: context.i18n.eew_description_sound,
                type: "eew",
              ),
              ListTileGroupHeader(title: context.i18n.eew_info_sound_title),
              SoundListTile(
                title: context.i18n.int_report_sound,
                subtitle: context.i18n.int_report_description_sound,
                enable: monitor,
                type: "int_report",
              ),
              SoundListTile(
                title: context.i18n.monitor,
                subtitle: context.i18n.eq_description_sound,
                enable: monitor,
                type: "eq",
              ),
              SoundListTile(
                title: context.i18n.report,
                subtitle: context.i18n.report_description_sound,
                type: "report",
              ),
              ListTileGroupHeader(title: context.i18n.dp_info_sound_title),
              SoundListTile(
                title: context.i18n.thunderstorm_instant_messaging_sound,
                subtitle: context.i18n.thunderstorm_instant_messaging_description_sound,
                type: "thunderstorm",
              ),
              SoundListTile(
                title: context.i18n.heavy_rain_alert_sound,
                subtitle: context.i18n.heavy_rain_alert_description_sound,
                type: "rain_2",
              ),
              SoundListTile(
                title: context.i18n.torrential_rain_alert_sound,
                subtitle: context.i18n.torrential_rain_alert_description_sound,
                type: "rain_1",
              ),
              SoundListTile(
                title: context.i18n.flooding_alert_sound,
                subtitle: context.i18n.flooding_alert_description_sound,
                type: "flood",
              ),
              SoundListTile(
                title: context.i18n.tsunami_alert2_sound,
                subtitle: context.i18n.tsunami_alert2_description_sound,
                type: "tsunami",
              ),
              SoundListTile(
                title: context.i18n.tsunami_alert_sound,
                subtitle: context.i18n.tsunami_alert_description_sound,
                type: "tsunami_warn",
              ),
              SoundListTile(
                title: context.i18n.volcano_info_sound,
                subtitle: context.i18n.volcano_info_description_sound,
                type: "volcano",
              ),
              SoundListTile(
                title: context.i18n.high_temperature_info_sound,
                subtitle: context.i18n.high_temperature_info_description_sound,
                type: "heat",
              ),
              SoundListTile(
                title: context.i18n.strong_wind_warning_sound,
                subtitle: context.i18n.strong_wind_warning_description_sound,
                type: "typhoon",
              ),
              ListTileGroupHeader(title: context.i18n.other_title),
              SoundListTile(
                title: context.i18n.other_alert_sound,
                subtitle: context.i18n.other_alert_description_sound,
                type: "other",
              ),
              SoundListTile(
                title: context.i18n.server_announcement_sound,
                subtitle: context.i18n.server_announcement_description_sound,
                type: "announcement",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
