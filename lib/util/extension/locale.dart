import 'dart:ui';

import 'package:flutter_localized_locales/flutter_localized_locales.dart';

extension NativeLocale on Locale {
  String get nativeName {
    if (languageCode == "zh" && countryCode == "TW") {
      return "繁體中文";
    } else if (languageCode == "zh") {
      return "簡體中文";
    }

    return LocaleNamesLocalizationsDelegate.nativeLocaleNames[toString()] ?? "";
  }
}
