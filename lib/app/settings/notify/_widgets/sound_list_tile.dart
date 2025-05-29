import 'dart:async';
import 'dart:io';

import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/global.dart';

class SoundListTile extends StatefulWidget {
  final String title;
  final Widget? subtitle;
  final String type;

  const SoundListTile({super.key, required this.title, required this.type, this.subtitle});

  @override
  State<SoundListTile> createState() => _SoundListTileState();
}

class _SoundListTileState extends State<SoundListTile> {
  bool _enabled = true;

  void onTap() {
    setState(() => _enabled = false);

    final content = Global.notifyTestContent[widget.type]!;

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: widget.type,
        title: '[測試] ${content.title}',
        body: '＊＊＊這是測試訊息＊＊＊${(Platform.isIOS) ? "\n" : "<br>"} ${content.body}',
        notificationLayout: NotificationLayout.BigText,
      ),
    );

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _enabled = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListSectionTile(
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: _enabled ? const Icon(Symbols.play_circle_rounded) : const LoadingIcon(),
      enabled: _enabled,
      onTap: onTap,
    );
  }
}
