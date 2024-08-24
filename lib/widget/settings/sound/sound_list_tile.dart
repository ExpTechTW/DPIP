import "package:audioplayers/audioplayers.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class SoundListTile extends StatefulWidget {
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
  SoundListTileState createState() => SoundListTileState();
}

class SoundListTileState extends State<SoundListTile> {
  static final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;

  void playSound() async {
    if (isPlaying) {
      await audioPlayer.stop();
    }

    await audioPlayer.setSource(AssetSource(widget.file));
    await audioPlayer.resume();

    setState(() {
      isPlaying = true;
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: const Icon(Symbols.play_circle, fill: 1),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      onTap: playSound,
    );
  }
}
