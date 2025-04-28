import 'package:clipboard/clipboard.dart';
import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appInfo = '${Global.packageInfo.version}(${Global.packageInfo.buildNumber})';
    final deviceInfo =
        '${DeviceInfo.model}${DeviceInfo.serial != null ? '(${DeviceInfo.serial})' : ''}(${DeviceInfo.version})';

    return ListView(
      controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
      children: [
        SettingsListSection(
          title: context.i18n.settings_position,
          children: [
            SettingsListTile(
              icon: Symbols.pin_drop_rounded,
              title: context.i18n.settings_location,
              subtitle: Text(context.i18n.settings_location_description),
              onTap: () {
                context.push('/settings/location');
              },
            ),
          ],
        ),
        SettingsListSection(
          title: 'User Interface',
          children: [
            SettingsListTile(
              icon: Symbols.brush_rounded,
              title: context.i18n.settings_theme,
              subtitle: Text(context.i18n.settings_theme_description),
              onTap: () {
                context.push('/settings/theme');
              },
            ),
            SettingsListTile(
              icon: Symbols.translate_rounded,
              title: context.i18n.settings_locale,
              subtitle: Text(context.i18n.settings_locale_description),
              onTap: () {
                context.push('/settings/locale');
              },
            ),
          ],
        ),
        SettingsListSection(
          title: 'Notification',
          children: [
            SettingsListTile(
              icon: Symbols.notifications_rounded,
              title: 'Notification',
              subtitle: Text('Notification'),
              onTap: () => context.push('/settings/notify'),
            ),
          ],
        ),
        SettingsListSection(
          title: 'Information',
          children: [
            SettingsListTile(
              icon: Symbols.newspaper_rounded,
              title: context.i18n.announcement,
              subtitle: Text('來自 ExpTech Studio 的最新消息'),
              trailing: Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push('/announcement'),
            ),
            SettingsListTile(
              icon: Symbols.update_rounded,
              title: context.i18n.update_log,
              subtitle: Text('查看 DPIP 更新了什麼新東西'),
              trailing: Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push('/changelog'),
            ),
            SettingsListTile(
              icon: Symbols.volunteer_activism_rounded,
              title: context.i18n.donate,
              subtitle: Text(context.i18n.donate_h2),
              trailing: Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(Uri.parse('https://exptech.com.tw/donate')),
            ),
            SettingsListTile(
              icon: Symbols.book_rounded,
              title: context.i18n.third_party_libraries,
              subtitle: Text('DPIP 的實現歸功於開放源始碼'),
              trailing: Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push('/license'),
            ),
          ],
        ),
        SettingsListSection(
          title: 'ExpTech Studio',
          children: [
            SettingsListTile(
              icon: SimpleIcons.github,
              title: 'Github',
              subtitle: Text('ExpTechTW'),
              trailing: Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(Uri.parse('https://github.com/ExpTechTW')),
            ),
            SettingsListTile(
              icon: SimpleIcons.discord,
              title: 'Discord',
              subtitle: Text('.gg/exptech-studio'),
              trailing: Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(Uri.parse('https://discord.gg/exptech-studio')),
            ),
            SettingsListTile(
              icon: SimpleIcons.threads,
              title: 'Threads',
              subtitle: Text('@dpip.tw'),
              trailing: Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(Uri.parse('https://www.threads.net/@dpip.tw')),
            ),
            SettingsListTile(
              icon: SimpleIcons.youtube,
              title: 'Youtube',
              subtitle: Text('@exptechtw'),
              trailing: Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(Uri.parse('https://www.youtube.com/@exptechtw/live')),
            ),
          ],
        ),
        if (kDebugMode)
          SettingsListSection(
            title: 'Debug',
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
                title: context.i18n.app_logs,
                trailing: Icon(Symbols.chevron_right_rounded),
                onTap: () => context.push('/debug/logs'),
              ),
            ],
          ),
        SettingsListTextSection(
          content:
              'ExpTech Studio © 2025\n'
              '${context.i18n.official_info}',
        ),
      ],
    );
  }
}
