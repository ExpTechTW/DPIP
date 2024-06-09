import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class NotifyPage extends StatelessWidget {
  final AudioPlayer _audioPlayer = AudioPlayer();
  NotifyPage({Key? key}) : super(key: key);

  // 播放音效的函式
  Future<void> playSound(String soundPath) async {
      await _audioPlayer.setSource(AssetSource(soundPath));
      await _audioPlayer.resume();
    }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("音效測試"),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x330063C6),
                          Color(0xFF0063C6),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '強震即時警報(警報)',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            playSound("eew_alert.wav");
                          },
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x330063C6),
                          Color(0xFF0063C6),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '地震速報(注意)',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            playSound("eew_warn.wav");
                          },
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x33F8E495),
                          Color(0xFFF8E495),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '震度速報',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            playSound("warn.wav");
                          },
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x33F8E495),
                          Color(0xFFF8E495),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '強震監視器',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            playSound("warn.wav");
                          },
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x33F8E495),
                          Color(0xFFF8E495),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '地震報告',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            playSound("warn.wav");
                          },
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x1AFD9800),
                          Color(0xFFFD9800),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '大雷雨及時訊息',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            playSound("warn.wav");
                          },
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x660063C6),
                          Color(0xFF0063C6),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '強震即時警報 (EEW) ',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            playSound("warn.wav");
                          },
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("音效測試"),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x330063C6),
                    Color(0xFF0063C6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(90)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 靠兩側(其實我看不太懂
                children: [
                  const Text(
                    '緊急地震速報(警報)',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      playSound("eew_alert.wav");
                    },
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x330063C6),
                    Color(0xFF0063C6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(90)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 靠兩側(其實我看不太懂
                children: [
                  const Text(
                    '地震速報(注意)',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      playSound("eew_warn.wav");
                    },
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x33F8E495),
                    Color(0xFFF8E495),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(90)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 靠兩側(其實我看不太懂
                children: [
                  const Text(
                    '震度速報',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      playSound("warn.wav");
                    },
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x33F8E495),
                    Color(0xFFF8E495),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(90)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 靠兩側(其實我看不太懂
                children: [
                  const Text(
                    '強震監視器',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      playSound("warn.wav");
                    },
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x33F8E495),
                    Color(0xFFF8E495),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(90)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 靠兩側(其實我看不太懂
                children: [
                  const Text(
                    '地震報告',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      playSound("warn.wav");
                    },
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x1AFD9800),
                    Color(0xFFFD9800),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(90)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 靠兩側(其實我看不太懂
                children: [
                  const Text(
                    '大雷雨及時訊息',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      playSound("warn.wav");
                    },
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
