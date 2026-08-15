/// The app's selected UI language (or the system default).
library;

import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/widgets.dart';

/// Holds the user's chosen [Locale] override, persisted across launches.
///
/// `null` means "follow the system language" (the default) — `MaterialApp`
/// resolves it against the supported locales. Setting a locale forces that
/// language app-wide; the app root watches this and rebuilds `MaterialApp`.
///
/// Persisted as a BCP-47 language tag (e.g. `zh-TW`, `zh-Hant-HK`, `zh-Hans`,
/// `ja`) so script- and region-specific variants — Traditional vs Simplified,
/// Taiwan vs Hong Kong — round-trip losslessly, not just the bare language code.
class LocaleController extends ChangeNotifier {
  LocaleController(this._settings);

  final SettingsStore _settings;

  /// The chosen locale, or null to follow the system.
  Locale? get locale {
    final tag = _settings.getString(SettingKeys.locale);
    if (tag == null || tag.isEmpty) return null;
    return _canonicalize(_parseTag(tag));
  }

  /// Sets the locale override; null clears it (back to the system language).
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _settings.remove(SettingKeys.locale);
    } else {
      final canonical = _canonicalize(locale);
      await _settings.setString(SettingKeys.locale, canonical.toLanguageTag());
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

  /// Legacy bare `zh` meant Taiwan Traditional — rewrite to `zh_TW` so Material
  /// widgets stay Traditional (bare `zh` → Simplified in Flutter).
  static Locale _canonicalize(Locale locale) {
    if (locale.languageCode == 'zh' &&
        locale.scriptCode == null &&
        locale.countryCode == null) {
      return const Locale('zh', 'TW');
    }
    return locale;
  }
}
