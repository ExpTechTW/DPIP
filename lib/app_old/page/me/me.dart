import "package:flutter/material.dart";

import "package:go_router/go_router.dart";
import "package:material_symbols_icons/symbols.dart";


import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/widgets/list/tile_group_header.dart";

import "developer.dart";

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTileGroupHeader(title: context.i18n.me_general),
        /**
         * 設定
         */
        ListTile(
          leading: const Icon(Symbols.tune),
          title: Text(context.i18n.settings),
          subtitle: Text(context.i18n.settingsDescription),
          onTap: () => context.push("/settings"),
        ),
        ListTileGroupHeader(title: context.i18n.me_about),
        ListTile(
          leading: const Icon(Symbols.forum_rounded),
          title: Text(context.i18n.me_developer),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DPIPInfoPage()));
          },
        ),

        /**
         * 打開歡迎頁面
         */
        ListTile(
          leading: const Icon(Icons.visibility),
          title: Text(context.i18n.me_welcome),
          onTap: () => context.push('/welcome'),
        ),
      ],
    );
  }
}
