import "package:clipboard/clipboard.dart";
import "package:dpip/global.dart";
import "package:dpip/route/announcement/announcement.dart";
import "package:dpip/route/changelog/changelog.dart";
import "package:dpip/route/settings/settings.dart";
import "package:dpip/route/sound/sound.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:simple_icons/simple_icons.dart";
import "package:url_launcher/url_launcher.dart";

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
        ListTileGroupHeader(title: context.i18n.me_generally),
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
         * 更新日誌
         */
        ListTile(
          leading: const Icon(Symbols.announcement_rounded),
          title: Text(context.i18n.announcement),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnnouncementPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Symbols.update_rounded),
          title: Text(context.i18n.update_log),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangelogPage()),
            );
          },
        ),
        ListTileGroupHeader(title: context.i18n.me_debug),

        /**
         * 複製 FCM Token
         */
        ListTile(
          leading: const Icon(Icons.bug_report_rounded),
          title: Text(context.i18n.settings_fcm),
          onTap: () {
            String token = Global.preference.getString("fcm-token") ?? "";
            if (token != "") {
              FlutterClipboard.copy(token);
              context.scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(context.i18n.settings_copy_fcm),
                ),
              );
            } else {
              context.scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text("複製 FCM Token 時發生錯誤"),
                ),
              );
            }
          },
        ),

        /**
         * App 資訊
         */
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
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
                    ActionChip(
                      avatar: Icon(Symbols.group_rounded, fill: 1),
                      label: Text(context.i18n.contributor),
                    ),
                    ActionChip(
                      avatar: const Icon(Symbols.favorite_rounded, fill: 1),
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
                      avatar: const Icon(Symbols.web_rounded),
                      label: Text(context.i18n.official_web),
                      onPressed: () {
                        launchUrl(Uri.parse("https://exptech.com.tw/dpip"));
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.history),
                      label: Text(context.i18n.notification_record),
                      onPressed: () {
                        launchUrl(Uri.parse("https://exptech.com.tw/history/notification"));
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
                      avatar: const Icon(Symbols.pulse_alert, fill: 1),
                      label: Text(context.i18n.server_status),
                      onPressed: () {
                        launchUrl(Uri.parse("https://status.exptech.dev"));
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Symbols.book_rounded, fill: 1),
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
        )
      ],
    );
  }
}
