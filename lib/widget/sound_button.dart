import 'package:flutter/material.dart';
import 'play_button.dart';

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
