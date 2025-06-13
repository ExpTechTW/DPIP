import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class WelcomeChangelogDialog extends StatelessWidget {
  const WelcomeChangelogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Symbols.update_rounded),
      title: const Text('更新完成'),
      content: const Text('DPIP 更新完成，要前往查看更新日誌嗎？'),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          child: const Text('稍後再說'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: const Text('前往查看'),
          onPressed: () {
            Navigator.pop(context);
            context.push('/changelog');
          },
        ),
      ],
    );
  }
}
