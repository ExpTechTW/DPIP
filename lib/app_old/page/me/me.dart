import "dart:io";

import "package:clipboard/clipboard.dart";
import "package:dpip/global.dart";
import "package:dpip/route/announcement/announcement.dart";
import "package:dpip/route/changelog/changelog.dart";
import "package:dpip/route/log/log.dart";
import "package:dpip/route/sound/sound.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/widgets/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons/symbols.dart";
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
          onTap: () => context.push("/settings"),
        ),

        /**
         * 音效測試
         */
        ListTile(
          leading: const Icon(Symbols.audiotrack_sharp),
          title: Text(context.i18n.notify_test),
          subtitle: Text(context.i18n.notify_test_description),
          onTap:
              () => Navigator.push(
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnouncementPage()));
          },
        ),
        ListTile(
          leading: const Icon(Symbols.update_rounded),
          title: Text(context.i18n.update_log),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangelogPage()));
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => LogViewerPage()));
          },
        ),
        /**
         * 複製 FCM Token
         */
        ListTile(
          leading: const Icon(Icons.fingerprint),
          title: Text(context.i18n.settings_fcm),
          onTap: () {
            String token =
                ((Platform.isIOS)
                    ? Global.preference.getString("apns-token")
                    : Global.preference.getString("fcm-token")) ??
                "";
            if (token != "") {
              FlutterClipboard.copy(token);
              context.scaffoldMessenger.showSnackBar(SnackBar(content: Text(context.i18n.settings_copy_fcm)));
            } else {
              context.scaffoldMessenger.showSnackBar(SnackBar(content: Text(context.i18n.copy_fcm_token_error)));
            }
          },
        ),
        ListTileGroupHeader(title: context.i18n.me_about),
        ListTile(
          leading: const Icon(Symbols.forum_rounded),
          title: Text(context.i18n.me_developer),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DPIPInfoPage()));
          },
        ),

        /**
         * 打開歡迎頁面
         */
        ListTile(
          leading: const Icon(Icons.visibility),
          title: Text(context.i18n.me_welcome),
          onTap: () => context.push('/welcome'),
        ),
      ],
    );
  }
}
