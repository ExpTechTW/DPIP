import 'package:clipboard/clipboard.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/extension.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'notify.dart';

var loc_data;

class MePage extends StatefulWidget {
  const MePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                  child: Text(
                    "所在地",
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                ),
                ListTile(
                  title: const Text('縣市'),
                  subtitle: Text(
                    Global.preference.getString("loc-city") ?? "尚未設定",
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('鄉鎮市區'),
                  subtitle: Text(
                    Global.preference.getString("loc-town") ?? "尚未設定",
                  ),
                  onTap: () {},
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                  child: Text(
                    "一般",
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_rounded),
                  title: const Text('通知'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotifyPage(),
                        ));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text("版本"),
                  subtitle: Row(
                    children: [
                      Text(Global.packageInfo.version),
                      const SizedBox(width: 4),
                      if (Global.packageInfo.version.split(".")[2] != "0")
                        Badge(
                          label: const Text("ALPHA"),
                          largeSize: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textColor: context.colors.onSurfaceVariant,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: context.colors.surfaceVariant,
                        ),
                    ],
                  ),
                  onTap: () {},
                ),
                const AboutListTile(
                  icon: Icon(Icons.info_outline_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                  child: Text(
                    "除錯",
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_rounded),
                  title: const Text("複製 FCM Token"),
                  onTap: () {
                    messaging.getToken().then((value) {
                      FlutterClipboard.copy(value ?? "");
                      context.scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('已複製 FCM Token'),
                        ),
                      );
                    }).catchError((error) {
                      context.scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('複製 FCM Token 時發生錯誤：$error'),
                        ),
                      );
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
