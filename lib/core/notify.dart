import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/received_notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final FirebaseMessaging messaging = FirebaseMessaging.instance;
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();
final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

const String darwinNotificationCategoryText = 'textCategory';
const String navigationActionId = 'id_3';
const String darwinNotificationCategoryPlain = 'plainCategory';

Future<void> notifyInit() async {
  final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
      didReceiveLocalNotificationStream.add(
        ReceivedNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        ),
      );
    },
  );
  final initializationSettings = InitializationSettings(
    android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: initializationSettingsDarwin,
  );
  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          selectNotificationStream.add(notificationResponse.payload);
          break;
        case NotificationResponseType.selectedNotificationAction:
          if (notificationResponse.actionId == navigationActionId) {
            selectNotificationStream.add(notificationResponse.payload);
          }
          break;
      }
    },
  );
}

Future<void> showNotify(RemoteMessage message) async {
  var data = message.data;

  flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          data["channel"]!,
          (data["level"] == null)
              ? '一般訊息'
              : (data["level"] == "0")
                  ? '警訊通知'
                  : '緊急警報',
          channelDescription: (data["level"] == null)
              ? '一般通知'
              : (data["level"] == "0")
                  ? '重要通知'
                  : '有立即危險',
          importance: (data["level"] == null)
              ? Importance.low
              : (data["level"] == "0")
                  ? Importance.defaultImportance
                  : Importance.max,
          priority: (data["level"] == null)
              ? Priority.low
              : (data["level"] == "0")
                  ? Priority.defaultPriority
                  : Priority.max,
          playSound: true,
          sound: data["sound"] != null ? RawResourceAndroidNotificationSound(data["sound"]) : null,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: darwinNotificationCategoryPlain,
          sound: data["sound"] != null ? "${data["sound"]}.wav" : "default",
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ));
}

Future<PermissionStatus> requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print('通知權限已授予');
  }
  print('通知權限被拒絕');
  return status;
}
