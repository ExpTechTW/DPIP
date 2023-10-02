import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
import 'background.dart';

const DarwinNotificationDetails iosNotificationDetails =
    DarwinNotificationDetails(
  categoryIdentifier: darwinNotificationCategoryPlain,
);

Future<void> messageHandler(RemoteMessage message) async {
  FCM(message.data);
  final RemoteNotification? notification = message.notification;
  final AndroidNotification? android = message.notification?.android;
  if (notification != null) {
    var data = message.data;
    flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            (data["level"] == 0)
                ? 'low'
                : (data["level"] == 1)
                    ? 'middle'
                    : 'high',
            (data["level"] == 0)
                ? '一般訊息'
                : (data["level"] == 1)
                    ? '警訊通知'
                    : '緊急警報',
            channelDescription: (data["level"] == 0)
                ? '一般通知'
                : (data["level"] == 1)
                    ? '重要通知'
                    : '有立即危險',
            icon: android?.smallIcon,
            importance: (data["level"] == 0)
                ? Importance.low
                : (data["level"] == 1)
                    ? Importance.defaultImportance
                    : Importance.max,
          ),
          iOS: iosNotificationDetails,
        ));
  }
}
