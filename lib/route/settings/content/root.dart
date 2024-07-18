import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
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

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTileGroupHeader(title: "位置"),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.pin_drop),
            ),
            title: const Text(
              "所在地",
              style: tileTitleTextStyle,
            ),
            subtitle: const Text("調整所在地來接收即時天氣資訊、地震預估震度以及地震波預估抵達秒數等"),
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
                "/Audio",
              );
            },
          ),
          const ListTileGroupHeader(title: "個人化"),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.format_paint),
            ),
            title: const Text(
              "主題色",
              style: tileTitleTextStyle,
            ),
            subtitle: const Text("調整 DPIP 整體的外觀與顏色"),
            onTap: () {
              Navigator.pushNamed(
                context,
                "/theme",
              );
            },
          ),
          const ListTileGroupHeader(title: "複製 FCM Token"),
          ListTile(
            leading: Icon(
              Platform.isAndroid
                ? Icons.bug_report_rounded
                : CupertinoIcons.square_on_square,
            ),
            title: const Text("複製 FCM Token"),
            onTap: () {
              messaging.getToken().then((value) {
                FlutterClipboard.copy(value ?? "");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已複製 FCM Token'),
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
