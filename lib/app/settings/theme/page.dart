import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsThemePage extends StatelessWidget {
  const SettingsThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
      children: [
        SettingsListSection(
          title: '主題模式',
          children: [
            Consumer<SettingsUserInterfaceModel>(
              builder: (context, model, child) {
                return ListTile(
                  leading: Icon(Symbols.dark_mode_rounded),
                  title: Text('主題模式', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(model.themeMode.name.capitalize),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text('主題模式'),
                          children: [
                            RadioListTile(
                              value: ThemeMode.light,
                              groupValue: model.themeMode,
                              title: Text(context.i18n.theme_light),
                              onChanged: (value) {
                                if (value == null) return;
                                model.setThemeMode(value);
                                Navigator.of(context).pop();
                              },
                            ),
                            RadioListTile(
                              value: ThemeMode.dark,
                              groupValue: model.themeMode,
                              title: Text(context.i18n.theme_dark),
                              onChanged: (value) {
                                if (value == null) return;
                                model.setThemeMode(value);
                                Navigator.of(context).pop();
                              },
                            ),
                            RadioListTile(
                              value: ThemeMode.system,
                              groupValue: model.themeMode,
                              title: Text(context.i18n.theme_system),
                              onChanged: (value) {
                                if (value == null) return;
                                model.setThemeMode(value);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            Consumer<SettingsUserInterfaceModel>(
              builder: (context, model, child) {
                return ListTile(
                  leading: Icon(Symbols.palette_rounded),
                  title: Text('主題色', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(model.themeColor != null ? ColorTools.nameThatColor(model.themeColor!) : '系統色彩'),
                  trailing: ColorIndicator(color: model.themeColor ?? context.colors.primary),
                  onTap: () async {
                    final result = await showDialog<Color>(
                      context: context,
                      builder: (context) {
                        Color pickerColor = model.themeColor ?? context.colors.primary;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              content: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 360),
                                child: ColorPicker(
                                  mainAxisSize: MainAxisSize.min,
                                  padding: EdgeInsets.zero,
                                  color: pickerColor,
                                  onColorChanged: (color) => setState(() => pickerColor = color),
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
                                  copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                                    copyFormat: ColorPickerCopyFormat.numHexRRGGBB,
                                    snackBarParseError: true,
                                    longPressMenu: true,
                                  ),
                                  actionButtons: ColorPickerActionButtons(dialogActionButtons: false),
                                ),
                              ),
                              contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                              actionsAlignment: MainAxisAlignment.spaceBetween,
                              actionsOverflowButtonSpacing: 8,
                              actions: [
                                TextButton(
                                  child: Text('Use system color'),
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
                                      child: Text(context.i18n.cancel),
                                      onPressed: () {
                                        Navigator.of(context).pop(model.themeColor);
                                      },
                                    ),
                                    FilledButton(
                                      child: Text(context.i18n.confirm),
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
