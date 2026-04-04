/// Sound test list tile widget for notification settings pages.
library;

import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/global.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A list tile that plays a test notification when tapped.
///
/// Disables itself for 2 seconds after tapping to prevent rapid repeated
/// triggers. Use [type] to specify the notification channel key:
///
/// ```dart
/// SoundListTile(
///   title: '緊急地震速報(重大)',
///   type: 'eew_alert-important-v2',
///   isFirst: true,
/// )
/// ```
class SoundListTile extends StatefulWidget {
  /// The display label for this sound test row.
  final String title;

  /// An optional description shown below [title].
  final Widget? subtitle;

  /// The notification channel key used to trigger the test notification.
  final String type;

  /// Whether this tile is the first in its containing list.
  final bool isFirst;

  /// Whether this tile is the last in its containing list.
  final bool isLast;

  /// Creates a [SoundListTile].
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
      trailing: _enabled ? const Icon(Symbols.play_circle_rounded) : const LoadingIcon(),
      enabled: _enabled,
      isFirst: widget.isFirst,
      isLast: widget.isLast,
      onTap: onTap,
    );
  }
}
