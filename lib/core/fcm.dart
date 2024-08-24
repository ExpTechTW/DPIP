import "package:dpip/core/notify.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";

import "../global.dart";

Future<void> messageHandler(RemoteMessage message) async {
  await showNotify(message);
}

Future<void> fcmInit() async {
  await Firebase.initializeApp();
  await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );
  FirebaseMessaging.onMessage.listen(messageHandler);
  FirebaseMessaging.onBackgroundMessage(messageHandler);
  FirebaseMessaging.onMessageOpenedApp.listen(messageHandler);
  messaging.getToken().then((value) async {
    if (value == null) {
      print("fcm token -> 獲取失敗");
      return;
    }
    String fcmToken = Global.preference.getString("fcm-token") ?? "";
    print("fcm token -> $fcmToken");
    Global.preference.setString("fcm-token", value);
  });
}
