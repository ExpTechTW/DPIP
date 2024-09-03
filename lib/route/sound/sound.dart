import 'package:dpip/global.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:dpip/widget/settings/sound/sound_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SoundRoute extends StatefulWidget {
  const SoundRoute({super.key});

  @override
  State<SoundRoute> createState() => _SoundRouteState();
}

class _SoundRouteState extends State<SoundRoute> {
  @override
  Widget build(BuildContext context) {
    const tileTitleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
    );

    return PopScope(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              pinned: true,
              floating: true,
              title: Text(context.i18n.notify_test),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                ListTileGroupHeader(title: context.i18n.eew_sound_title),
                _buildSoundTile(
                    context, context.i18n.emergency_earthquake_warning, 'eew', Symbols.warning, tileTitleTextStyle),
                ListTileGroupHeader(title: context.i18n.eew_info_sound_title),
                _buildSoundTile(context, '地震資訊', 'eq', Symbols.info, tileTitleTextStyle),
                ListTileGroupHeader(title: context.i18n.sound_weather_warning),
                _buildSoundTile(
                    context, context.i18n.sound_rain_instant, 'rain', Symbols.thunderstorm, tileTitleTextStyle),
                _buildSoundTile(
                    context, context.i18n.sound_weather_alert, 'weather', Symbols.cloudy_snowing, tileTitleTextStyle),
                ListTileGroupHeader(title: context.i18n.sound_disaster),
                _buildSoundTile(
                    context, context.i18n.sound_evacuation, 'evacuation', Symbols.directions_run, tileTitleTextStyle),
                _buildSoundTile(context, context.i18n.tsunami_warning, 'tsunami', Symbols.tsunami, tileTitleTextStyle),
                ListTileGroupHeader(title: context.i18n.other_title),
                _buildSoundTile(context, context.i18n.sound_other_notifications, 'other', Symbols.notifications,
                    tileTitleTextStyle),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTile(BuildContext context, String title, String route, IconData icon, TextStyle titleStyle) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon),
      ),
      title: Text(title, style: titleStyle),
      trailing: const Icon(Symbols.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SoundDetailPage(category: route, title: title),
          ),
        );
      },
    );
  }
}

class SoundDetailPage extends StatelessWidget {
  final String category;
  final String title;

  const SoundDetailPage({super.key, required this.category, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        children: _buildListItems(context),
      ),
    );
  }

  List<Widget> _buildListItems(BuildContext context) {
    final monitor = Global.preference.getBool("monitor") ?? false;

    Widget buildSoundListTile(String title, String subtitle, String type, {bool? enable}) {
      return SoundListTile(
        title: title,
        subtitle: subtitle,
        type: type,
        enable: enable ?? true,
      );
    }

    switch (category) {
      case 'eew':
        return [
          buildSoundListTile(context.i18n.sound_eew_alert_major, context.i18n.eew_alert_description_sound, "eew_alert"),
          buildSoundListTile(context.i18n.sound_eew_minor, context.i18n.eew_description_sound, "eew"),
          buildSoundListTile(
              context.i18n.sound_earthquake_eew_major, context.i18n.sound_earthquake_eew_major_h2, "eew_major"),
          buildSoundListTile(
              context.i18n.sound_earthquake_eew_minor, context.i18n.sound_earthquake_eew_minor_h2, "eew_minor"),
        ];
      case 'eq':
        return [
          buildSoundListTile(context.i18n.sound_int_report_minor, context.i18n.sound_int_report_minor_h2, "int_report",
              enable: monitor),
          buildSoundListTile(
              context.i18n.sound_int_report_silent, context.i18n.sound_int_report_silent_h2, "int_report_silent",
              enable: monitor),
          buildSoundListTile(context.i18n.sound_monitor_minor, context.i18n.eq_description_sound, "eq",
              enable: monitor),
          buildSoundListTile(context.i18n.sound_report_minor, context.i18n.report_description_sound, "report"),
          buildSoundListTile(context.i18n.sound_report_silent, context.i18n.sound_report_silent_h2, "report_silent"),
        ];
      case 'rain':
        return [
          buildSoundListTile(context.i18n.sound_major, context.i18n.thunderstorm_instant_messaging_description_sound,
              "thunderstorm_major"),
          buildSoundListTile(context.i18n.me_general, context.i18n.sound_rain_minor_h2, "thunderstorm"),
        ];
      case 'weather':
        return [
          buildSoundListTile(context.i18n.sound_major, context.i18n.sound_weather_major_h2, "weather_major"),
          buildSoundListTile(context.i18n.me_general, context.i18n.sound_weather_minor_h2, "weather_minor"),
        ];
      case 'evacuation':
        return [
          buildSoundListTile(context.i18n.sound_major, context.i18n.sound_evacuation_major_h2, "evacuation_major"),
          buildSoundListTile(context.i18n.me_general, context.i18n.sound_evacuation_minor_h2, "evacuation_minor"),
        ];
      case 'tsunami':
        return [
          buildSoundListTile(context.i18n.sound_major, context.i18n.tsunami_alert_description_sound, "tsunami_warn"),
          buildSoundListTile(context.i18n.me_general, context.i18n.tsunami_alert2_description_sound, "tsunami"),
          buildSoundListTile(
              context.i18n.sound_tsunami_silent, context.i18n.sound_tsunami_silent_h2, "tsunami_pacific_silent"),
        ];
      case 'other':
        return [
          buildSoundListTile(
              context.i18n.announcement, context.i18n.server_announcement_description_sound, "announcement"),
        ];
      default:
        return [];
    }
  }
}
