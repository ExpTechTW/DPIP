import "package:dpip/global.dart";
import "package:dpip/models/settings/ui.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/widgets/settings/theme/theme_radio_tile.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class SettingsThemeView extends StatefulWidget {
  const SettingsThemeView({super.key});

  @override
  State<SettingsThemeView> createState() => _SettingsThemeViewState();
}

class _SettingsThemeViewState extends State<SettingsThemeView> {
  String themeMode = Global.preference.getString("theme") ?? "system";

  final light = ThemeData(brightness: Brightness.light);
  final dark = ThemeData(brightness: Brightness.dark);
  late ThemeData system;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemTheme();
  }

  void _updateSystemTheme() {
    final brightness = MediaQuery.of(context).platformBrightness;
    system = ThemeData(brightness: brightness);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<SettingsUserInterfaceModel>(
              builder: (context, model, child) {
                return Column(
                  children: [
                    ThemeRadioTile(
                      value: ThemeMode.light,
                      groupValue: model.themeMode,
                      onTap: () => model.setThemeMode(ThemeMode.light),
                      title: context.i18n.theme_light,
                      theme: light,
                    ),
                    const SizedBox(height: 16),
                    ThemeRadioTile(
                      value: ThemeMode.dark,
                      groupValue: model.themeMode,
                      onTap: () => model.setThemeMode(ThemeMode.dark),
                      title: context.i18n.theme_dark,
                      theme: dark,
                    ),
                    const SizedBox(height: 16),
                    ThemeRadioTile(
                      value: ThemeMode.system,
                      groupValue: model.themeMode,
                      onTap: () => model.setThemeMode(ThemeMode.system),
                      title: context.i18n.theme_system,
                      theme: system,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
