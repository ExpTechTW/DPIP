import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/utils/extensions/build_context.dart';

Future<void> showLimitDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        icon: const Icon(Symbols.error),
        title: const Text('無效操作'),
        content: const Text('操作間隔過短，請稍後再嘗試。'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            child: const Text('知道了'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
