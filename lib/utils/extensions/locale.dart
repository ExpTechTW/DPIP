import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

extension NativeLocale on Locale {
  String get nativeName {
    switch (toLanguageTag()) {
      case 'zh-Hant':
        return '繁體中文';
      case 'zh-Hans':
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

  String? flagCodeFromLocale(Locale locale) {
    switch (locale.toLanguageTag()) {
      case 'zh-Hant':
        return 'tw';
      case 'zh-Hans':
      case 'zh':
        return 'cn';
      case 'en':
        return 'us';
      case 'ja':
        return 'jp';
      case 'ko':
        return 'kr';
      case 'vi':
        return 'vn';
      case 'ru':
        return 'ru';
      default:
        return null;
    }
  }

  Widget get flag {
    final code = flagCodeFromLocale(this);
    if (code == null) return const SizedBox.shrink();

    return SvgPicture.asset('assets/flags/$code.svg', height: 24);
  }
}
