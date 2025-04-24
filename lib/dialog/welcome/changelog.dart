import 'package:dpip/route/changelog/changelog.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class WelcomeChangelogDialog extends StatelessWidget {
  const WelcomeChangelogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Symbols.update_rounded),
      title: Text(context.i18n.update_complete),
      content: Text(context.i18n.update_complete_prompt),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          child: Text(context.i18n.remind_later),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(context.i18n.go_to_view),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangelogPage()));
          },
        ),
      ],
    );
  }
}
