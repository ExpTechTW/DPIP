import 'package:flutter/material.dart';

import 'package:clipboard/clipboard.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/settings/donate/page.dart';
import 'package:dpip/app/settings/locale/page.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/map/page.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/app/settings/proxy/page.dart';
import 'package:dpip/app/settings/theme/page.dart';
import 'package:dpip/app/settings/unit/page.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';

import 'layout/page.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  static const route = '/settings';

  @override
  Widget build(BuildContext context) {
    final appInfo =
        '${Global.packageInfo.version}(${Global.packageInfo.buildNumber})';
    final deviceInfo =
        '${DeviceInfo.model}${DeviceInfo.serial != null ? '' : ''}(${DeviceInfo.version})';

    final location = Section(
      label: Text('位置'.i18n),
      children: [
        SectionListTile(
          isFirst: true,
          isLast: true,
          leading: Icon(Symbols.pin_drop_rounded),
          title: Text('所在地'.i18n),
          subtitle: Text('設定你的所在地來接收當地的即時資訊'.i18n),
          onTap: () {
            context.push(SettingsLocationPage.route);
          },
        ),
      ],
    );

    final userInterface = Section(
      label: Text('介面'.i18n),
      children: [
        SectionListTile(
          isFirst: true,
          leading: Icon(Symbols.grid_view_rounded),
          title: Text('佈局'.i18n),
          subtitle: Text('調整 DPIP 的佈局樣式'.i18n),
          onTap: () {
            context.push(SettingsLayoutPage.route);
          },
        ),
        SectionListTile(
          leading: Icon(Symbols.brush_rounded),
          title: Text('主題'.i18n),
          subtitle: Text('調整 DPIP 整體的外觀與顏色'.i18n),
          onTap: () {
            context.push(SettingsThemePage.route);
          },
        ),
        SectionListTile(
          leading: Icon(Symbols.translate_rounded),
          title: Text('語言'.i18n),
          subtitle: Text('調整 DPIP 的顯示語言'.i18n),
          onTap: () {
            context.push(SettingsLocalePage.route);
          },
        ),
        SectionListTile(
          leading: Icon(Symbols.percent_rounded),
          title: Text('單位'.i18n),
          subtitle: Text('調整 DPIP 顯示數值時使用的單位'.i18n),
          onTap: () => context.push(SettingsUnitPage.route),
        ),
        SectionListTile(
          isLast: true,
          leading: Icon(Symbols.map_rounded),
          title: Text('地圖'.i18n),
          subtitle: Text('調整 DPIP 地圖的設定'.i18n),
          onTap: () => context.push(SettingsMapPage.route),
        ),
      ],
    );

    final notification = Section(
      label: Text('通知'.i18n),
      children: [
        SectionListTile(
          isFirst: true,
          isLast: true,
          leading: Icon(Symbols.notification_settings_rounded),
          title: Text('通知'.i18n),
          subtitle: Text('推播通知設定與通知音效測試'.i18n),
          onTap: () => context.push(SettingsNotifyPage.route),
        ),
      ],
    );

    final information = Section(
      label: Text('資訊'.i18n),
      children: [
        SectionListTile(
          isFirst: true,
          leading: Icon(Symbols.newspaper_rounded),
          title: Text('公告'.i18n),
          subtitle: Text('掌握 ExpTech Studio 的最新公告與資訊'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/announcement'),
        ),
        SectionListTile(
          leading: Icon(Symbols.update_rounded),
          title: Text('更新日誌'.i18n),
          subtitle: Text('瀏覽 DPIP 的歷次更新紀錄'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/changelog'),
        ),
        SectionListTile(
          leading: Icon(Symbols.volunteer_activism_rounded),
          title: Text('贊助我們'.i18n),
          subtitle: Text('幫助我們維護伺服器的穩定和長久發展'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push(SettingsDonatePage.route),
        ),
        SectionListTile(
          isLast: true,
          leading: Icon(Symbols.book_rounded),
          title: Text('第三方套件授權'.i18n),
          subtitle: Text('DPIP 的實現歸功於開放源始碼'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/license'),
        ),
      ],
    );

    final links = Section(
      label: Text('ExpTech Studio'),
      children: [
        SectionListTile(
          isFirst: true,
          leading: Icon(SimpleIcons.github),
          title: Text('Github'),
          subtitle: const Text('ExpTechTW'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () =>
              launchUrl(Uri.parse('https://github.com/ExpTechTW/DPIP-Pocket')),
        ),
        SectionListTile(
          leading: Icon(SimpleIcons.discord),
          title: Text('Discord'),
          subtitle: const Text('.gg/exptech-studio'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () =>
              launchUrl(Uri.parse('https://discord.gg/exptech-studio')),
        ),
        SectionListTile(
          leading: Icon(SimpleIcons.threads),
          title: Text('Threads'),
          subtitle: const Text('@dpip.tw'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://www.threads.net/@dpip.tw')),
        ),
        SectionListTile(
          isLast: true,
          leading: Icon(SimpleIcons.youtube),
          title: Text('Youtube'),
          subtitle: const Text('@exptechtw'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () =>
              launchUrl(Uri.parse('https://www.youtube.com/@exptechtw/live')),
        ),
      ],
    );

    final network = Section(
      label: Text('網路'.i18n),
      children: [
        SectionListTile(
          isFirst: true,
          isLast: true,
          leading: Icon(Symbols.settings_ethernet_rounded),
          title: Text('HTTP 代理'.i18n),
          subtitle: Text(
            Preference.proxyEnabled == true
                ? '${Preference.proxyHost ?? ''}:${Preference.proxyPort ?? ''}'
                : '未啟用'.i18n,
          ),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push(SettingsProxyPage.route),
        ),
      ],
    );

    final debug = Section(
      label: Text('除錯'.i18n),
      children: [
        SectionListTile(
          isFirst: true,
          leading: Icon(Symbols.bug_report_rounded),
          title: Text('應用程式版本'.i18n),
          trailing: Text(appInfo),
          onLongPress: () => FlutterClipboard.copy(appInfo),
        ),
        SectionListTile(
          leading: Icon(Symbols.bug_report_rounded),
          title: Text('裝置資訊'.i18n),
          trailing: Text(deviceInfo),
          onLongPress: () => FlutterClipboard.copy(deviceInfo),
        ),
        SectionListTile(
          leading: Icon(Symbols.bug_report_rounded),
          title: Text('複製通知 Token'.i18n),
          trailing: const Icon(Symbols.content_copy_rounded),
          onTap: () => FlutterClipboard.copy(Preference.notifyToken),
        ),
        SectionListTile(
          isLast: true,
          leading: Icon(Symbols.bug_report_rounded),
          title: Text('App 日誌'.i18n),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push(AppDebugLogsPage.route),
        ),
      ],
    );

    final footer = SectionText(
      child: Text('ExpTech Studio © 2025\n${'任何資訊應以中央氣象署發布之內容為準。'.i18n}'),
    );

    return ListView(
      padding: EdgeInsets.only(top: 16, bottom: 16 + context.padding.bottom),
      children: [
        location,
        userInterface,
        notification,
        network,
        information,
        links,
        debug,
        footer,
      ],
    );
  }
}
