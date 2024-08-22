import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsRootView extends StatefulWidget {
  const SettingsRootView({super.key});

  @override
  State<SettingsRootView> createState() => _SettingsRootViewState();
}

class _SettingsRootViewState extends State<SettingsRootView> {
  @override
  Widget build(BuildContext context) {
    const tileTitleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
    );

    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          ListTileGroupHeader(title: context.i18n.settings_position),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.pin_drop),
            ),
            title: Text(
              context.i18n.settings_location,
              style: tileTitleTextStyle,
            ),
            subtitle: Text(context.i18n.settings_location_description),
            onTap: () {
              Navigator.pushNamed(
                context,
                "/location",
              );
            },
          ),
          ListTileGroupHeader(title: context.i18n.settings_Personalization),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.format_paint),
            ),
            title: Text(
              context.i18n.settings_theme,
              style: tileTitleTextStyle,
            ),
            subtitle: Text(context.i18n.settings_theme_description),
            onTap: () {
              Navigator.pushNamed(
                context,
                "/theme",
              );
            },
          ),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.translate),
            ),
            title: Text(
              context.i18n.settings_locale,
              style: tileTitleTextStyle,
            ),
            subtitle: Text(context.i18n.settings_locale_description),
            onTap: () {
              Navigator.pushNamed(
                context,
                "/locale",
              );
            },
          ),
        ],
      ),
    );
  }
}
