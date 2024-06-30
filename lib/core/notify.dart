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
    android: const AndroidInitializationSettings('ic_launcher'),
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
          sound: data["sound"] != "default" ? RawResourceAndroidNotificationSound(data["sound"]) : null,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: darwinNotificationCategoryPlain,
          sound: data["sound"] != "default" ? "${data["sound"]}.wav" : "default",
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ));
}

Future<bool> requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print('通知權限已授予');
    return true;
  } else if (status.isDenied) {
    print('通知權限被拒絕');
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
  return false;
}
