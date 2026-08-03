import 'package:dpip/core/settings/locale_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = <Locale>[
    Locale('zh', 'TW'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'HK',
    ),
    Locale('ja'),
  ];

  test('null / empty → Taiwan', () {
    expect(resolveAppLocale(null, supported), kHomeLocale);
    expect(resolveAppLocale([], supported), kHomeLocale);
  });

  test('zh_TW exact', () {
    expect(
      resolveAppLocale(const [Locale('zh', 'TW')], supported),
      const Locale('zh', 'TW'),
    );
  });

  test('bare zh / zh_Hant → Taiwan (not Simplified Material zh)', () {
    expect(resolveAppLocale(const [Locale('zh')], supported), kHomeLocale);
    expect(
      resolveAppLocale(const [
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ], supported),
      kHomeLocale,
    );
  });

  test('zh_Hans / CN → Simplified', () {
    expect(
      resolveAppLocale(const [
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ], supported),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
    expect(
      resolveAppLocale(const [Locale('zh', 'CN')], supported),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
  });

  test('zh_HK → Hong Kong', () {
    expect(
      resolveAppLocale(const [Locale('zh', 'HK')], supported),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      ),
    );
  });

  test('unrelated language falls back to Taiwan', () {
    expect(resolveAppLocale(const [Locale('de')], supported), kHomeLocale);
  });
}
