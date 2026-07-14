/// The app's selected UI language (or the system default).
library;

import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter/widgets.dart';

/// Holds the user's chosen [Locale] override, persisted across launches.
///
/// `null` means "follow the system language" (the default) — `MaterialApp`
/// resolves it against the supported locales. Setting a locale forces that
/// language app-wide; the app root watches this and rebuilds `MaterialApp`.
///
/// Persisted as a BCP-47 language tag (e.g. `zh-Hant-HK`, `zh-Hans`, `ja`) so
/// script- and region-specific variants — Traditional vs Simplified, Taiwan vs
/// Hong Kong — round-trip losslessly, not just the bare language code.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs);

  final Prefs _prefs;

  /// The chosen locale, or null to follow the system.
  Locale? get locale {
    final tag = _prefs.getString(PreferenceKeys.locale);
    if (tag == null || tag.isEmpty) return null;
    return _parseTag(tag);
  }

  /// Sets the locale override; null clears it (back to the system language).
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(PreferenceKeys.locale);
    } else {
      await _prefs.setString(PreferenceKeys.locale, locale.toLanguageTag());
    }
    notifyListeners();
  }

  /// Parses a BCP-47 tag (`zh-Hant-HK`) back into a [Locale], recognising the
  /// 4-letter script subtag so it survives the round-trip. Also tolerates the
  /// legacy `_` separator from earlier builds.
  static Locale _parseTag(String tag) {
    final parts = tag.split(RegExp('[-_]'));
    String? script;
    String? country;
    for (final part in parts.skip(1)) {
      if (part.length == 4) {
        script = part; // script subtags are 4 letters (Hant, Hans)
      } else {
        country = part.toUpperCase();
      }
    }
    return Locale.fromSubtags(
      languageCode: parts.first,
      scriptCode: script,
      countryCode: country,
    );
  }
}
