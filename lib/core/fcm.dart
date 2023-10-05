import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';

Future<void> messageHandler(RemoteMessage message) async {
  var data = message.data;
  flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          data["channel"]!,
          (data["level"] == "0")
              ? '一般訊息'
              : (data["level"] == "1")
                  ? '警訊通知'
                  : '緊急警報',
          channelDescription: (data["level"] == "0")
              ? '一般通知'
              : (data["level"] == "1")
                  ? '重要通知'
                  : '有立即危險',
          importance: (data["level"] == "0")
              ? Importance.low
              : (data["level"] == "1")
                  ? Importance.defaultImportance
                  : Importance.max,
          priority: (data["level"] == "0")
              ? Priority.low
              : (data["level"] == "1")
                  ? Priority.defaultPriority
                  : Priority.max,
          sound: data["sound"] != "default"
              ? RawResourceAndroidNotificationSound(data["sound"])
              : null,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: darwinNotificationCategoryPlain,
          sound:
              data["sound"] != "default" ? "${data["sound"]}.wav" : "default",
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ));
}
