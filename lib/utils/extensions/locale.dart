import "package:dash_flags/dash_flags.dart";
import "package:flutter/material.dart";
import "package:flutter_localized_locales/flutter_localized_locales.dart";

extension NativeLocale on Locale {
  String get nativeName {
    if (languageCode == "zh" && countryCode == "TW") {
      return "繁體中文";
    } else if (languageCode == "zh") {
      return "簡體中文";
    }

    return LocaleNamesLocalizationsDelegate.nativeLocaleNames[toString()] ?? "";
  }

  Widget get flag {
    if (countryCode == 'TW') {
      return CountryFlag(country: Country.tw, height: 24);
    }

    return LanguageFlag(language: Language.fromCode(languageCode), height: 24);
  }
}
