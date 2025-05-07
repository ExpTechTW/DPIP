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
        title: Text(context.i18n.location_not_set),
        content: Text(context.i18n.location_setting_required),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            child: Text(context.i18n.go_to_settings),
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
