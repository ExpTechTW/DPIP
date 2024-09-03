import "package:clipboard/clipboard.dart";
import "package:dpip/global.dart";
import "package:dpip/route/announcement/announcement.dart";
import "package:dpip/route/changelog/changelog.dart";
import "package:dpip/route/log/log.dart";
import "package:dpip/route/notification/notification.dart";
import "package:dpip/route/settings/settings.dart";
import "package:dpip/route/sound/sound.dart";
import "package:dpip/route/status/status.dart";
import "package:dpip/route/welcome/welcome.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:simple_icons/simple_icons.dart";
import "package:url_launcher/url_launcher.dart";

import "developer.dart";

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
        ListTileGroupHeader(title: context.i18n.me_general),
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
          title: Text(context.i18n.notify_test),
          subtitle: Text(context.i18n.notify_test_description),
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
          leading: const Icon(Symbols.campaign_rounded, fill: 1),
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
        ListTile(
          leading: const Icon(Symbols.favorite_rounded, fill: 1),
          title: Text(context.i18n.donate),
          subtitle: Text(context.i18n.donate_h2),
          onTap: () {
            launchUrl(Uri.parse("https://exptech.com.tw/donate"));
          },
        ),
        ListTileGroupHeader(title: context.i18n.me_debug),
        ListTile(
          leading: const Icon(Symbols.bug_report),
          title: Text(context.i18n.app_logs),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LogViewerPage()),
            );
          },
        ),
        /**
         * 複製 FCM Token
         */
        ListTile(
          leading: const Icon(Icons.fingerprint),
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
                SnackBar(
                  content: Text(context.i18n.copy_fcm_token_error),
                ),
              );
            }
          },
        ),
        ListTileGroupHeader(title: context.i18n.me_about),
        ListTile(
          leading: const Icon(Symbols.forum_rounded),
          title: Text(context.i18n.me_developer),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DPIPInfoPage()),
            );
          },
        ),

        /**
         * 打開歡迎頁面
         */
        ListTile(
          leading: const Icon(Icons.visibility),
          title: Text(context.i18n.me_welcome),
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (context) => const WelcomeRoute()),
            );
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
                    context.i18n
                        .me_version(Global.packageInfo.version.toString(), Global.packageInfo.buildNumber.toString()),
                    textAlign: TextAlign.center,
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    ActionChip(
                      avatar: const Icon(Symbols.group_rounded, fill: 1),
                      label: Text(context.i18n.contributor),
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
                      avatar: const Icon(Symbols.notifications_rounded),
                      label: Text(context.i18n.notification_record),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationHistoryPage()),
                        );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Symbols.dns_rounded),
                      label: Text(context.i18n.server_status),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ServerStatusPage()),
                        );
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
