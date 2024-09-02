import 'package:dpip/global.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:dpip/widget/settings/sound/sound_list_tile.dart';
import 'package:flutter/material.dart';

class SoundRoute extends StatefulWidget {
  const SoundRoute({super.key});

  @override
  State<SoundRoute> createState() => _SoundRouteState();
}

class _SoundRouteState extends State<SoundRoute> {
  final monitor = Global.preference.getBool("monitor") ?? false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar.large(
                pinned: true,
                floating: true,
                title: Text(context.i18n.notify_test),
              )
            ];
          },
          body: ListView(
            padding: EdgeInsets.only(bottom: context.padding.bottom),
            controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
            children: [
              _buildCategoryTile(context.i18n.eew_sound_title, 'eew'),
              _buildCategoryTile(context.i18n.eew_info_sound_title, 'eq'),
              _buildCategoryTile('雷雨即時訊息', 'rain'),
              _buildCategoryTile('天氣警特報', 'weather'),
              _buildCategoryTile('避難資訊', 'evacuation'),
              _buildCategoryTile(context.i18n.tsunami_alert_sound, 'tsunami'),
              _buildCategoryTile(context.i18n.other_title, 'other'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String title, String route) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SoundDetailPage(category: route),
          ),
        );
      },
    );
  }
}

class SoundDetailPage extends StatelessWidget {
  final String category;

  const SoundDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView(
        children: _buildListItems(context),
      ),
    );
  }

  List<Widget> _buildListItems(BuildContext context) {
    final monitor = Global.preference.getBool("monitor") ?? false;

    switch (category) {
      case 'eew':
        return [
          SoundListTile(
            title: '緊急地震速報(重大)',
            subtitle: context.i18n.eew_alert_description_sound,
            type: "eew_alert",
          ),
          SoundListTile(
            title: '緊急地震速報(一般)',
            subtitle: context.i18n.eew_description_sound,
            type: "eew",
          ),
          SoundListTile(
            title: '地震速報(重大)',
            subtitle: '重大地震速報通知音效',
            type: "eew_major",
          ),
          SoundListTile(
            title: '地震速報(一般)',
            subtitle: '一般地震速報通知音效',
            type: "eew_minor",
          ),
        ];
      case 'eq':
        return [
          SoundListTile(
            title: '震度速報(一般)',
            subtitle: '一般震度速報通知音效',
            type: "int_report",
            enable: monitor,
          ),
          SoundListTile(
            title: '震度速報(靜默通知)',
            subtitle: '靜默震度速報通知',
            type: "int_report_silent",
            enable: monitor,
          ),
          SoundListTile(
            title: '強震監視器(一般)',
            subtitle: context.i18n.eq_description_sound,
            type: "eq",
            enable: monitor,
          ),
          SoundListTile(
            title: '地震報告(一般)',
            subtitle: context.i18n.report_description_sound,
            type: "report",
          ),
          SoundListTile(
            title: '地震報告(靜默通知)',
            subtitle: '靜默地震報告通知',
            type: "report_silent",
          ),
        ];
      case 'rain':
        return [
          SoundListTile(
            title: '重大',
            subtitle: context.i18n.thunderstorm_instant_messaging_description_sound,
            type: "thunderstorm_major",
          ),
          SoundListTile(
            title: '一般',
            subtitle: '一般雷雨即時訊息通知音效',
            type: "thunderstorm",
          ),
        ];
      case 'weather':
        return [
          SoundListTile(
            title: '重大',
            subtitle: '重大天氣警特報通知音效',
            type: "weather_major",
          ),
          SoundListTile(
            title: '一般',
            subtitle: '一般天氣警特報通知音效',
            type: "weather_minor",
          ),
        ];
      case 'evacuation':
        return [
          SoundListTile(
            title: '重大',
            subtitle: '重大避難資訊通知音效',
            type: "evacuation_major",
          ),
          SoundListTile(
            title: '一般',
            subtitle: '一般避難資訊通知音效',
            type: "evacuation_minor",
          ),
        ];
      case 'tsunami':
        return [
          SoundListTile(
            title: '重大',
            subtitle: context.i18n.tsunami_alert_description_sound,
            type: "tsunami_warn",
          ),
          SoundListTile(
            title: '一般',
            subtitle: context.i18n.tsunami_alert2_description_sound,
            type: "tsunami",
          ),
          SoundListTile(
            title: '太平洋海嘯消息(靜默通知)',
            subtitle: '靜默太平洋海嘯消息通知',
            type: "tsunami_pacific_silent",
          ),
        ];
      case 'other':
        return [
          SoundListTile(
            title: '公告',
            subtitle: context.i18n.server_announcement_description_sound,
            type: "announcement",
          ),
        ];
      default:
        return [];
    }
  }
}
