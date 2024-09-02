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
      canPop: false,
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
                _buildSoundTile(context, '緊急地震速報', 'eew', Symbols.warning, tileTitleTextStyle),
                ListTileGroupHeader(title: context.i18n.eew_info_sound_title),
                _buildSoundTile(context, '地震資訊', 'eq', Symbols.info, tileTitleTextStyle),
                ListTileGroupHeader(title: '氣象警報'),
                _buildSoundTile(context, '雷雨即時訊息', 'rain', Symbols.thunderstorm, tileTitleTextStyle),
                _buildSoundTile(context, '天氣警特報', 'weather', Symbols.cloudy_snowing, tileTitleTextStyle),
                ListTileGroupHeader(title: '災害資訊'),
                _buildSoundTile(context, '避難資訊', 'evacuation', Symbols.directions_run, tileTitleTextStyle),
                _buildSoundTile(
                    context, context.i18n.tsunami_alert_sound, 'tsunami', Symbols.waves, tileTitleTextStyle),
                ListTileGroupHeader(title: context.i18n.other_title),
                _buildSoundTile(context, '其他通知', 'other', Symbols.notifications, tileTitleTextStyle),
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
          buildSoundListTile('緊急地震速報(重大)', context.i18n.eew_alert_description_sound, "eew_alert"),
          buildSoundListTile('緊急地震速報(一般)', context.i18n.eew_description_sound, "eew"),
          buildSoundListTile('地震速報(重大)', '重大地震速報通知音效', "eew_major"),
          buildSoundListTile('地震速報(一般)', '一般地震速報通知音效', "eew_minor"),
        ];
      case 'eq':
        return [
          buildSoundListTile('震度速報(一般)', '一般震度速報通知音效', "int_report", enable: monitor),
          buildSoundListTile('震度速報(靜默通知)', '靜默震度速報通知', "int_report_silent", enable: monitor),
          buildSoundListTile('強震監視器(一般)', context.i18n.eq_description_sound, "eq", enable: monitor),
          buildSoundListTile('地震報告(一般)', context.i18n.report_description_sound, "report"),
          buildSoundListTile('地震報告(靜默通知)', '靜默地震報告通知', "report_silent"),
        ];
      case 'rain':
        return [
          buildSoundListTile('重大', context.i18n.thunderstorm_instant_messaging_description_sound, "thunderstorm_major"),
          buildSoundListTile('一般', '一般雷雨即時訊息通知音效', "thunderstorm"),
        ];
      case 'weather':
        return [
          buildSoundListTile('重大', '重大天氣警特報通知音效', "weather_major"),
          buildSoundListTile('一般', '一般天氣警特報通知音效', "weather_minor"),
        ];
      case 'evacuation':
        return [
          buildSoundListTile('重大', '重大避難資訊通知音效', "evacuation_major"),
          buildSoundListTile('一般', '一般避難資訊通知音效', "evacuation_minor"),
        ];
      case 'tsunami':
        return [
          buildSoundListTile('重大', context.i18n.tsunami_alert_description_sound, "tsunami_warn"),
          buildSoundListTile('一般', context.i18n.tsunami_alert2_description_sound, "tsunami"),
          buildSoundListTile('太平洋海嘯消息(靜默通知)', '靜默太平洋海嘯消息通知', "tsunami_pacific_silent"),
        ];
      case 'other':
        return [
          buildSoundListTile('公告', context.i18n.server_announcement_description_sound, "announcement"),
        ];
      default:
        return [];
    }
  }
}
