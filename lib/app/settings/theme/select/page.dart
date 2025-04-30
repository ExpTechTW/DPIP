import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsThemeSelectPage extends StatelessWidget {
  const SettingsThemeSelectPage({super.key});

  static const route = '/settings/theme/select';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SettingsListSection(
          title: context.i18n.settings_theme,
          children: [
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder:
                  (context, themeMode, child) => SettingsListTile(
                    icon: Symbols.light_mode_rounded,
                    title: context.i18n.theme_light,
                    trailing: Icon(themeMode == ThemeMode.light ? Symbols.check : null),
                    onTap: () {
                      context.read<SettingsUserInterfaceModel>().setThemeMode(ThemeMode.light);
                      context.pop();
                    },
                  ),
            ),
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder:
                  (context, themeMode, child) => SettingsListTile(
                    icon: Symbols.dark_mode_rounded,
                    title: context.i18n.theme_dark,
                    trailing: Icon(themeMode == ThemeMode.dark ? Symbols.check : null),
                    onTap: () {
                      context.read<SettingsUserInterfaceModel>().setThemeMode(ThemeMode.dark);
                      context.pop();
                    },
                  ),
            ),
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder:
                  (context, themeMode, child) => SettingsListTile(
                    icon: Symbols.devices_rounded,
                    title: context.i18n.theme_system,
                    subtitle: Text(switch (MediaQuery.of(context).platformBrightness) {
                      Brightness.light => context.i18n.theme_light,
                      Brightness.dark => context.i18n.theme_dark,
                    }),
                    trailing: Icon(themeMode == ThemeMode.system ? Symbols.check : null),
                    onTap: () {
                      context.read<SettingsUserInterfaceModel>().setThemeMode(ThemeMode.system);
                      context.pop();
                    },
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
