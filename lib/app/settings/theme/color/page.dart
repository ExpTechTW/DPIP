import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/color_picker.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsThemeColorPage extends StatelessWidget {
  const SettingsThemeColorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.useUserInterface.themeColor;

    return ListView(
      padding: .only(bottom: context.padding.bottom + 64),
      children: [
        SegmentedList(
          label: Text('主題色彩'.i18n),
          children: [
            DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                final seed = switch (context.theme.brightness) {
                  .light => lightDynamic ?? ColorScheme.light(),
                  .dark => darkDynamic ?? ColorScheme.dark(),
                }.primary;

                final colors = ColorScheme.fromSeed(
                  seedColor: seed,
                  brightness: context.theme.brightness,
                );

                return SegmentedListTile(
                  isFirst: true,
                  leading: ContainedIcon(
                    Symbols.devices_rounded,
                    color: colors.primary,
                  ),
                  title: Text(
                    '使用系統配色'.i18n,
                    style: TextStyle(color: colors.onSurface),
                  ),
                  tileColor: colors.surfaceContainerHigh,
                  subtitle: Text(
                    '#${colors.primary.toHexString()}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  trailing: color == null ? Icon(Symbols.check_rounded) : null,
                  onTap: () => context.userInterface.setThemeColor(null),
                );
              },
            ),
            SegmentedListTile(
              isLast: true,
              leading: ContainedIcon(
                Symbols.format_paint_rounded,
                color: color,
              ),
              title: Text('自訂'.i18n),
              subtitle: color != null ? Text('#${color.toHexString()}') : null,
              trailing: color != null ? Icon(Symbols.check_rounded) : null,
              onTap: () =>
                  context.userInterface.setThemeColor(context.colors.primary),
            ),
          ],
        ),
        if (color != null)
          SegmentedList(
            label: Text('自訂色彩'.i18n),
            children: [
              ColorPicker(
                color: .fromColor(color),
                onChanged: (value) {
                  context.userInterface.setThemeColor(value.toColor());
                },
              ),
            ],
          ),
      ],
    );
  }
}
