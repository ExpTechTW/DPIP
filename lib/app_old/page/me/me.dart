import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/widgets/list/tile_group_header.dart';

import 'package:dpip/app_old/page/me/developer.dart';

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
        const ListTileGroupHeader(title: '關於'),
        ListTile(
          leading: const Icon(Symbols.forum_rounded),
          title: const Text('開發者想說的話'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DPIPInfoPage()));
          },
        ),

        /**
         * 打開歡迎頁面
         */
        ListTile(
          leading: const Icon(Icons.visibility),
          title: const Text('歡迎頁面'),
          onTap: () => context.push('/welcome'),
        ),
      ],
    );
  }
}
