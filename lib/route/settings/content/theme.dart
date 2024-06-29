import 'package:dpip/global.dart';
import 'package:dpip/main.dart';
import 'package:dpip/widget/settings/theme/theme_radio_tile.dart';
import 'package:flutter/material.dart';

class SettingsThemeView extends StatefulWidget {
  const SettingsThemeView({super.key});

  @override
  State<SettingsThemeView> createState() => _SettingsThemeViewState();
}

class _SettingsThemeViewState extends State<SettingsThemeView> {
  String themeMode = Global.preference.getString("theme") ?? "system";

  final light = ThemeData(brightness: Brightness.light);
  final dark = ThemeData(brightness: Brightness.dark);
  final system = ThemeData();

  setTheme(String theme) async {
    DpipApp.of(context)!.changeTheme(theme);
    await Global.preference.setString("theme", theme);
    setState(() {
      themeMode = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ThemeRadioTile(
                  value: "light",
                  groupValue: themeMode,
                  onTap: () => setTheme("light"),
                  title: "淺色",
                  theme: light,
                ),
                ThemeRadioTile(
                  value: "dark",
                  groupValue: themeMode,
                  onTap: () => setTheme("dark"),
                  title: "深色",
                  theme: dark,
                ),
                ThemeRadioTile(
                  value: "system",
                  groupValue: themeMode,
                  onTap: () => setTheme("system"),
                  title: "跟隨系統主題",
                  theme: system,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
