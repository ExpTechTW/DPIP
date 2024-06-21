import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../global.dart';
import '../../main.dart';
import '../init.dart';

class WelcomeNotifyPage extends StatefulWidget {
  const WelcomeNotifyPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WelcomeNotifyPageState();
}

class _WelcomeNotifyPageState extends State<WelcomeNotifyPage> {
  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("通知"),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF009E8B), Colors.transparent, 0.5)!,
                          Color.lerp(const Color(0xFF203864), Colors.transparent, 0.5)!
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFF606060), width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        "請開啟通知權限，以收取地震速報及即時劇烈天氣通知。",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009E8B), Color(0xFF203864)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await messaging.requestPermission(
                          alert: true,
                          announcement: true,
                          badge: true,
                          carPlay: true,
                          criticalAlert: true,
                          provisional: true,
                          sound: true,
                        );
                        await Global.preference.setString("infoVersion", "1.0.0");
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InitPage(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Text(
                        "確認並開始使用",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("通知"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF009E8B), Colors.transparent, 0.5)!,
                          Color.lerp(const Color(0xFF203864), Colors.transparent, 0.5)!
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFF606060), width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        "請開啟通知權限，以收取地震速報及即時劇烈天氣通知。",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009E8B), Color(0xFF203864)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await messaging.requestPermission(
                          alert: true,
                          announcement: true,
                          badge: true,
                          carPlay: true,
                          criticalAlert: true,
                          provisional: true,
                          sound: true,
                        );
                        await Global.preference.setString("infoVersion", "1.0.0");
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InitPage(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Text(
                        "確認並開始使用",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
