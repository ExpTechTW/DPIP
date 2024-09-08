import "dart:io";

import "package:awesome_notifications/awesome_notifications.dart";
import "package:dpip/core/ios_get_location.dart";
import "package:dpip/global.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/need_location.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class SoundListTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String type;
  final bool? enable;

  const SoundListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    this.enable = true,
  });

  @override
  SoundListTileState createState() => SoundListTileState();
}

class SoundListTileState extends State<SoundListTile> {
  bool isPlaying = false;
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  void _initUserLocation() async {
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }

    if (!mounted) return;

    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;
  }

  void playSound() async {
    if (!widget.enable!) return;
    _initUserLocation();
    if (!isUserLocationValid && !(Global.preference.getBool("auto-location") ?? false)) {
      await showLocationDialog(context);
    } else {
      int limit = Global.preference.getInt("limit-sound-test") ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now - limit > 1000) {
        Global.preference.setInt("limit-sound-test", now);
        print("test");
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: -1,
            channelKey: 'eew_alert-important',
            title: '重大通知',
            body: '這是一個包含重大通知的重要訊息。',
            notificationLayout: NotificationLayout.BigText,
            // criticalAlert: true,
          ),
        );


      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: !widget.enable! ? null : const Icon(Symbols.volume_up, fill: 1),
      title: Text("${widget.title}${!widget.enable! ? context.i18n.not_enabled : ""}"),
      subtitle: Text(widget.subtitle),
      onTap: playSound,
    );
  }
}
