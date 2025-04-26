import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
      children: [
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
              onTap: () {
                context.push('/settings/notify');
              },
            ),
          ],
        ),
      ],
    );
  }
}
