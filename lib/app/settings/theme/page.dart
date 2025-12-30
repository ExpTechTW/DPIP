import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16 + context.padding.bottom,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildThemeModeCard(context, model),
            _buildThemeColorCard(context, model),
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

  Widget _buildThemeModeCard(
    BuildContext context,
    SettingsUserInterfaceModel model,
  ) {
    final modeIcon = switch (model.themeMode) {
      ThemeMode.light => Symbols.light_mode_rounded,
      ThemeMode.dark => Symbols.dark_mode_rounded,
      ThemeMode.system => Symbols.contrast_rounded,
    };
    final modeColor = switch (model.themeMode) {
      ThemeMode.light => Colors.orange,
      ThemeMode.dark => Colors.indigo,
      ThemeMode.system => context.colors.primary,
    };
    final modeName = switch (model.themeMode) {
      ThemeMode.light => '淺色'.i18n,
      ThemeMode.dark => '深色'.i18n,
      ThemeMode.system => '跟隨系統主題'.i18n,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => SettingsThemeSelectRoute().push(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(modeIcon, color: modeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主題模式'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modeName,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeColorCard(
    BuildContext context,
    SettingsUserInterfaceModel model,
  ) {
    final currentColor = model.themeColor ?? context.colors.primary;
    final colorName = model.themeColor != null
        ? ColorTools.nameThatColor(model.themeColor!)
        : '系統色彩'.i18n;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showColorPicker(context, model),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentColor,
                        HSLColor.fromColor(currentColor)
                            .withLightness(
                              (HSLColor.fromColor(currentColor).lightness + 0.2)
                                  .clamp(0.0, 1.0),
                            )
                            .toColor(),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.colorize_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主題色'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        colorName,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ColorIndicator(color: currentColor, width: 32, height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPicker(
    BuildContext context,
    SettingsUserInterfaceModel model,
  ) async {
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
                  copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                    copyFormat: ColorPickerCopyFormat.numHexRRGGBB,
                    snackBarParseError: true,
                    longPressMenu: true,
                  ),
                  actionButtons: const ColorPickerActionButtons(
                    dialogActionButtons: false,
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                        Navigator.of(context).pop(model.themeColor);
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
  }
}
