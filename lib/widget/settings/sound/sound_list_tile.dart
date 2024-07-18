import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SoundListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String file;

  const SoundListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: const Icon(Symbols.play_circle, fill: 1),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () async {
        final audioPlayer = AudioPlayer();

        await audioPlayer.setSource(AssetSource(file));
        await audioPlayer.resume();
      },
    );
  }
}
