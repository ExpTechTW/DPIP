import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../global.dart';
import '../main.dart';

Future<void> messageHandler(RemoteMessage message) async {
  late SharedPreferences preference;

  var data = message.data;
  String type = data["type"];
  String title = data["title"];
  String body = data["body"];

  print(data);

  preference = await SharedPreferences.getInstance();

  if (type == "rts" && (preference.getBool("notification:monitor") ?? true)) {
    flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1000000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            "rts",
            "強震監視器",
            channelDescription: "顯示檢測到晃動的地區",
            importance: Importance.max,
            priority: Priority.max,
            sound: RawResourceAndroidNotificationSound("warn"),
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: darwinNotificationCategoryPlain,
            sound: "warn.wav",
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ));
  }
}
