import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotifyPage extends StatefulWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  _NotifyPage createState() => _NotifyPage();
}

class _NotifyPage extends State<NotifyPage> {
  List<Widget> _listChildren = <Widget>[];
  final player = AudioPlayer();

  @override
  void initState() {
    render();
    super.initState();
  }

  void play(String name) async {
    await player.setSource(AssetSource("$name"));
    player.resume();
  }

  void render() {
    _listChildren = <Widget>[
      const SizedBox(height: 20),
      _buildHeader("僅為音效試聽，並非設定通知分類", null),
      _buildDivider(),
      _buildHeader("強震即時警報（警報）", "預估最大震度 5弱 以上"),
      _buildAlertItem("所在地 預估震度 4級 以上", "eew_alert"),
      _buildAlertItem("所在地 預估震度 3級 以下", "eew_warn"),
      _buildDivider(),
      _buildHeader("地震速報（注意）", "預估最大震度 5弱 以下"),
      _buildAlertItem("所在地 預估震度 3級 以上", "eew_warn"),
      _buildAlertItem("所在地 預估震度 2級 以下", null),
      _buildDivider(),
      _buildHeader("震度速報", "地震觀測網自動觀測結果"),
      _buildAlertItem("所在地 實測震度 3級 以上", "warn"),
      _buildAlertItem("所在地 實測震度 2級 以下", null),
      _buildDivider(),
      _buildHeader("地震報告", "中央氣象署 地震報告"),
      _buildAlertItem("所在地 實測震度 3級 以上", "warn"),
      _buildAlertItem("所在地 實測震度 2級 以下", null),
      _buildDivider(),
      _buildHeader("大雷雨即時訊息", null),
      _buildAlertItem("所在地 發布 大雷雨即時訊息", "warn"),
      _buildDivider(),
      _buildHeader("豪雨特報", null),
      _buildAlertItem("所在地 發布 豪雨特報", "warn"),
      _buildDivider(),
      _buildHeader("大雨特報", null),
      _buildAlertItem("所在地 發布 大雨特報", "warn"),
      _buildDivider(),
      _buildHeader("高溫資訊", null),
      _buildAlertItem("所在地 發布 高溫資訊", null),
      _buildDivider(),
      _buildHeader("陸上強風特報", null),
      _buildAlertItem("所在地 發布 陸上強風特報", null),
      _buildDivider(),
      _buildHeader("停班停課資訊", null),
      _buildAlertItem("所在地 發布 停班停課資訊", null),
      _buildDivider(),
      _buildHeader("海上陸上颱風警報", null),
      _buildAlertItem("發布 海上陸上颱風警報", null),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildHeader(String title, String? subTitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
          if (subTitle != null)
            Text(subTitle, style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String? audioName) {
    if (Platform.isIOS) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xff333439),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: CupertinoListTile(
          onTap: () {
            if (audioName != null) play("$audioName.wav");
          },
          title: Text(
            title,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          trailing:
              audioName != null ? const Icon(CupertinoIcons.play_circle_fill, color: Colors.blue, size: 30) : null,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xff333439),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListTile(
          onTap: () {
            if (audioName != null) play("$audioName.wav");
          },
          title: Text(
            title,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          trailing: audioName != null ? const Icon(Icons.play_circle_fill, color: Colors.blue, size: 30) : null,
        ),
      );
    }
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      render();
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("音效"),
        ),
        backgroundColor: Colors.black,
        child: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: _listChildren,
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("音效"),
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: _listChildren,
          ),
        ),
      );
    }
  }
}
