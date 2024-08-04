import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
  static String? currentlyPlayingFile;
  bool isPlaying = false;

  void playSound() async {
    if (currentlyPlayingFile == widget.file) {
      if (isPlaying) {
        await audioPlayer.stop();
        setState(() {
          isPlaying = false;
        });
      } else {
        await audioPlayer.resume();
        setState(() {
          isPlaying = true;
        });
      }
    } else {
      if (currentlyPlayingFile != null) {
        await audioPlayer.stop();
        setState(() {
          isPlaying = false;
        });
      }

      await audioPlayer.setSource(AssetSource(widget.file));
      await audioPlayer.resume();

      setState(() {
        currentlyPlayingFile = widget.file;
        isPlaying = true;
      });
    }

    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          currentlyPlayingFile = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: Icon(isPlaying ? Symbols.stop_circle : Symbols.play_circle, fill: 1),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      onTap: playSound,
    );
  }
}
