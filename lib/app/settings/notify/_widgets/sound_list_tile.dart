import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/global.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SoundListTile extends StatefulWidget {
  final String title;
  final Widget? subtitle;
  final String type;
  final bool isFirst;
  final bool isLast;

  const SoundListTile({
    super.key,
    required this.title,
    required this.type,
    this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

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
    return SegmentedListTile(
      title: Text(widget.title),
      subtitle: widget.subtitle,
      trailing: _enabled
          ? const Icon(Symbols.play_circle_rounded)
          : const LoadingIcon(),
      enabled: _enabled,
      isFirst: widget.isFirst,
      isLast: widget.isLast,
      onTap: onTap,
    );
  }
}
