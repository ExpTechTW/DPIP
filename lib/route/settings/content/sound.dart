import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:dpip/widget/settings/sound/sound_list_tile.dart';
import 'package:flutter/material.dart';

class SettingsSoundView extends StatefulWidget {
  const SettingsSoundView({super.key});

  @override
  State<SettingsSoundView> createState() => _SettingsSoundViewState();
}

class _SettingsSoundViewState extends State<SettingsSoundView> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: const [
          ListTileGroupHeader(title: "地震速報音效"),
          SoundListTile(
            title: "強震即時警報（警報）",
            subtitle: "地震速報 最大震度 5弱 以上\n且所在地預估震度 4 以上",
            file: "eew_alert.wav",
          ),
          SoundListTile(
            title: "地震速報（注意）",
            subtitle: "地震速報 所在地預估震度 2 以上",
            file: "eew.wav",
          ),
          ListTileGroupHeader(title: "地震資訊"),
          SoundListTile(
            title: "震度速報",
            subtitle: "TREM 觀測網 所在地實測震度 1 以上",
            file: "int_report.wav",
          ),
          SoundListTile(
            title: "強震監視器",
            subtitle: "TREM 觀測網 偵測到晃動",
            file: "eq.wav",
          ),
          SoundListTile(
            title: "地震報告",
            subtitle: "地震報告 所在地震度 1 以上",
            file: "report.wav",
          ),
          ListTileGroupHeader(title: "防災資訊"),
          SoundListTile(
            title: "大雷雨即時訊息",
            subtitle: "所在地發布 大雷雨即時訊息",
            file: "rain.wav",
          ),
          SoundListTile(
            title: "豪雨特報",
            subtitle: "所在地發布 豪雨特報",
            file: "weather.wav",
          ),
          SoundListTile(
            title: "海嘯警報（警報）",
            subtitle: "所在地發布 海嘯警報（警報）\n預估浪高 1 公尺以上",
            file: "tsunami.wav",
          ),
          SoundListTile(
            title: "海嘯警報（注意）",
            subtitle: "所在地發布 海嘯警報（注意）\n預估浪高 1 公尺以下",
            file: "warn.wav",
          ),
          SoundListTile(
            title: "火山資訊",
            subtitle: "所在地發布 火山資訊",
            file: "warn.wav",
          ),
          SoundListTile(
            title: "大雨特報",
            subtitle: "所在地發布 大雨特報",
            file: "normal.wav",
          ),
          SoundListTile(
            title: "高溫資訊",
            subtitle: "所在地發布 高溫資訊",
            file: "normal.wav",
          ),
          SoundListTile(
            title: "陸上強風特報",
            subtitle: "所在地發布 陸上強風特報",
            file: "normal.wav",
          ),
          ListTileGroupHeader(title: "其他"),
          SoundListTile(
            title: "防空核子警報",
            subtitle: "所在地發布 防空核子警報",
            file: "warn.wav",
          ),
          SoundListTile(
            title: "伺服器公告",
            subtitle: "ExpTech 發布之公告",
            file: "info.wav",
          ),
        ],
      ),
    );
  }
}
