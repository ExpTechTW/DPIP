import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widget/sound_button.dart';
import '../widget/title_text.dart';

class NotifyPage extends StatelessWidget {
  final AudioPlayer _audioPlayer = AudioPlayer();
  NotifyPage({Key? key}) : super(key: key);

  Future<void> playSound(String soundPath) async {
    await _audioPlayer.setSource(AssetSource(soundPath));
    await _audioPlayer.resume();
  }

  @override
  Widget build(BuildContext context) {
    const String eewTitle = "地震速報音效";
    const String eqTitle = "地震資訊音效";
    const String weatherTitle = "防災資訊音效";
    const String otherTitle = "其他音效";

    final List<Widget> soundButtons = [
      const TitleText(text: eewTitle),
      SoundButton(
        text: '強震即時警報(警報)',
        subtitle: '地震速報 最大震度 5弱 以上\n且所在地預估震度 4 以上',
        soundPath: 'eew_alert.wav',
        colors: const [Color(0x33FF0000), Color(0xFFFF0000)],
        playSound: playSound,
      ),
      SoundButton(
        text: '地震速報(注意)',
        subtitle: '地震速報 所在地預估震度 2 以上',
        soundPath: 'eq.wav',
        colors: const [Color(0x33FF0000), Color(0xFFFF0000)],
        playSound: playSound,
      ),
      const TitleText(text: eqTitle),
      SoundButton(
        text: '震度速報',
        subtitle: 'TREM觀測網 所在地實測震度 1 以上',
        soundPath: 'eq.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '強震監視器',
        subtitle: 'TREM地震速報 預估震度 1 以上',
        soundPath: 'eq.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '地震報告',
        subtitle: '地震報告 所在地震度 1 以上',
        soundPath: 'report.wav',
        colors: const [Color(0x330063C6), Color(0xFF0063C6)],
        playSound: playSound,
      ),
      const TitleText(text: weatherTitle),
      SoundButton(
        text: '大雷雨即時訊息',
        subtitle: '所在地發布 大雷雨即時訊息',
        soundPath: 'rain.wav',
        colors: const [Color(0x33FF0000), Color(0xFFFF0000)],
        playSound: playSound,
      ),
      SoundButton(
        text: '豪雨特報',
        subtitle: '所在地發布 豪雨特報',
        soundPath: 'weather.wav',
        colors: const [Color(0x33FF0000), Color(0xFFFF0000)],
        playSound: playSound,
      ),
      SoundButton(
        text: '海嘯警報(警報)',
        subtitle: '所在地發布 海嘯警報(警報)\n預估浪高 1公尺 以上',
        soundPath: 'tsunami.wav',
        colors: const [Color(0x33FF0000), Color(0xFFFF0000)],
        playSound: playSound,
      ),
      SoundButton(
        text: '海嘯警報(注意)',
        subtitle: '所在地發布 海嘯警報(注意)\n預估浪高 1公尺 以下',
        soundPath: 'warn.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '火山資訊',
        subtitle: '所在地發布 火山資訊',
        soundPath: 'warn.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '大雨特報',
        subtitle: '所在地發布 大雨特報',
        soundPath: 'normal.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '高溫資訊',
        subtitle: '所在地發布 高溫資訊',
        soundPath: 'normal.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '陸上強風特報',
        subtitle: '所在地發布 陸上強風特報',
        soundPath: 'normal.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      const TitleText(text: otherTitle),
      SoundButton(
        text: '防空核子警報',
        subtitle: '所在地發布 防空核子警報',
        soundPath: 'warn.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '伺服器公告',
        subtitle: 'ExpTech發布之公告',
        soundPath: 'info.wav',
        colors: const [Color(0x330063C6), Color(0xFF0063C6)],
        playSound: playSound,
      ),
    ];

    if (Platform.isIOS) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.2)),
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text("音效測試"),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(soundButtons),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.2)),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("音效測試"),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
              ),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        "僅供音效測試使用",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(soundButtons),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
