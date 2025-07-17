import 'package:clipboard/clipboard.dart';
import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/settings/donate/page.dart';
import 'package:dpip/app/settings/locale/page.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/map/page.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/app/settings/theme/page.dart';
import 'package:dpip/app/settings/unit/page.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  static const route = '/settings';

  @override
  Widget build(BuildContext context) {
    final appInfo = '${Global.packageInfo.version}(${Global.packageInfo.buildNumber})';
    final deviceInfo = '${DeviceInfo.model}${DeviceInfo.serial != null ? '' : ''}(${DeviceInfo.version})';

    final location = ListSection(
      title: '位置'.i18n,
      children: [
        ListSectionTile(
          icon: Symbols.pin_drop_rounded,
          title: '所在地'.i18n,
          subtitle: Text('設定你的所在地來接收當地的即時資訊'.i18n),
          onTap: () {
            context.push(SettingsLocationPage.route);
          },
        ),
      ],
    );

    final userInterface = ListSection(
      title: '介面'.i18n,
      children: [
        ListSectionTile(
          icon: Symbols.brush_rounded,
          title: '主題'.i18n,
          subtitle: Text('調整 DPIP 整體的外觀與顏色'.i18n),
          onTap: () {
            context.push(SettingsThemePage.route);
          },
        ),
        ListSectionTile(
          icon: Symbols.translate_rounded,
          title: '語言'.i18n,
          subtitle: Text('調整 DPIP 的顯示語言'.i18n),
          onTap: () {
            context.push(SettingsLocalePage.route);
          },
        ),
        ListSectionTile(
          icon: Symbols.percent_rounded,
          title: '單位'.i18n,
          subtitle: Text('調整 DPIP 顯示數值時使用的單位'.i18n),
          onTap: () => context.push(SettingsUnitPage.route),
        ),
        ListSectionTile(
          icon: Symbols.map_rounded,
          title: '地圖'.i18n,
          subtitle: Text('調整 DPIP 地圖的設定'.i18n),
          onTap: () => context.push(SettingsMapPage.route),
        ),
      ],
    );

    final notification = ListSection(
      title: '通知'.i18n,
      children: [
        ListSectionTile(
          icon: Symbols.notification_settings_rounded,
          title: '通知'.i18n,
          subtitle: Text('推播通知設定與通知音效測試'.i18n),
          onTap: () => context.push(SettingsNotifyPage.route),
        ),
      ],
    );

    final information = ListSection(
      title: '資訊'.i18n,
      children: [
        ListSectionTile(
          icon: Symbols.newspaper_rounded,
          title: '公告'.i18n,
          subtitle: Text('掌握 ExpTech Studio 的最新公告與資訊'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/announcement'),
        ),
        ListSectionTile(
          icon: Symbols.update_rounded,
          title: '更新日誌'.i18n,
          subtitle: Text('瀏覽 DPIP 的歷次更新紀錄'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/changelog'),
        ),
        ListSectionTile(
          icon: Symbols.volunteer_activism_rounded,
          title: '贊助我們'.i18n,
          subtitle: Text('幫助我們維護伺服器的穩定和長久發展'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push(SettingsDonatePage.route),
        ),
        ListSectionTile(
          icon: Symbols.book_rounded,
          title: '第三方套件授權'.i18n,
          subtitle: Text('DPIP 的實現歸功於開放源始碼'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/license'),
        ),
      ],
    );

    final links = ListSection(
      title: 'ExpTech Studio',
      children: [
        ListSectionTile(
          icon: SimpleIcons.github,
          title: 'Github',
          subtitle: const Text('ExpTechTW'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://github.com/ExpTechTW')),
        ),
        ListSectionTile(
          icon: SimpleIcons.discord,
          title: 'Discord',
          subtitle: const Text('.gg/exptech-studio'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://discord.gg/exptech-studio')),
        ),
        ListSectionTile(
          icon: SimpleIcons.threads,
          title: 'Threads',
          subtitle: const Text('@dpip.tw'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://www.threads.net/@dpip.tw')),
        ),
        ListSectionTile(
          icon: SimpleIcons.youtube,
          title: 'Youtube',
          subtitle: const Text('@exptechtw'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://www.youtube.com/@exptechtw/live')),
        ),
      ],
    );

    final debug = ListSection(
      title: '除錯'.i18n,
      children: [
        ListSectionTile(
          icon: Symbols.bug_report_rounded,
          title: '應用程式版本'.i18n,
          trailing: Text(appInfo),
          onLongPress: () => FlutterClipboard.copy(appInfo),
        ),
        ListSectionTile(
          icon: Symbols.bug_report_rounded,
          title: '裝置資訊'.i18n,
          trailing: Text(deviceInfo),
          onLongPress: () => FlutterClipboard.copy(deviceInfo),
        ),
        ListSectionTile(
          icon: Symbols.bug_report_rounded,
          title: '複製通知 Token'.i18n,
          trailing: const Icon(Symbols.content_copy_rounded),
          onTap: () => FlutterClipboard.copy(Preference.notifyToken),
        ),
        ListSectionTile(
          icon: Symbols.bug_report_rounded,
          title: 'App 日誌'.i18n,
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push(AppDebugLogsPage.route),
        ),
      ],
    );

    final footer = SettingsListTextSection(
      content: 'ExpTech Studio © 2025\n${'任何資訊應以中央氣象署發布之內容為準。'.i18n}',
      contentColor: context.theme.colorScheme.outline,
    );

    return ListView(
      padding: EdgeInsets.only(top: 16, bottom: 16 + context.padding.bottom),
      children: [location, userInterface, notification, information, links, debug, footer],
    );
  }
}
