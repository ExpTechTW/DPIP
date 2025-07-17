import 'package:flutter/material.dart';

extension NativeLocale on Locale {
  String get nativeName {
    switch (toLanguageTag()) {
      case 'zh-Hant':
        return '繁體中文';
      case 'zh-Hans':
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

  String get iconLabel {
    switch (toLanguageTag()) {
      case 'zh-Hant':
        return '繁';
      case 'zh-Hans':
        return '简';
      case 'en':
        return 'EN';
      case 'ja':
        return 'あ';
      case 'ko':
        return '한';
      case 'vi':
        return 'VI';
      case 'ru':
        return 'РУ';
      default:
        return toString().substring(0, 2);
    }
  }
}
