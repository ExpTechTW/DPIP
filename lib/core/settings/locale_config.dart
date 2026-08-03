/// The app's locale configuration — its home locale and supported set.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

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

bool _isBareChinese(Locale locale) =>
    locale.languageCode == 'zh' &&
    locale.scriptCode == null &&
    locale.countryCode == null;

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
