/// The list of offered UI languages, each with its own native name.
library;

import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// One offered language: its [locale] and its own native name (taken from that
/// locale's ARB `languageName` — never hardcoded, so a new ARB self-describes).
typedef LanguageOption = ({Locale locale, String name});

/// Cached for the process — the supported set is fixed at build time.
Future<List<LanguageOption>>? _cache;

/// Loads each supported locale's own display name from its ARB. Shared by the
/// compact [language picker] and the full language settings page so both offer
/// exactly the same set, derived (never hardcoded).
Future<List<LanguageOption>> loadLanguageOptions() => _cache ??= _load();

Future<List<LanguageOption>> _load() async {
  final options = <LanguageOption>[];
  for (final locale in appSupportedLocales) {
    final l10n = await AppLocalizations.delegate.load(locale);
    options.add((locale: locale, name: l10n.languageName));
  }
  return options;
}
