import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dpip/core/utils.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/view/setting/ios/cupertino_city_page.dart';
import 'package:dpip/view/setting/ios/cupertino_theme_mode_page.dart';
import 'package:dpip/view/setting/ios/cupertino_town_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    try {
      if (Platform.isIOS) {
        showCupertinoDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return const CupertinoAlertDialog(
              content: Row(
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(width: 24),
                  Text("解除通知主題訂閱中..."),
                ],
              ),
            );
          },
        );
      } else {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return const AlertDialog(
              contentPadding: EdgeInsets.all(24),
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 24),
                  Text("解除通知主題訂閱中..."),
                ],
              ),
            );
          },
        );
      }

      final fcmToken = await messaging.getToken();

      if (fcmToken == null) {
        if (!mounted) return;

        Navigator.pop(context);

        if (Platform.isIOS) {
          showCupertinoDialog(
            barrierDismissible: true,
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                title: const Text("重置時發生錯誤"),
                content: const Text(
                  "無法取得已訂閱主題列表",
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text("確定"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            },
          );
        } else {
          context.scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text("重置 FCM 主題訂閱時發生錯誤：無法取得已訂閱主題列表")),
          );
        }

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

        if (Platform.isIOS) {
          showCupertinoDialog(
            barrierDismissible: true,
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                content: const Text(
                  "已重置 FCM 主題訂閱",
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text("確定"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            },
          );
        } else {
          context.scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text("已重置 FCM 主題訂閱")),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      if (Platform.isIOS) {
        showCupertinoDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text("重置時發生錯誤"),
              content: Text(
                e.toString(),
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text("確定"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      } else {
        context.scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("重置 FCM 主題訂閱時發生錯誤：${e.toString()}"),
          ),
        );
      }
    }
  }

  Future<void> setCityLocation(String? value) async {
    if (value == null) return;
    // unsubscribe old location topic
    if (currentCity != null) {
      await messaging.unsubscribeFromTopic(safeBase64Encode(currentCity!));
      if (currentTown != null) {
        await messaging.unsubscribeFromTopic(safeBase64Encode("$currentCity$currentTown"));
      }
    }

    setState(() {
      currentCity = value;
      currentTown = Global.region[value]!.keys.first;
    });

    await Global.preference.setString("loc-city", currentCity!);
    await Global.preference.setString("loc-town", currentTown!);

    // subscribe new location topic
    await messaging.subscribeToTopic(safeBase64Encode(currentCity!));
    await messaging.subscribeToTopic(safeBase64Encode("$currentCity$currentTown"));
  }

  Future<void> setTownLocation(String? value) async {
    if (value == null) return;

    setState(() {
      if (currentTown != null) {
        messaging.unsubscribeFromTopic(safeBase64Encode("$currentCity$currentTown"));
      }
      currentTown = value;
      Global.preference.setString("loc-town", currentTown!);
      messaging.subscribeToTopic(safeBase64Encode("$currentCity$currentTown"));
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
                    header: const Text("所在地"),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.building_2_fill),
                        title: const Text('縣市'),
                        additionalInfo: Text(currentCity ?? "尚未設定"),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.push<String>(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => CupertinoCityPage(city: currentCity ?? "縣市"),
                            ),
                          ).then(setCityLocation);
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.tree),
                        title: const Text('鄉鎮市區'),
                        additionalInfo: Text(currentTown ?? "尚未設定"),
                        trailing: const CupertinoListTileChevron(),
                        onTap: currentCity != null
                            ? () {
                                Navigator.push<String>(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => CupertinoTownPage(city: currentCity!, town: currentTown),
                                  ),
                                ).then(setTownLocation);
                              }
                            : null,
                      ),
                    ],
                  ),
                  CupertinoListSection(
                    header: const Text("一般"),
                    children: [
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
                          }),
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
                    ],
                  ),
                  CupertinoListSection(
                    header: const Text("除錯"),
                    children: [
                      CupertinoListTile(
                        title: const Text("版本"),
                        additionalInfo: Text(Global.packageInfo.version),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        title: const Text("建置號碼"),
                        additionalInfo: Text(Global.packageInfo.buildNumber),
                        onTap: () {},
                      ),
                      CupertinoListTile(
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
                      CupertinoListTile(
                        title: const Text("重置 FCM 主題訂閱"),
                        onTap: unsubscribeAllTopics,
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
                      "所在地",
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_city_rounded),
                    title: const Text('縣市'),
                    subtitle: Text(currentCity ?? "尚未設定"),
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
                                  setCityLocation(value);
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
                    subtitle: Text(currentTown ?? "尚未設定"),
                    enabled: currentCity != null,
                    onTap: () {
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
                                  setTownLocation(value);
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
                  ListTile(
                    leading: const Icon(Icons.bug_report_rounded),
                    title: const Text("重置 FCM 主題訂閱"),
                    onTap: unsubscribeAllTopics,
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
