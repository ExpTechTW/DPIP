import 'package:flutter/material.dart';

import 'package:clipboard/clipboard.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/app/settings/donate/page.dart';
import 'package:dpip/app/settings/locale/page.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/app/settings/sound/page.dart';
import 'package:dpip/app/settings/theme/page.dart';
import 'package:dpip/app/settings/unit/page.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  static const route = '/settings';

  @override
  Widget build(BuildContext context) {
    final appInfo = '${Global.packageInfo.version}(${Global.packageInfo.buildNumber})';
    final deviceInfo =
        '${DeviceInfo.model}${DeviceInfo.serial != null ? '' : ''}(${DeviceInfo.version})';

    final location = SettingsListSection(
      title: context.i18n.settings_position,
      children: [
        SettingsListTile(
          icon: Symbols.pin_drop_rounded,
          title: context.i18n.settings_location,
          subtitle: Text(context.i18n.settings_location_description),
          onTap: () {
            context.push(SettingsLocationPage.route);
          },
        ),
      ],
    );

    final userInterface = SettingsListSection(
      title: 'User Interface',
      children: [
        SettingsListTile(
          icon: Symbols.brush_rounded,
          title: context.i18n.settings_theme,
          subtitle: Text(context.i18n.settings_theme_description),
          onTap: () {
            context.push(SettingsThemePage.route);
          },
        ),
        SettingsListTile(
          icon: Symbols.translate_rounded,
          title: context.i18n.settings_locale,
          subtitle: Text(context.i18n.settings_locale_description),
          onTap: () {
            context.push(SettingsLocalePage.route);
          },
        ),
        SettingsListTile(
          icon: Symbols.percent_rounded,
          title: '單位',
          subtitle: const Text('調整 DPIP 顯示數值時使用的單位'),
          onTap: () => context.push(SettingsUnitPage.route),
        ),
      ],
    );

    final notification = SettingsListSection(
      title: 'Notification',
      children: [
        SettingsListTile(
          icon: Symbols.notifications_rounded,
          title: 'Notification',
          subtitle: const Text('Notification'),
          onTap: () => context.push(SettingsNotifyPage.route),
        ),
        SettingsListTile(
          icon: Symbols.audiotrack_sharp,
          title: context.i18n.notify_test,
          subtitle: Text(context.i18n.notify_test_description),
          onTap: () => context.push(SettingsSoundPage.route),
        ),
      ],
    );

    final information = SettingsListSection(
      title: 'Information',
      children: [
        SettingsListTile(
          icon: Symbols.newspaper_rounded,
          title: context.i18n.announcement,
          subtitle: const Text('來自 ExpTech Studio 的最新消息'),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/announcement'),
        ),
        SettingsListTile(
          icon: Symbols.update_rounded,
          title: context.i18n.update_log,
          subtitle: const Text('查看 DPIP 更新了什麼新東西'),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/changelog'),
        ),
        SettingsListTile(
          icon: Symbols.volunteer_activism_rounded,
          title: context.i18n.donate,
          subtitle: Text(context.i18n.donate_h2),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push(SettingsDonatePage.route),
        ),
        SettingsListTile(
          icon: Symbols.book_rounded,
          title: context.i18n.third_party_libraries,
          subtitle: const Text('DPIP 的實現歸功於開放源始碼'),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push('/license'),
        ),
      ],
    );

    final links = SettingsListSection(
      title: 'ExpTech Studio',
      children: [
        SettingsListTile(
          icon: SimpleIcons.github,
          title: 'Github',
          subtitle: const Text('ExpTechTW'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://github.com/ExpTechTW')),
        ),
        SettingsListTile(
          icon: SimpleIcons.discord,
          title: 'Discord',
          subtitle: const Text('.gg/exptech-studio'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://discord.gg/exptech-studio')),
        ),
        SettingsListTile(
          icon: SimpleIcons.threads,
          title: 'Threads',
          subtitle: const Text('@dpip.tw'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://www.threads.net/@dpip.tw')),
        ),
        SettingsListTile(
          icon: SimpleIcons.youtube,
          title: 'Youtube',
          subtitle: const Text('@exptechtw'),
          trailing: const Icon(Symbols.arrow_outward_rounded),
          onTap: () => launchUrl(Uri.parse('https://www.youtube.com/@exptechtw/live')),
        ),
      ],
    );

    final debug = SettingsListSection(
      title: context.i18n.me_debug,
      children: [
        SettingsListTile(
          icon: Symbols.bug_report_rounded,
          title: 'App Version',
          trailing: Text(appInfo),
          onLongPress: () => FlutterClipboard.copy(appInfo),
        ),
        SettingsListTile(
          icon: Symbols.bug_report_rounded,
          title: 'Device Info',
          trailing: Text(deviceInfo),
          onLongPress: () => FlutterClipboard.copy(deviceInfo),
        ),
        SettingsListTile(
          icon: Symbols.bug_report_rounded,
          title: context.i18n.settings_fcm,
          trailing: const Icon(Symbols.content_copy_rounded),
          onTap: () => FlutterClipboard.copy(Preference.notifyToken),
        ),
        SettingsListTile(
          icon: Symbols.bug_report_rounded,
          title: context.i18n.app_logs,
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => context.push(AppDebugLogsPage.route),
        ),
      ],
    );

    final footer = SettingsListTextSection(
      content:
          'ExpTech Studio © 2025\n'
          '${context.i18n.official_info}',
      contentColor: context.theme.colorScheme.outline,
    );

    return ListView(
      padding: EdgeInsets.only(top: 16, bottom: 16 + context.padding.bottom),
      children: [location, userInterface, notification, information, links, debug, footer],
    );
  }
}
