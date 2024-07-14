import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

class SettingsAudioView extends StatefulWidget {
  const SettingsAudioView({super.key});

  @override
  State<SettingsAudioView> createState() => _SettingsAudioViewState();
}

class _SettingsAudioViewState extends State<SettingsAudioView> {
  final AudioPlayer _audioPlayer = AudioPlayer();

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
      const TitleText(
        text: eewTitle,
      ),
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
        soundPath: 'eew.wav',
        colors: const [Color(0x33FF0000), Color(0xFFFF0000)],
        playSound: playSound,
      ),
      const TitleText(text: eqTitle),
      SoundButton(
        text: '震度速報',
        subtitle: 'TREM觀測網 所在地實測震度 1 以上',
        soundPath: 'Int_report.wav',
        colors: const [Color(0x33FFC901), Color(0xFFFFC901)],
        playSound: playSound,
      ),
      SoundButton(
        text: '強震監視器',
        subtitle: 'TREM觀測網 偵測到晃動',
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
         // appBar: AppBar(
         //   title: const Text("音效測試"),
         // ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
              ),
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
    }
  }
}

class PlayButton extends StatelessWidget {
  final String soundPath;
  final Future<void> Function(String soundPath) playSound;

  const PlayButton({
    Key? key,
    required this.soundPath,
    required this.playSound,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Color(0xFFCEBBFD) : Color(0xFF654EA2);
    return Platform.isIOS
        ? CupertinoButton(
      onPressed: () {
        playSound(soundPath);
      },
      padding: EdgeInsets.zero,
      child: Icon(
        CupertinoIcons.play_circle_fill,
        color: textColor,  // 使用根據主題變化的顏色
        size: 32,
      ),
    )
        : IconButton(
      onPressed: () {
        playSound(soundPath);
      },
      icon: Icon(
        Icons.play_circle,
        color: textColor,  // 使用根據主題變化的顏色
        size: 32,
      ),
    );
  }
}

class SoundButton extends StatelessWidget {
  final String text;
  final String subtitle;
  final String soundPath;
  final List<Color> colors;
  final Future<void> Function(String soundPath) playSound;

  const SoundButton({
    Key? key,
    required this.text,
    required this.subtitle,
    required this.soundPath,
    required this.colors,
    required this.playSound,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color borderColor = isDarkMode ? Colors.white : Colors.black;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 15, right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),  // 設置邊框顏色和寬度
        color: Colors.transparent,  // 背景設為透明
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,

                  ),
                ),
              ],
            ),
          ),
            PlayButton(soundPath: soundPath, playSound: playSound),
        ],
      ),
    );
  }
}
class TitleText extends StatelessWidget {
  final String text;

  const TitleText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Color(0xFFCEBBFD) : Color(0xFF654EA2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}