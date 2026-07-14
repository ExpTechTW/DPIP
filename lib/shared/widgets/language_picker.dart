/// A compact language selector — an icon that opens a menu of supported
/// languages, driving the app-wide [LocaleController].
library;

import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = context.watch<LocaleController>().locale?.languageCode;
    return PopupMenuButton<String?>(
      icon: const Icon(Icons.language),
      tooltip: l10n.language,
      initialValue: current,
      onSelected: (code) => context.read<LocaleController>().setLocale(
        code == null ? null : Locale(code),
      ),
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String?>(
          value: null,
          checked: current == null,
          child: Text(l10n.languageSystem),
        ),
        // Native language names (not translated) so each is recognisable.
        CheckedPopupMenuItem<String?>(
          value: 'zh',
          checked: current == 'zh',
          child: const Text('中文'),
        ),
        CheckedPopupMenuItem<String?>(
          value: 'en',
          checked: current == 'en',
          child: const Text('English'),
        ),
      ],
    );
  }
}
