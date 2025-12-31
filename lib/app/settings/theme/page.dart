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

class SettingsThemePage extends StatelessWidget {
  const SettingsThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView(
          children: [
            _buildHeader(context),
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
                      onTap: () => const SettingsThemeModeRoute().push(context),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Symbols.palette_rounded,
              color: context.colors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主題設定'.i18n,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '自訂應用程式的外觀'.i18n,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
