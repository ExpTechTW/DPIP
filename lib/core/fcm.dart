import 'package:firebase_messaging/firebase_messaging.dart';

import 'background.dart';

Future<void> messageHandler(RemoteMessage message) async {
  FCM(message.data);
  // flutterLocalNotificationsPlugin.show(
  //     notification.hashCode,
  //     notification.title,
  //     notification.body,
  //     NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         android?.channelId ?? "default",
  //         (data["level"] == 0)
  //             ? '一般訊息'
  //             : (data["level"] == 1)
  //                 ? '警訊通知'
  //                 : '緊急警報',
  //         channelDescription: (data["level"] == 0)
  //             ? '一般通知'
  //             : (data["level"] == 1)
  //                 ? '重要通知'
  //                 : '有立即危險',
  //         icon: android?.smallIcon,
  //         importance: (data["level"] == 0)
  //             ? Importance.low
  //             : (data["level"] == 1)
  //                 ? Importance.defaultImportance
  //                 : Importance.max,
  //         priority: (data["level"] == 0)
  //             ? Priority.low
  //             : (data["level"] == 1)
  //                 ? Priority.defaultPriority
  //                 : Priority.max,
  //         sound: data["sound"] != null
  //             ? RawResourceAndroidNotificationSound(data["sound"])
  //             : null,
  //       ),
  //       iOS: DarwinNotificationDetails(
  //         categoryIdentifier: darwinNotificationCategoryPlain,
  //         sound: "${data["sound"]}.wav" ?? "default",
  //         interruptionLevel: InterruptionLevel.timeSensitive,
  //       ),
  //     ));
}
