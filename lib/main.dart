import 'package:dpip/view/init.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _BackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message);
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );
  FirebaseMessaging.onBackgroundMessage(_BackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print(message);
  });
  print(await messaging.getToken());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "DPIP",
      home: InitPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}