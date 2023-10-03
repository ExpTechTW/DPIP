import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

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
    print(android?.sound);
    flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            android?.channelId ?? "default",
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
            priority: (data["level"] == 0)
                ? Priority.low
                : (data["level"] == 1)
                    ? Priority.defaultPriority
                    : Priority.max,
            sound: android?.channelId != null
                ? RawResourceAndroidNotificationSound(android?.channelId)
                : null,
          ),
          iOS: iosNotificationDetails,
        ));
    if (data["level"] != 0) {
      bool? vibration = await Vibration.hasVibrator();
      bool? hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (vibration != null && vibration) {
        if (hasCustom != null && hasCustom) {
          Vibration.vibrate(duration: (data["level"] == 2) ? 5000 : 2000);
        } else {
          Vibration.vibrate();
          await Future.delayed(
              Duration(milliseconds: (data["level"] == 2) ? 5000 : 2000));
          Vibration.vibrate();
        }
      }
    }
  }
}
