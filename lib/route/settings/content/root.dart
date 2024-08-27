import "package:dpip/global.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

typedef DevUpdateCallback = void Function();

class SettingsRootView extends StatefulWidget {
  final Function()? onDevUpdate;
  const SettingsRootView({super.key, this.onDevUpdate});

  @override
  State<SettingsRootView> createState() => _SettingsRootViewState();

  static DevUpdateCallback? _activeCallback;

  static void setActiveCallback(DevUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updateDev() {
    _activeCallback?.call();
  }
}

class _SettingsRootViewState extends State<SettingsRootView> {
  bool devEnabled = Global.preference.getBool("dev") ?? false;

  @override
  void initState() {
    super.initState();
    SettingsRootView.setActiveCallback(sendDevUpdate);
  }

  @override
  void dispose() {
    SettingsRootView.clearActiveCallback();
    super.dispose();
  }

  void sendDevUpdate() {
    devEnabled = Global.preference.getBool("dev") ?? false;
    setState(() {});
    widget.onDevUpdate?.call();
}

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
          ListTileGroupHeader(title: context.i18n.other_title),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.experiment),
            ),
            title: Text(
              context.i18n.advanced_features,
              style: tileTitleTextStyle,
            ),
            subtitle: Text(context.i18n.advanced_features_title),
            onTap: () {
              Navigator.pushNamed(
                context,
                "/experiment",
              );
            },
          ),
          if (devEnabled)
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Symbols.experiment),
              ),
              title: Text(
                context.i18n.login_exptech,
                style: tileTitleTextStyle,
              ),
              subtitle: Text(context.i18n.login_exptech_title),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/login",
                );
              },
            ),
        ],
      ),
    );
  }
}
