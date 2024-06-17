import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class NotifyPage extends StatelessWidget {
  final AudioPlayer _audioPlayer = AudioPlayer();
  NotifyPage({Key? key}) : super(key: key);

  Future<void> playSound(String soundPath) async {
    await _audioPlayer.setSource(AssetSource(soundPath));
    await _audioPlayer.resume();
  }

  // 生成音效按鈕容器的函式
  Widget buildSoundButton({
    required String text,
    required String subtitle,
    required String soundPath,
    required List<Color> colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 15, right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          buildPlayButton(soundPath),
        ],
      ),
    );
  }

  // 生成播放按鈕的函式
  Widget buildPlayButton(String soundPath) {
    return Platform.isIOS
        ? CupertinoButton(
      onPressed: () {
        playSound(soundPath);
      },
      padding: EdgeInsets.zero,
      child: const Icon(
        CupertinoIcons.play_circle_fill,
        color: CupertinoColors.white,
        size: 32,
      ),
    )
        : IconButton(
      onPressed: () {
        playSound(soundPath);
      },
      icon: const Icon(
        Icons.play_circle,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  // 生成標題文本容器的函式
  Widget buildTitleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 25),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String eewTitle = "地震速報相關音效";
    const String eqTitle = "地震資訊音效音效";
    const String weatherTitle = "防災資訊音效";
    const String otherTitle = "其他音效";





    final List<Widget> soundButtons = [
      buildTitleText(eewTitle),
      buildSoundButton(
        text: '強震即時警報(警報)',
        subtitle: '地震速報所在地',
        soundPath: 'eew_alert.wav',
        colors: [const Color(0x330063C6), const Color(0xFF0063C6)],
      ),
      buildSoundButton(
        text: '地震速報(注意)',
        subtitle: '地震速報所在地',
        soundPath: 'eew_warn.wav',
        colors: [const Color(0x330063C6), const Color(0xFF0063C6)],
      ),
      buildSoundButton(
        text: '震度速報',
        subtitle: '地震速報所在地',
        soundPath: 'warn.wav',
        colors: [const Color(0x33F8E495), const Color(0xFFF8E495)],
      ),
      buildSoundButton(
        text: '強震監視器',
        subtitle: '地震速報所在地',
        soundPath: 'warn.wav',
        colors: [const Color(0x33F8E495), const Color(0xFFF8E495)],
      ),
      buildSoundButton(
        text: '地震報告',
        subtitle: '地震速報所在地',
        soundPath: 'warn.wav',
        colors: [const Color(0x33F8E495), const Color(0xFFF8E495)],
      ),
      buildTitleText(weatherTitle),
      buildSoundButton(
        text: '大雷雨即時訊息',
        subtitle: '地震速報所在地',
        soundPath: 'warn.wav',
        colors: [const Color(0x1AFD9800), const Color(0xFFFD9800)],
      ),
      buildTitleText(otherTitle),
      buildSoundButton(
        text: '大雷雨即時訊息',
        subtitle: '地震速報所在地',
        soundPath: 'warn.wav',
        colors: [const Color(0x1AFD9800), const Color(0xFFFD9800)],
      ),
    ];

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
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
      );
    } else {
      return Scaffold(
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
                  // 新增的文字
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
      );
    }
  }
}
