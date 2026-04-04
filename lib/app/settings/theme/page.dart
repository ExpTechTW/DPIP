/// Theme settings page for adjusting the app's visual appearance.
library;

import 'package:dpip/app/settings/_widgets/settings_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/theme.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flex_color_picker/flex_color_picker.dart' show ColorTools;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// A settings page for choosing the theme mode and accent color.
///
/// Requires [SettingsUserInterfaceModel] in the widget tree.
class SettingsThemePage extends StatelessWidget {
  /// Creates a [SettingsThemePage].
  const SettingsThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView(
          children: [
            SettingsHeader(
              icon: Symbols.palette_rounded,
              title: Text('主題'.i18n),
              subtitle: Text('調整 DPIP 整體的外觀與顏色'.i18n),
            ),
            const SizedBox(height: 16),
            SegmentedList(
              children: [
                Selector<SettingsUserInterfaceModel, ThemeMode>(
                  selector: (context, model) => model.themeMode,
                  builder: (context, themeMode, child) {
                    return SegmentedListTile(
                      isFirst: true,
                      leading: ContainedIcon(
                        switch (context.theme.brightness) {
                          .light => Symbols.light_mode_rounded,
                          .dark => Symbols.dark_mode_rounded,
                        },
                        color: switch (context.theme.brightness) {
                          .light => Colors.orange,
                          .dark => Colors.blue[300]!,
                        },
                      ),
                      title: Text('主題模式'.i18n),
                      subtitle: Text(themeMode.label.i18n),
                      trailing: const Icon(Symbols.chevron_right_rounded),
                      onTap: () =>
                          const SettingsThemeModeRoute().push(context),
                    );
                  },
                ),
                Selector<SettingsUserInterfaceModel, Color?>(
                  selector: (context, model) => model.themeColor,
                  builder: (context, themeColor, child) {
                    return SegmentedListTile(
                      isLast: true,
                      leading: ContainedIcon(
                        Symbols.colorize_rounded,
                        color: themeColor ?? context.colors.primary,
                      ),
                      title: Text('主題色彩'.i18n),
                      subtitle: Text(switch (themeColor) {
                        null => '使用系統配色'.i18n,
                        final v => ColorTools.nameThatColor(v),
                      }),
                      trailing: const Icon(Symbols.chevron_right_rounded),
                      onTap: () =>
                          const SettingsThemeColorRoute().push(context),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
