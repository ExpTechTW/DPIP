/// The app's locale configuration — its home locale and supported set.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

/// The app's home locale: Traditional Chinese for Taiwan (`zh_TW`).
///
/// Must be `zh_TW` (not bare `zh`) so Flutter **Material / Cupertino** widgets
/// (date pickers, dialogs, …) load Traditional Chinese strings. Bare `zh` is
/// treated as Simplified by the framework — that is why the filter date picker
/// used to show 简体 under 「繁體中文(臺灣)」.
///
/// `app_zh.arb` still exists as the gen-l10n **base** fallback for `zh_*`
/// variants, but [appSupportedLocales] deliberately omits bare `zh` so it never
/// becomes the app/Material locale.
///
/// Used as the ultimate fallback when the device language matches nothing else
/// supported — DPIP is a Taiwan-first disaster app.
const Locale kHomeLocale = Locale('zh', 'TW');

/// Every locale offered in the language picker / [MaterialApp], with
/// [kHomeLocale] first. Bare `zh` from codegen is filtered out (see above).
List<Locale> get appSupportedLocales => [
  kHomeLocale,
  ...AppLocalizations.supportedLocales.where(
    (l) => l != kHomeLocale && !_isBareChinese(l),
  ),
];

/// The app's localization delegates, with a widgets-layer fallback for
/// locales [flutter_localizations] does not ship (yue): Cantonese strings
/// come from our own ARB, but Material/Cupertino built-in widget strings
/// (date pickers, dialogs, …) fall back to Traditional Chinese — the closest
/// written form the framework ships — instead of asserting.
///
/// [flutter_localizations] has no `yue`; a `MaterialApp` whose supported
/// locales include it crashes at startup with "a Cupertino/Material delegate
/// that supports the yue locale was not found". These fallback delegates
/// pre-empt the framework's own `Global*` ones for exactly those locales.
List<LocalizationsDelegate<dynamic>> get appLocalizationsDelegates => [
  ...AppLocalizations.localizationsDelegates,
  const _WidgetsFallbackDelegate<MaterialLocalizations>(
    loadWith: _loadMaterial,
    unsupported: [Locale('yue')],
    replacement: kHomeLocale,
  ),
  const _WidgetsFallbackDelegate<CupertinoLocalizations>(
    loadWith: _loadCupertino,
    unsupported: [Locale('yue')],
    replacement: kHomeLocale,
  ),
];

Future<MaterialLocalizations> _loadMaterial(Locale locale) =>
    GlobalMaterialLocalizations.delegate.load(locale);

Future<CupertinoLocalizations> _loadCupertino(Locale locale) =>
    GlobalCupertinoLocalizations.delegate.load(locale);

/// Forwards a widgets delegate for locales it cannot serve to a
/// [replacement], and passes every other locale through to the underlying
/// `Global*` delegate untouched.
///
/// A delegate that answers "not supported" gets skipped entirely by
/// [Localizations], so the fallback has to pre-empt the framework's own
/// `Global*` delegates: it claims support for exactly [unsupported] and
/// serves [replacement] in their place.
class _WidgetsFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _WidgetsFallbackDelegate({
    required this.loadWith,
    required this.unsupported,
    required this.replacement,
  });

  final Future<T> Function(Locale locale) loadWith;
  final List<Locale> unsupported;
  final Locale replacement;

  @override
  bool isSupported(Locale locale) => unsupported.contains(locale);

  @override
  Future<T> load(Locale locale) => loadWith(replacement);

  @override
  bool shouldReload(_WidgetsFallbackDelegate<T> old) =>
      old.unsupported != unsupported || old.replacement != replacement;

  @override
  String toString() => 'WidgetsFallbackDelegate($unsupported → $replacement)';
}

bool _isBareChinese(Locale locale) =>
    locale.languageCode == 'zh' &&
    locale.scriptCode == null &&
    locale.countryCode == null;

/// A `DateFormat`-safe locale tag for [locale].
///
/// `intl` ships its own locale-data set, entirely separate from
/// `flutter_localizations` — it does not know every locale this app
/// supports either (`yue` included, the same gap the widgets-fallback
/// delegates above patch for Material/Cupertino). Asking `DateFormat` to
/// format with a tag it has no data for throws ("Invalid locale") rather than
/// falling back, so every `DateFormat` call driven by the app's locale must
/// go through this first. Falls back to [kHomeLocale], the same replacement
/// the Material/Cupertino delegates use.
String intlDateLocale(Locale locale) {
  final tag = locale.toString();
  return DateFormat.localeExists(tag) ? tag : kHomeLocale.toString();
}

/// Picks the best supported locale for [deviceLocales].
///
/// Chinese needs an explicit script/region split: bare `zh` and `zh_Hant` map
/// to Taiwan Traditional ([kHomeLocale]); `zh_Hans` / `CN` / `SG` → Simplified;
/// `HK` / `MO` → Hong Kong Traditional. Other languages use language-code match
/// then fall back to [kHomeLocale].
Locale resolveAppLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  final supportedList = supported.toList(growable: false);
  if (deviceLocales == null || deviceLocales.isEmpty) return kHomeLocale;

  for (final device in deviceLocales) {
    for (final s in supportedList) {
      if (s == device) return s;
    }
  }

  for (final device in deviceLocales) {
    if (device.languageCode != 'zh') continue;
    if (_isSimplifiedChinese(device)) {
      return supportedList.firstWhere(
        (l) => l.languageCode == 'zh' && l.scriptCode == 'Hans',
        orElse: () => kHomeLocale,
      );
    }
    if (device.countryCode == 'HK' || device.countryCode == 'MO') {
      return supportedList.firstWhere(
        (l) => l.languageCode == 'zh' && l.countryCode == 'HK',
        orElse: () => kHomeLocale,
      );
    }
    // zh / zh_TW / zh_Hant / zh_Hant_TW → Taiwan Traditional.
    return kHomeLocale;
  }

  for (final device in deviceLocales) {
    for (final s in supportedList) {
      if (s.languageCode == device.languageCode) return s;
    }
  }
  return kHomeLocale;
}

bool _isSimplifiedChinese(Locale locale) =>
    locale.scriptCode == 'Hans' ||
    locale.countryCode == 'CN' ||
    locale.countryCode == 'SG';
