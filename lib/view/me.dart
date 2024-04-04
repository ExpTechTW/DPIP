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
  String currentTown = Global.preference.getString("loc-town") ?? "";
  String currentCity = Global.preference.getString("loc-city") ?? "";

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
                    currentCity.isNotEmpty ? currentCity : "尚未設定",
                  ),
                  onTap: () {
                    List<String> cityList = Global.region.keys.toList();

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("縣市"),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 16.0),
                        content: SizedBox(
                          width: double.minPositive,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: cityList.length,
                            itemBuilder: (context, index) => RadioListTile(
                              value: cityList[index],
                              groupValue: currentCity,
                              title: Text(cityList[index]),
                              onChanged: (value) {
                                setState(() {
                                  currentCity = value ?? "";
                                  Global.preference
                                      .setString("loc-city", value!);
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("取消"))
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('鄉鎮市區'),
                  subtitle: Text(
                    currentTown.isNotEmpty ? currentTown : "尚未設定",
                  ),
                  enabled: currentCity.isNotEmpty,
                  onTap: () {
                    if (currentCity.isNotEmpty) {
                      List<String> townList =
                          Global.region[currentCity]!.keys.toList();

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('鄉鎮市區'),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 16.0),
                          content: SizedBox(
                            width: double.minPositive,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: townList.length,
                              itemBuilder: (context, index) => RadioListTile(
                                value: townList[index],
                                groupValue: currentTown,
                                title: Text(townList[index]),
                                onChanged: (value) {
                                  setState(() {
                                    currentTown = value ?? "";
                                    Global.preference
                                        .setString("loc-town", value ?? "");
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("取消"))
                          ],
                        ),
                      );
                    }
                  },
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
                  title: const Text('通知音效'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotifyPage(),
                        ));
                  },
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
                  title: const Text("版本"),
                  trailing: Text(
                    Global.packageInfo.version,
                    style: TextStyle(
                      color: context.colors.outline,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_rounded),
                  title: const Text("建置號碼"),
                  trailing: Text(
                    Global.packageInfo.buildNumber,
                    style: TextStyle(
                      color: context.colors.outline,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {},
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
