import 'package:dpip/api/exptech.dart';
import 'package:dpip/dialog/welcome/announcement.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/changelog/changelog.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class WelcomeChangelogDialog extends StatelessWidget {
  const WelcomeChangelogDialog({super.key});

  Future<void> _checkAnnouncement(BuildContext context) async {
    var data = await ExpTech().getAnnouncement();
    if (data.last.show && Global.preference.getString("announcement") != data.last.time.toString()) {
      Global.preference.setString("announcement", data.last.time.toString());
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => const WelcomeAnnouncementDialog(),
        );
      }
    }
  }

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
            _checkAnnouncement(context);
          },
        ),
        TextButton(
          child: Text(context.i18n.go_to_view),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangelogPage()),
            ).then((_) => _checkAnnouncement(context));
          },
        ),
      ],
    );
  }
}
