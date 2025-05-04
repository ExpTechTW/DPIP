import "dart:convert";
import "dart:io";

import "package:dpip/core/providers.dart";
import "package:awesome_notifications/awesome_notifications.dart";
import "package:dpip/core/ios_get_location.dart";
import "package:dpip/global.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/need_location.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_symbols_icons/symbols.dart";

class SoundListTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String type;
  final bool? enable;

  const SoundListTile({super.key, required this.title, required this.subtitle, required this.type, this.enable = true});

  @override
  SoundListTileState createState() => SoundListTileState();
}

class SoundListTileState extends State<SoundListTile> {
  bool isPlaying = false;
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() async {
    final json = await rootBundle.loadString("assets/notify_test.json");
    data = jsonDecode(json) as Map<String, dynamic>;
  }

  void _initUserLocation() async {
    if (Platform.isIOS && GlobalProviders.location.auto) {
      await getSavedLocation();
    }

    if (!mounted) return;

    userLat = GlobalProviders.location.latitude ?? 0;
    userLon = GlobalProviders.location.longitude ?? 0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;
  }

  void playSound() async {
    if (!widget.enable!) return;
    _initUserLocation();
    if (!isUserLocationValid && !GlobalProviders.location.auto) {
      await showLocationDialog(context);
    } else {
      int limit = Global.preference.getInt("limit-sound-test") ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now - limit > 1000) {
        Global.preference.setInt("limit-sound-test", now);
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: -1,
            channelKey: widget.type,
            title: "[測試] ${data[widget.type]["title"]}",
            body: "＊＊＊這是測試訊息＊＊＊${(Platform.isIOS) ? "\n" : "<br>"}${data[widget.type]["body"]}",
            notificationLayout: NotificationLayout.BigText,
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
