import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dpip/core/utils.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/view/setting/ios/cupertino_theme_mode_page.dart';
import 'package:dpip/view/setting/location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'notify.dart';

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
  String? currentTown = Global.preference.getString("loc-town");
  String? currentCity = Global.preference.getString("loc-city");
  String _theme = Global.preference.getString("theme") ?? "system";

  Future<void> unsubscribeAllTopics() async {
    final fcmToken = await messaging.getToken();

    if (fcmToken == null) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final topics = await Global.api.getNotificationTopics(fcmToken);
    final topicKeepList = ["DPIP"];

    if (Global.preference.getString("loc-city") != null) {
      final city = Global.preference.getString("loc-city")!;
      topicKeepList.add(safeBase64Encode(city));
      if (Global.preference.getString("loc-town") != null) {
        final town = Global.preference.getString("loc-town")!;
        topicKeepList.add(safeBase64Encode("$city$town"));
      }
    }

    topics.removeWhere((topic) => topicKeepList.contains(topic));

    Future.forEach(
      topics,
      (topic) => messaging.unsubscribeFromTopic(topic).catchError(print),
    ).then((value) {
      messaging.subscribeToTopic("DPIP");

      Navigator.of(context).pop();
    });
  }

  void updateCurrentLocationSettings() {
    setState(() {
      currentCity = Global.preference.getString("loc-city");
      currentTown = Global.preference.getString("loc-town");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("我"),
        ),
        backgroundColor: CupertinoColors.secondarySystemBackground,
        child: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoListSection(
                    header: const Text("一般"),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.location_solid),
                        title: const Text("所在地"),
                        additionalInfo: Text(currentTown != null ? "$currentCity $currentTown" : "未設定"),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const LocationSettingsPage(),
                            ),
                          );

                          updateCurrentLocationSettings();
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.moon_fill),
                        title: const Text("主題"),
                        additionalInfo: Text(themeOptions[_theme]!),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.push<String>(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => CupertinoThemeModePage(
                                themeMode: _theme,
                              ),
                            ),
                          ).then((value) {
                            if (value != null) {
                              setState(() {
                                _theme = value;
                                Global.preference.setString("theme", value);
                                MainApp.of(context)!.changeTheme(_theme);
                              });
                            }
                          });
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.bell_fill),
                        title: const Text('通知'),
                        onTap: () {
                          AppSettings.openAppSettings(type: AppSettingsType.notification);
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.music_note),
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
                    ],
                  ),
                  CupertinoListSection(
                    header: const Text("ExpTech Studio 探索科技"),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(SimpleIcons.github),
                        title: const Text("ExpTechTW/DPIP"),
                        onTap: () {
                          launchUrl(
                            Uri.parse("https://www.github.com/ExpTechTW/DPIP"),
                          );
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(SimpleIcons.discord),
                        title: const Text("Discord 社群"),
                        onTap: () {
                          launchUrl(
                            Uri.parse("https://discord.com/invite/exptech-studio"),
                          );
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(SimpleIcons.instagram),
                        title: const Text("@exptech.tw"),
                        onTap: () {
                          launchUrl(
                            Uri.parse("https://www.instagram.com/exptech.tw"),
                          );
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(SimpleIcons.youtube),
                        title: const Text("Youtube 直播"),
                        onTap: () {
                          launchUrl(
                            Uri.parse("https://www.youtube.com/@exptechtw/live"),
                          );
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(SimpleIcons.githubsponsors),
                        title: const Text("贊助我們"),
                        onTap: () {
                          launchUrl(
                            Uri.parse("https://exptech.com.tw/donate"),
                          );
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(Icons.pending),
                        title: const Text("服務條款"),
                        onTap: () {
                          launchUrl(
                            Uri.parse("https://exptech.com.tw/tos"),
                          );
                        },
                      ),
                    ],
                  ),
                  CupertinoListSection(
                    header: const Text("除錯"),
                    children: [
                      CupertinoListTile(
                        title: const Text("版本"),
                        additionalInfo: Text(Global.packageInfo.version),
                      ),
                      CupertinoListTile(
                        title: const Text("建置號碼"),
                        additionalInfo: Text(Global.packageInfo.buildNumber),
                      ),
                      CupertinoListTile(
                        title: const Text("複製 FCM Token"),
                        onTap: () {
                          messaging.getToken().then((value) {
                            FlutterClipboard.copy(value ?? "");
                            showCupertinoDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (context) {
                                return const CupertinoAlertDialog(
                                  content: Center(
                                    child: Text("已複製 FCM Token"),
                                  ),
                                );
                              },
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('複製 FCM Token 時發生錯誤：$error'),
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      );
    } else {
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
                      "一般",
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Symbols.location_pin_rounded),
                    title: const Text("所在地"),
                    subtitle: Text(
                      currentTown != null ? "$currentCity $currentTown" : "未設定",
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocationSettingsPage(),
                        ),
                      );

                      updateCurrentLocationSettings();
                    },
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
                      "ExpTech Studio 探索科技",
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
                  ListTile(
                    leading: const Icon(SimpleIcons.githubsponsors),
                    title: const Text("贊助我們"),
                    onTap: () {
                      launchUrl(
                        Uri.parse("https://exptech.com.tw/donate"),
                      );
                    },
                    onLongPress: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: "https://exptech.com.tw/donate",
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.pending),
                    title: const Text("服務條款"),
                    onTap: () {
                      launchUrl(
                        Uri.parse("https://exptech.com.tw/tos"),
                      );
                    },
                    onLongPress: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: "https://exptech.com.tw/tos",
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
}
