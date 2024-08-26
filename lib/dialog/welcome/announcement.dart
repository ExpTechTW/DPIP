import 'package:dpip/route/announcement/announcement.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class WelcomeAnnouncementDialog extends StatelessWidget {
  const WelcomeAnnouncementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Symbols.announcement),
      title: Text(context.i18n.announcement),
      content: Text(context.i18n.new_announcement_prompt),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnnouncementPage()),
            );
          },
        ),
      ],
    );
  }
}
