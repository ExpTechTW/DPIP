/// Theme mode settings page.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// A page for selecting the app theme mode (light, dark, or system).
///
/// Selecting a mode immediately applies it and pops the page. Requires
/// [SettingsUserInterfaceModel] in the widget tree.
class SettingsThemeModePage extends StatelessWidget {
  /// Creates a [SettingsThemeModePage].
  const SettingsThemeModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: .only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        SegmentedList(
          label: Text('主題模式'.i18n),
          children: [
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder: (context, themeMode, child) => SegmentedListTile(
                isFirst: true,
                leading: Icon(Symbols.light_mode_rounded),
                title: Text('淺色'.i18n),
                trailing: Icon(
                  themeMode == .light ? Symbols.check_rounded : null,
                ),
                onTap: () {
                  context.read<SettingsUserInterfaceModel>().setThemeMode(
                    .light,
                  );
                  context.pop();
                },
              ),
            ),
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder: (context, themeMode, child) => SegmentedListTile(
                leading: Icon(Symbols.dark_mode_rounded),
                title: Text('深色'.i18n),
                trailing: Icon(
                  themeMode == .dark ? Symbols.check_rounded : null,
                ),
                onTap: () {
                  context.read<SettingsUserInterfaceModel>().setThemeMode(
                    .dark,
                  );
                  context.pop();
                },
              ),
            ),
            Selector<SettingsUserInterfaceModel, ThemeMode>(
              selector: (context, model) => model.themeMode,
              builder: (context, themeMode, child) => SegmentedListTile(
                isLast: true,
                leading: Icon(Symbols.devices_rounded),
                title: Text('跟隨系統主題'.i18n),
                subtitle: Text(switch (context.brightness) {
                  .light => '淺色'.i18n,
                  .dark => '深色'.i18n,
                }),
                trailing: Icon(
                  themeMode == .system ? Symbols.check_rounded : null,
                ),
                onTap: () {
                  context.read<SettingsUserInterfaceModel>().setThemeMode(
                    .system,
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
