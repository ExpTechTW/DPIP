/// A compact language selector — an icon that opens a menu of supported
/// languages, driving the app-wide [LocaleController].
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, this.label});

  /// Optional text shown to the left of the globe (e.g. "語言設定" on welcome).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = context.watch<LocaleController>().locale?.languageCode;
    final trigger = label == null
        ? const Icon(Icons.language)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label!, style: theme.textTheme.labelLarge),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.language),
            ],
          );
    return PopupMenuButton<String?>(
      tooltip: l10n.language,
      initialValue: current,
      onSelected: (code) => context.read<LocaleController>().setLocale(
        code == null ? null : Locale(code),
      ),
      position: PopupMenuPosition.under,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: trigger,
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
