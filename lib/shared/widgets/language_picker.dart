/// A compact language selector — an icon that opens a menu of supported
/// languages, driving the app-wide [LocaleController].
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One offered language: its [locale] and its own native name (taken from that
/// locale's ARB `languageName` — never hardcoded here).
typedef _LanguageOption = ({Locale locale, String name});

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, this.label});

  /// Optional text shown to the left of the globe (e.g. "語言設定" on welcome).
  final String? label;

  /// Loads each supported locale's own name from its ARB. Cached for the
  /// process — the supported set is fixed at build time. `delegate.load` is
  /// synchronous under the hood (gen-l10n), so the picker paints immediately.
  static Future<List<_LanguageOption>>? _optionsCache;
  static Future<List<_LanguageOption>> _options() =>
      _optionsCache ??= _loadOptions();

  static Future<List<_LanguageOption>> _loadOptions() async {
    final options = <_LanguageOption>[];
    for (final locale in appSupportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      options.add((locale: locale, name: l10n.languageName));
    }
    return options;
  }

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
    return FutureBuilder<List<_LanguageOption>>(
      future: _options(),
      builder: (context, snapshot) {
        final options = snapshot.data ?? const [];
        return PopupMenuButton<Locale?>(
          tooltip: l10n.language,
          initialValue: current,
          enabled: options.isNotEmpty,
          onSelected: (locale) =>
              context.read<LocaleController>().setLocale(locale),
          position: PopupMenuPosition.under,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: trigger,
          ),
          itemBuilder: (context) => [
            CheckedPopupMenuItem<Locale?>(
              value: null,
              checked: current == null,
              child: Text(l10n.languageSystem),
            ),
            for (final option in options)
              CheckedPopupMenuItem<Locale?>(
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
