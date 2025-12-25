import 'package:dpip/app/settings/theme/select/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsThemePage extends StatelessWidget {
  const SettingsThemePage({super.key});

  static const route = '/settings/theme';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '主題模式'.i18n,
          children: [
            Consumer<SettingsUserInterfaceModel>(
              builder: (context, model, child) {
                return ListSectionTile(
                  icon: Symbols.dark_mode_rounded,
                  title: '主題模式'.i18n,
                  subtitle: Text(switch (model.themeMode) {
                    ThemeMode.light => '淺色'.i18n,
                    ThemeMode.dark => '深色'.i18n,
                    ThemeMode.system => '跟隨系統主題'.i18n,
                  }),
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  onTap: () => context.push(SettingsThemeSelectPage.route),
                );
              },
            ),
            Consumer<SettingsUserInterfaceModel>(
              builder: (context, model, child) {
                return ListSectionTile(
                  icon: Symbols.palette_rounded,
                  title: '主題色'.i18n,
                  subtitle: Text(
                    model.themeColor != null
                        ? ColorTools.nameThatColor(model.themeColor!)
                        : '系統色彩'.i18n,
                  ),
                  trailing: ColorIndicator(
                    color: model.themeColor ?? context.colors.primary,
                  ),
                  onTap: () async {
                    final result = await showDialog<Color>(
                      context: context,
                      builder: (context) {
                        Color pickerColor =
                            model.themeColor ?? context.colors.primary;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              content: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 360,
                                ),
                                child: ColorPicker(
                                  mainAxisSize: MainAxisSize.min,
                                  padding: EdgeInsets.zero,
                                  color: pickerColor,
                                  onColorChanged: (color) =>
                                      setState(() => pickerColor = color),
                                  enableTonalPalette: true,
                                  enableShadesSelection: false,
                                  showMaterialName: true,
                                  showColorName: true,
                                  showColorCode: true,
                                  tonalColorSameSize: true,
                                  pickersEnabled: const <ColorPickerType, bool>{
                                    ColorPickerType.primary: true,
                                    ColorPickerType.accent: false,
                                    ColorPickerType.wheel: true,
                                  },
                                  copyPasteBehavior:
                                      const ColorPickerCopyPasteBehavior(
                                        copyFormat:
                                            ColorPickerCopyFormat.numHexRRGGBB,
                                        snackBarParseError: true,
                                        longPressMenu: true,
                                      ),
                                  actionButtons: const ColorPickerActionButtons(
                                    dialogActionButtons: false,
                                  ),
                                ),
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                8,
                              ),
                              actionsAlignment: MainAxisAlignment.spaceBetween,
                              actionsOverflowButtonSpacing: 8,
                              actions: [
                                TextButton(
                                  child: Text('使用系統顏色'.i18n),
                                  onPressed: () {
                                    model.setThemeColor(null);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      child: Text('取消'.i18n),
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pop(model.themeColor);
                                      },
                                    ),
                                    FilledButton(
                                      child: Text('確定'.i18n),
                                      onPressed: () {
                                        Navigator.of(context).pop(pickerColor);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                    if (result == null) return;
                    model.setThemeColor(result);
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
