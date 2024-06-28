import 'package:dpip/core/notify.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> messageHandler(RemoteMessage message) async {
  await showNotify(message);
}

void fcmInit() async{
  await Firebase.initializeApp();
  FirebaseMessaging.onMessage.listen(messageHandler);
  FirebaseMessaging.onBackgroundMessage(messageHandler);
  FirebaseMessaging.onMessageOpenedApp.listen(messageHandler);
}