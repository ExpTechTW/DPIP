import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
import 'background.dart';

Future<void> messageHandler(RemoteMessage message) async {
  var ans = await FCM(message.data);
  flutterLocalNotificationsPlugin.show(
      ans["code"],
      ans["title"],
      ans["body"],
      NotificationDetails(
        android: AndroidNotificationDetails(
          ans["channel"]!,
          (ans["level"] == 0)
              ? '一般訊息'
              : (ans["level"] == 1)
                  ? '警訊通知'
                  : '緊急警報',
          channelDescription: (ans["level"] == 0)
              ? '一般通知'
              : (ans["level"] == 1)
                  ? '重要通知'
                  : '有立即危險',
          importance: (ans["level"] == 0)
              ? Importance.low
              : (ans["level"] == 1)
                  ? Importance.defaultImportance
                  : Importance.max,
          priority: (ans["level"] == 0)
              ? Priority.low
              : (ans["level"] == 1)
                  ? Priority.defaultPriority
                  : Priority.max,
          sound: ans["sound"] != "default"
              ? RawResourceAndroidNotificationSound(ans["sound"])
              : null,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: darwinNotificationCategoryPlain,
          sound: "${ans["sound"]}.wav",
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ));
}
