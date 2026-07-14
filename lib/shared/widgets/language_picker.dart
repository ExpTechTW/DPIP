/// A compact language selector — an icon that opens a menu of supported
/// languages, driving the app-wide [LocaleController].
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/language_options.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, this.label});

  /// Optional text shown to the left of the globe (e.g. "語言設定" on welcome).
  final String? label;

  /// Menu sentinel for the "follow system" entry. `PopupMenuButton` reports a
  /// dismissal as a `null` result and swallows it, so a `null`-valued item can
  /// never be selected — we use the BCP-47 "undetermined" tag as a non-null
  /// marker and map it back to `null` (clear the override) on selection.
  static const Locale _systemLocale = Locale('und');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = context.watch<LocaleController>().locale;
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
    return FutureBuilder<List<LanguageOption>>(
      future: loadLanguageOptions(),
      builder: (context, snapshot) {
        final options = snapshot.data ?? const [];
        return PopupMenuButton<Locale>(
          tooltip: l10n.language,
          initialValue: current ?? _systemLocale,
          enabled: options.isNotEmpty,
          onSelected: (locale) => context.read<LocaleController>().setLocale(
            locale == _systemLocale ? null : locale,
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
            CheckedPopupMenuItem<Locale>(
              value: _systemLocale,
              checked: current == null,
              child: Text(l10n.languageSystem),
            ),
            for (final option in options)
              CheckedPopupMenuItem<Locale>(
                value: option.locale,
                checked: current == option.locale,
                child: Text(option.name),
              ),
          ],
        );
      },
    );
  }
}
