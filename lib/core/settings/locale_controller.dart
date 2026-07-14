/// The app's selected UI language (or the system default).
library;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen [Locale] override, persisted across launches.
///
/// `null` means "follow the system language" (the default) — `MaterialApp`
/// resolves it against the supported locales. Setting a locale forces that
/// language app-wide; the app root watches this and rebuilds `MaterialApp`.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'app.localeLanguageCode';

  /// The chosen locale, or null to follow the system.
  Locale? get locale {
    final code = _prefs.getString(_key);
    return code == null ? null : Locale(code);
  }

  /// Sets the locale override; null clears it (back to the system language).
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
    notifyListeners();
  }
}
