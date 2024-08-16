import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:dpip/core/notify.dart';
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
          const ListTileGroupHeader(title: "音效"),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.audiotrack_sharp),
            ),
            title: const Text(
              "音效測試",
              style: tileTitleTextStyle,
            ),
            subtitle: const Text("測試即時天氣資訊、地震速報等音效"),
            onTap: () {
              Navigator.pushNamed(
                context,
                "/sound",
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
          ListTileGroupHeader(title: context.i18n.settings_FCM),
          ListTile(
            leading: Icon(
              Platform.isAndroid ? Icons.bug_report_rounded : CupertinoIcons.square_on_square,
            ),
            title: Text(context.i18n.settings_FCM),
            onTap: () {
              messaging.getToken().then((value) {
                FlutterClipboard.copy(value ?? "");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.i18n.settings_copyFCM),
                  ),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('複製 FCM Token 時發生錯誤：$error'),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
