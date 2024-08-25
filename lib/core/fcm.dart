import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:dpip/global.dart';

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
  Global.preference.setString("fcm-token", token);
}

Future<void> onNativeTokenHandle(String token) async {
  debugPrint('FCM Token:"$token"');
  Global.preference.setString("fcm-token", token);
}

Future<void> onFcmSilentDataHandle(FcmSilentData silentData) async {
  return Future.value();
}
