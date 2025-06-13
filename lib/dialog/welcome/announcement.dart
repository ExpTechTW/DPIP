import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class WelcomeAnnouncementDialog extends StatelessWidget {
  const WelcomeAnnouncementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Symbols.announcement),
      title: const Text('公告'),
      content: const Text('有新的公告，要前往查看嗎？'),
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
            context.push('/announcement');
          },
        ),
      ],
    );
  }
}
