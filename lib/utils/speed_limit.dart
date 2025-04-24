import "package:dpip/utils/extensions/build_context.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

Future<void> showLimitDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        icon: const Icon(Symbols.error),
        title: Text(context.i18n.invalid_operation),
        content: Text(context.i18n.operation_interval_too_short),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            child: Text(context.i18n.got_it),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
