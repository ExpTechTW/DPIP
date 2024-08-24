import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/changelog/changelog.dart';
import 'package:dpip/route/settings/settings.dart';
import 'package:dpip/route/sound/sound.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        /**
         * 設定
         */
        ListTile(
          leading: const Icon(Symbols.tune),
          title: Text(context.i18n.settings),
          subtitle: Text(context.i18n.settingsDescription),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: "/settings"),
              builder: (context) => const SettingsRoute(),
            ),
          ),
        ),

        /**
         * 音效測試
         */
        ListTile(
          leading: const Icon(Symbols.audiotrack_sharp),
          title: Text(context.i18n.sound_test),
          subtitle: Text(context.i18n.sound_test_description),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: "/sound"),
              builder: (context) => const SoundRoute(),
            ),
          ),
        ),

        /**
         * 複製 FCM Token
         */
        ListTile(
          leading: Icon(
            Platform.isAndroid ? Icons.bug_report_rounded : CupertinoIcons.square_on_square,
          ),
          title: Text(context.i18n.settings_fcm),
          onTap: () {
            messaging.getToken().then((value) {
              FlutterClipboard.copy(value ?? "");
              context.scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(context.i18n.settings_copy_fcm),
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
          leading: Icon(Symbols.update_rounded),
          title: Text("更新日誌"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangelogPage()),
            );
          },
        ),

        /**
         * App 資訊
         */
        Padding(
          padding: const EdgeInsets.all(8),
          child: Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        "assets/DPIP.png",
                        height: 64,
                        width: 64,
                      ),
                    ),
                  ),
                  const Text(
                    "DPIP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      context.i18n.me_version(Global.packageInfo.version.toString()),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [
                      const ActionChip(
                        avatar: Icon(Symbols.group),
                        label: Text("貢獻者"),
                      ),
                      ActionChip(
                        avatar: const Icon(Symbols.favorite),
                        label: Text(context.i18n.donate),
                        onPressed: () {
                          launchUrl(Uri.parse("https://exptech.com.tw/donate"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(SimpleIcons.github),
                        label: const Text("GitHub"),
                        onPressed: () {
                          launchUrl(Uri.parse("https://github.com/exptechtw/dpip"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(SimpleIcons.discord),
                        label: const Text("Discord"),
                        onPressed: () {
                          launchUrl(Uri.parse("https://exptech.com.tw/dc"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.web_rounded),
                        label: const Text("ExpTech Studio"),
                        onPressed: () {
                          launchUrl(Uri.parse("https://exptech.com.tw/dpip"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.history),
                        label: const Text("行動通知推播紀錄"),
                        onPressed: () {
                          launchUrl(Uri.parse("https://exptech.com.tw/history/notification"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(SimpleIcons.appstore),
                        label: const Text("App Store"),
                        onPressed: () {
                          launchUrl(Uri.parse(
                              "https://apps.apple.com/tw/app/dpip-%E7%81%BD%E5%AE%B3%E5%A4%A9%E6%B0%A3%E8%88%87%E5%9C%B0%E9%9C%87%E9%80%9F%E5%A0%B1/id6468026362"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(SimpleIcons.googleplay),
                        label: const Text("Google Play"),
                        onPressed: () {
                          launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.exptech.dpip"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(SimpleIcons.threads),
                        label: Text(context.i18n.threads),
                        onPressed: () {
                          launchUrl(Uri.parse("https://www.threads.net/@dpip.tw"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(SimpleIcons.youtube),
                        label: Text(context.i18n.youtube),
                        onPressed: () {
                          launchUrl(Uri.parse("https://www.youtube.com/@exptechtw/live"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Symbols.pulse_alert),
                        label: Text(context.i18n.server_status),
                        onPressed: () {
                          launchUrl(Uri.parse("https://status.exptech.dev"));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Symbols.book),
                        label: Text(context.i18n.third_party_libraries),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return const LicensePage();
                            },
                          ));
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
