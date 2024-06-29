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
      body: ListView(
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
          )
        ],
      ),
    );
  }
}
