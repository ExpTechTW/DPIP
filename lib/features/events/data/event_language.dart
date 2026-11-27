/// The `{lang}` path segment of the DPIP card API (v2), derived from the
/// app's locale.
library;

import 'dart:ui' show Locale;

/// Every `{lang}` value the card API accepts, exactly as it must be written.
///
/// The server compares the segment byte for byte, case included, and answers
/// anything else (`zh_Hans`, `zh-hans`, `zh-HK`, `en-US`) with a 404 — there
/// are no aliases on its side, so every alias is resolved here.
///
/// `zh` and `zh-TW` both serve the original Taiwan Traditional text; the app
/// sends `zh-TW`, never bare `zh`.
const List<String> eventApiLanguageTags = [
  'zh-TW',
  'zh',
  'zh-Hans',
  'zh-Hant-HK',
  'yue',
  'en',
  'ja',
  'ko',
  'vi',
  'th',
  'id',
  'fil',
];

/// The tag sent when [eventApiLanguage] finds no match: the original text.
const String eventApiFallbackLanguage = 'zh-TW';

/// [eventApiLanguageTags] keyed by their lower-case form, for the
/// case-insensitive first pass of [eventApiLanguage].
final Map<String, String> _byLowerTag = {
  for (final tag in eventApiLanguageTags) tag.toLowerCase(): tag,
};

/// Maps [locale] to one of [eventApiLanguageTags]; [eventApiFallbackLanguage]
/// when nothing matches.
///
/// In order:
///  1. `locale.toLanguageTag()`, with any `_` read as `-` and compared without
///     case, against the accepted tags — every locale the app ships
///     (`AppLocalizations.supportedLocales`) matches here.
///  2. Chinese by script and region, the same split `resolveAppLocale` makes
///     for the UI: `Hans`, `CN` or `SG` → `zh-Hans`; `HK` or `MO` →
///     `zh-Hant-HK`; any other Chinese (`zh`, `zh-Hant`, `zh-Hant-TW`) →
///     `zh-TW`.
///  3. The bare language code (`en-US` → `en`, `ja-JP` → `ja`).
String eventApiLanguage(Locale locale) {
  final tag = locale.toLanguageTag().replaceAll('_', '-').toLowerCase();
  final exact = _byLowerTag[tag];
  if (exact != null) return exact;

  final subtags = tag.split('-');
  final language = subtags.first;
  if (language == 'zh') {
    final rest = subtags.skip(1).toSet();
    if (rest.contains('hans') || rest.contains('cn') || rest.contains('sg')) {
      return 'zh-Hans';
    }
    if (rest.contains('hk') || rest.contains('mo')) return 'zh-Hant-HK';
    return 'zh-TW';
  }

  return _byLowerTag[language] ?? eventApiFallbackLanguage;
}
