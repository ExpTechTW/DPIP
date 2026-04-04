import 'package:flutter/material.dart';

/// Extension on [Locale] that provides convenient utilities for locale display and formatting.
///
/// This extension adds helpful getters to simplify displaying locale information in the user interface, including
/// native language names and compact icon labels for language selection.
extension NativeLocale on Locale {
  static const Map<String, String> _nativeNames = {
    'zh-Hant': '繁體中文',
    'zh-Hans': '簡體中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'vi': 'Tiếng Việt',
    'ru': 'Русский',
  };

  static const Map<String, String> _iconLabels = {
    'zh-Hant': '繁',
    'zh-Hans': '简',
    'en': 'EN',
    'ja': 'あ',
    'ko': '한',
    'vi': 'VI',
    'ru': 'РУ',
  };

  /// Returns the native name of this locale in its own language.
  ///
  /// Returns the language name written in the language itself (e.g., "繁體中文" for Traditional Chinese, "English" for
  /// English, "日本語" for Japanese). This is useful for displaying language options in language selection interfaces
  /// where users can recognize their preferred language.
  ///
  /// For unsupported locales, returns the string representation of the locale.
  ///
  /// Example:
  /// ```dart
  /// final locale = Locale('zh', 'TW');
  /// print(locale.nativeName); // "繁體中文"
  ///
  /// final englishLocale = Locale('en');
  /// print(englishLocale.nativeName); // "English"
  /// ```
  String get nativeName => _nativeNames[toLanguageTag()] ?? toString();

  /// Returns a compact label suitable for use in icons or compact UI elements.
  ///
  /// Returns a short, typically 1-2 character label representing the locale (e.g., "繁" for Traditional Chinese, "EN"
  /// for English, "あ" for Japanese). This is useful for displaying language indicators in compact spaces like icon
  /// buttons or badges.
  ///
  /// For unsupported locales, returns the first 2 characters of the locale's string representation.
  ///
  /// Example:
  /// ```dart
  /// final locale = Locale('zh', 'TW');
  /// print(locale.iconLabel); // "繁"
  ///
  /// final englishLocale = Locale('en');
  /// print(englishLocale.iconLabel); // "EN"
  /// ```
  String get iconLabel => _iconLabels[toLanguageTag()] ?? toString().substring(0, 2);
}
