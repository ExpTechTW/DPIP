import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';

class SettingsThemeSelectPage extends StatelessWidget {
  const SettingsThemeSelectPage({super.key});

  static const route = '/settings/theme/select';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        Section(
          label: Text('主題色'.i18n),
          children: [
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder: (context, themeMode, child) => SectionListTile(
                isFirst: true,
                leading: Icon(Symbols.light_mode_rounded),
                title: Text('淺色'.i18n),
                trailing: Icon(
                  themeMode == ThemeMode.light ? Symbols.check : null,
                ),
                onTap: () {
                  context.read<SettingsUserInterfaceModel>().setThemeMode(
                    ThemeMode.light,
                  );
                  context.pop();
                },
              ),
            ),
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder: (context, themeMode, child) => SectionListTile(
                leading: Icon(Symbols.dark_mode_rounded),
                title: Text('深色'.i18n),
                trailing: Icon(
                  themeMode == ThemeMode.dark ? Symbols.check : null,
                ),
                onTap: () {
                  context.read<SettingsUserInterfaceModel>().setThemeMode(
                    ThemeMode.dark,
                  );
                  context.pop();
                },
              ),
            ),
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder: (context, themeMode, child) => SectionListTile(
                isLast: true,
                leading: Icon(Symbols.devices_rounded),
                title: Text('跟隨系統主題'.i18n),
                subtitle: Text(switch (MediaQuery.of(
                  context,
                ).platformBrightness) {
                  Brightness.light => '淺色'.i18n,
                  Brightness.dark => '深色'.i18n,
                }),
                trailing: Icon(
                  themeMode == ThemeMode.system ? Symbols.check : null,
                ),
                onTap: () {
                  context.read<SettingsUserInterfaceModel>().setThemeMode(
                    ThemeMode.system,
                  );
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
