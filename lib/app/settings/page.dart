import 'package:clipboard/clipboard.dart';
import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              trailing: Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push('/announcement'),
            ),
            SettingsListTile(
              icon: Symbols.update_rounded,
              title: context.i18n.update_log,
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
          ],
        ),
        if (kDebugMode)
          SettingsListSection(
            title: 'Debug',
            children: [
              SettingsListTile(
                icon: Symbols.bug_report_rounded,
                title: 'App Version',
                trailing: Text(Global.packageInfo.version),
                onLongPress: () => FlutterClipboard.copy(Global.packageInfo.version),
              ),
              SettingsListTile(
                icon: Symbols.bug_report_rounded,
                title: 'Build Number',
                trailing: Text(Global.packageInfo.buildNumber),
                onLongPress: () => FlutterClipboard.copy(Global.packageInfo.buildNumber),
              ),
              SettingsListTile(
                icon: Symbols.bug_report_rounded,
                title: context.i18n.app_logs,
                trailing: Icon(Symbols.chevron_right_rounded),
                onTap: () => context.push('/debug/logs'),
              ),
            ],
          ),
      ],
    );
  }
}
