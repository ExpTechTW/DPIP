import 'package:flutter/material.dart';

import 'package:dash_flags/dash_flags.dart';

extension NativeLocale on Locale {
  String get nativeName {
    switch (toString()) {
      case 'zh_TW':
        return '繁體中文';
      case 'zh_CN':
        return '簡體中文';
      case 'zh':
        return '簡體中文';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'vi':
        return 'Tiếng Việt';
      case 'ru':
        return 'Русский';
      default:
        return toString();
    }
  }

  Widget get flag {
    if (countryCode == 'TW') {
      return CountryFlag(country: Country.tw, height: 24);
    }

    return LanguageFlag(language: Language.fromCode(languageCode), height: 24);
  }
}
