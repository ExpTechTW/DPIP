import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../global.dart';

Future<void> fcmInit() async {
  await Firebase.initializeApp();
  await AwesomeNotificationsFcm().initialize(
    onFcmTokenHandle: onFcmTokenHandle,
    onNativeTokenHandle: onNativeTokenHandle,
    onFcmSilentDataHandle: onFcmSilentDataHandle,
    debug: true,
  );
  await AwesomeNotificationsFcm().requestFirebaseAppToken();
}

Future<void> onFcmTokenHandle(String token) async {
  debugPrint('FCM Token:"$token"');
  Global.preference.setString("fcm-token", token);
}

Future<void> onNativeTokenHandle(String token) async {
  debugPrint('FCM Token:"$token"');
  Global.preference.setString("fcm-token", token);
}

Future<void> onFcmSilentDataHandle(FcmSilentData silentData) async {
  debugPrint('"${silentData.createdLifeCycle?.name}": '
      'silentData: ${silentData.toString()}');

  if (silentData.createdLifeCycle == NotificationLifeCycle.AppKilled) {
    await AwesomeNotifications().createNotificationFromJsonData(silentData.data!.cast<String, dynamic>());
  } else {
    await showNotify(silentData.data!.cast<String, dynamic>());
  }

  return Future.value();
}

Future<void> showNotify(Map<String, dynamic> data) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: int.parse(data['id'] ?? '0'),
      channelKey: 'basic_channel',
      title: data['title'],
      body: data['body'],
    ),
  );
}