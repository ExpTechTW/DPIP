import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/utils/extensions/build_context.dart';

Future<void> showLocationDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        icon: const Icon(Symbols.error),
        title: const Text('尚未設定所在地'),
        content: const Text( 'DPIP 需要設定所在地才能正常運作。點擊「前往設定」設定所在地後再試一次。'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            child: const Text('前往設定'),
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings');
              context.push('/settings/location');
            },
          ),
        ],
      );
    },
  );
}
