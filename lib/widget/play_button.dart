import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
}
