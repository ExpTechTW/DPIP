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
    required String soundPath,
    required List<Color> colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(90)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> soundButtonsData = [
      {
        'text': '強震即時警報(警報)',
        'soundPath': 'eew_alert.wav',
        'colors': [const Color(0x330063C6), const Color(0xFF0063C6)],
      },
      {
        'text': '地震速報(注意)',
        'soundPath': 'eew_warn.wav',
        'colors': [const Color(0x330063C6), const Color(0xFF0063C6)],
      },
      {
        'text': '震度速報',
        'soundPath': 'warn.wav',
        'colors': [const Color(0x33F8E495), const Color(0xFFF8E495)],
      },
      {
        'text': '強震監視器',
        'soundPath': 'warn.wav',
        'colors': [const Color(0x33F8E495), const Color(0xFFF8E495)],
      },
      {
        'text': '地震報告',
        'soundPath': 'warn.wav',
        'colors': [const Color(0x33F8E495), const Color(0xFFF8E495)],
      },
      {
        'text': '大雷雨即時訊息',
        'soundPath': 'warn.wav',
        'colors': [const Color(0x1AFD9800), const Color(0xFFFD9800)],
      },
      {
        'text': '強震即時警報 (EEW)',
        'soundPath': 'warn.wav',
        'colors': [const Color(0x660063C6), const Color(0xFF0063C6)],
      },
    ];

    final List<Widget> soundButtons = soundButtonsData.map(
          (data) => buildSoundButton(
        text: data['text'],
        soundPath: data['soundPath'],
        colors: data['colors'],
      ),
    ).toList();

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
    }
  }
}