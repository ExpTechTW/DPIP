import 'package:app_settings/app_settings.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'notify.dart';

var loc_data;

final themeOptions = {
  "light": "淺色",
  "dark": "深色",
  "system": "跟隨系統主題",
};

class MePage extends StatefulWidget {
  const MePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  String currentTown = Global.preference.getString("loc-town") ?? "";
  String currentCity = Global.preference.getString("loc-city") ?? "";
  String _theme = Global.preference.getString("theme") ?? "system";

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
                  leading: const Icon(Icons.location_city_rounded),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
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
                                  currentTown = value != null ? Global.region[value]!.keys.first : "";
                                  Global.preference.setString("loc-city", value!);
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消"))],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.forest_rounded),
                  title: const Text('鄉鎮市區'),
                  subtitle: Text(
                    currentTown.isNotEmpty ? currentTown : "尚未設定",
                  ),
                  enabled: currentCity.isNotEmpty,
                  onTap: () {
                    if (currentCity.isNotEmpty) {
                      List<String> townList = Global.region[currentCity]!.keys.toList();

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('鄉鎮市區'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
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
                                    Global.preference.setString("loc-town", value ?? "");
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("取消"),
                            )
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
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: const Text("主題"),
                  subtitle: Text(themeOptions[_theme]!),
                  onTap: () => showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => SimpleDialog(
                      title: const Text("主題"),
                      children: [
                        ...themeOptions.entries.map(
                          (e) => RadioListTile(
                            value: e.key,
                            groupValue: _theme,
                            title: Text(e.value),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _theme = value;
                                  Global.preference.setString("theme", value);
                                  MainApp.of(context)!.changeTheme(_theme);
                                  Navigator.pop(context);
                                });
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("取消"),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_rounded),
                  title: const Text('通知'),
                  onTap: () {
                    AppSettings.openAppSettings(type: AppSettingsType.notification);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.music_note_rounded),
                  title: const Text('音效'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotifyPage(),
                      ),
                    );
                  },
                ),
                AboutListTile(
                  icon: const Icon(Icons.info_outline_rounded),
                  applicationIcon: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: const Image(
                        image: AssetImage("assets/app_icon.png"),
                        width: 48,
                        height: 48,
                      )),
                  applicationVersion: Global.packageInfo.version,
                  aboutBoxChildren: const [
                    Text(
                      "DPIP (Disaster prevention information platform)，是一套由臺灣本土團隊設計的App，整合 TREM (臺灣即時地震監測網) 之強震即時警報與地震資訊，以及中央氣象署之資料，提供一個整合、單一且便利的防災資訊應用程式。",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                  child: Text(
                    "ExpTech 探索科技",
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                ),
                ListTile(
                  leading: const Icon(SimpleIcons.github),
                  title: const Text("ExpTechTW/DPIP"),
                  onTap: () {
                    launchUrl(
                      Uri.parse("https://www.github.com/ExpTechTW/DPIP"),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: "https://www.github.com/ExpTechTW/DPIP",
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(SimpleIcons.discord),
                  title: const Text("Discord 社群"),
                  onTap: () {
                    launchUrl(
                      Uri.parse("https://discord.com/invite/exptech-studio"),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: "https://discord.com/invite/exptech-studio",
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(SimpleIcons.instagram),
                  title: const Text("@exptech.tw"),
                  onTap: () {
                    launchUrl(
                      Uri.parse("https://www.instagram.com/exptech.tw"),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: "https://www.instagram.com/exptech.tw",
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(SimpleIcons.youtube),
                  title: const Text("Youtube 直播"),
                  onTap: () {
                    launchUrl(
                      Uri.parse("https://www.youtube.com/@exptechtw/live"),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: "https://www.youtube.com/@exptechtw/live",
                      ),
                    );
                  },
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
