/// The card API answers any `{lang}` outside its twelve tags with a 404, so a
/// locale that maps to a near miss (`zh_Hans`, `zh-HK`, `en-US`) would blank
/// the events feed in that language rather than fall back to anything.
library;

import 'dart:ui' show Locale;

import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/events/data/event_language.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the accepted tags are exactly the twelve the server lists', () {
    expect(eventApiLanguageTags, [
      'zh-TW',
      'zh',
      'zh-Hans',
      'zh-Hant-HK',
      'yue',
      'en',
      'ja',
      'ko',
      'vi',
      'th',
      'id',
      'fil',
    ]);
  });

  test('every locale the app ships maps to its own tag', () {
    final expected = <Locale, String>{
      const Locale('en'): 'en',
      const Locale('fil'): 'fil',
      const Locale('id'): 'id',
      const Locale('ja'): 'ja',
      const Locale('ko'): 'ko',
      const Locale('th'): 'th',
      const Locale('vi'): 'vi',
      const Locale('yue'): 'yue',
      // Bare zh is the original text under another name; the server answers
      // it in zh-TW, so the app asks for zh-TW.
      const Locale('zh'): 'zh-TW',
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'):
          'zh-Hans',
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      ): 'zh-Hant-HK',
      const Locale('zh', 'TW'): 'zh-TW',
    };

    // One ARB per locale, twelve of them; a new ARB fails here until it is
    // given a tag.
    expect(AppLocalizations.supportedLocales, hasLength(12));
    expect(AppLocalizations.supportedLocales.toSet(), expected.keys.toSet());
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = eventApiLanguage(locale);
      expect(tag, expected[locale], reason: '$locale');
      expect(eventApiLanguageTags, contains(tag), reason: '$locale');
    }
  });

  test('every locale the UI can be in maps to an accepted tag', () {
    for (final locale in [kHomeLocale, ...appSupportedLocales]) {
      expect(
        eventApiLanguageTags,
        contains(eventApiLanguage(locale)),
        reason: '$locale',
      );
    }
    expect(eventApiLanguage(kHomeLocale), 'zh-TW');
  });

  test('underscore and case variants resolve to the exact tag', () {
    expect(eventApiLanguage(const Locale('zh_Hans')), 'zh-Hans');
    expect(eventApiLanguage(const Locale('zh_Hant_HK')), 'zh-Hant-HK');
    expect(eventApiLanguage(const Locale('zh_TW')), 'zh-TW');
    expect(
      eventApiLanguage(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'hans'),
      ),
      'zh-Hans',
    );
  });

  test('Chinese splits by script and region like the UI does', () {
    String map(String language, {String? script, String? country}) =>
        eventApiLanguage(
          Locale.fromSubtags(
            languageCode: language,
            scriptCode: script,
            countryCode: country,
          ),
        );

    expect(map('zh', country: 'CN'), 'zh-Hans');
    expect(map('zh', country: 'SG'), 'zh-Hans');
    expect(map('zh', script: 'Hans', country: 'CN'), 'zh-Hans');
    expect(map('zh', script: 'Hans', country: 'HK'), 'zh-Hans');
    expect(map('zh', country: 'HK'), 'zh-Hant-HK');
    expect(map('zh', country: 'MO'), 'zh-Hant-HK');
    expect(map('zh', script: 'Hant', country: 'MO'), 'zh-Hant-HK');
    expect(map('zh', script: 'Hant'), 'zh-TW');
    expect(map('zh', script: 'Hant', country: 'TW'), 'zh-TW');
  });

  test('other languages fall back to their language code', () {
    expect(eventApiLanguage(const Locale('en', 'US')), 'en');
    expect(eventApiLanguage(const Locale('ja', 'JP')), 'ja');
    expect(eventApiLanguage(const Locale('ko', 'KR')), 'ko');
    expect(eventApiLanguage(const Locale('fil', 'PH')), 'fil');
    expect(eventApiLanguage(const Locale('yue', 'HK')), 'yue');
  });

  test('an unknown locale gets the original text, zh-TW', () {
    expect(eventApiLanguage(const Locale('fr')), 'zh-TW');
    expect(eventApiLanguage(const Locale('de', 'DE')), 'zh-TW');
    expect(eventApiLanguage(const Locale('und')), 'zh-TW');
    expect(eventApiLanguageTags, contains(eventApiFallbackLanguage));
  });
}
