/// The app's selected UI language (or the system default).
library;

import 'package:dpip/core/settings/preference_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen [Locale] override, persisted across launches.
///
/// `null` means "follow the system language" (the default) — `MaterialApp`
/// resolves it against the supported locales. Setting a locale forces that
/// language app-wide; the app root watches this and rebuilds `MaterialApp`.
///
/// Persisted as a `language_COUNTRY` tag (e.g. `zh_TW`, `zh_HK`, `ja`) so
/// region-specific variants (Traditional Chinese for Taiwan vs Hong Kong) are
/// distinguishable.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs);

  final SharedPreferences _prefs;

  /// The chosen locale, or null to follow the system.
  Locale? get locale {
    final tag = _prefs.getString(PreferenceKeys.locale);
    if (tag == null || tag.isEmpty) return null;
    final parts = tag.split('_');
    return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  /// Sets the locale override; null clears it (back to the system language).
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(PreferenceKeys.locale);
    } else {
      final country = locale.countryCode;
      final tag = country == null
          ? locale.languageCode
          : '${locale.languageCode}_$country';
      await _prefs.setString(PreferenceKeys.locale, tag);
    }
    notifyListeners();
  }
}
