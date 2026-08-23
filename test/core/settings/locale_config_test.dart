import 'package:dpip/core/settings/locale_config.dart';
import 'package:flutter/material.dart';
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
    Locale('yue'),
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

  test('yue maps to itself', () {
    expect(
      resolveAppLocale(const [Locale('yue')], supported),
      const Locale('yue'),
    );
  });

  testWidgets(
    'intlDateLocale falls back to Taiwan for a locale intl has no data for',
    (tester) async {
      // DateFormat.localeExists needs intl's date-symbol data loaded first
      // (LocaleDataException otherwise) — pumping a MaterialApp is what does
      // that in the real app too, via GlobalMaterialLocalizations' delegate
      // load, so this exercises the same path the changelog page runs
      // through rather than calling intl cold.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: supported,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();
      // intl ships its own locale-data set, separate from flutter_localizations
      // — it has no `yue` either, and asking DateFormat to format with a tag it
      // cannot verify throws "Invalid locale" rather than falling back (the
      // changelog crash this guards against).
      expect(intlDateLocale(const Locale('yue')), kHomeLocale.toString());
      expect(intlDateLocale(const Locale('ja')), 'ja');
    },
  );

  testWidgets('app delegates serve Cantonese without crashing', (tester) async {
    // flutter_localizations ships no yue; the fallback delegates must serve
    // zh_TW widgets strings so a yue MaterialApp builds instead of asserting
    // "a Cupertino/Material delegate that supports the yue locale was not
    // found" at startup.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('yue'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: supported,
        home: const Scaffold(body: Text('hi')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
  });
}
