/// Verifies the locale override persists losslessly — including script and
/// region subtags (Traditional vs Simplified, Taiwan vs Hong Kong).
library;

import 'package:dpip/core/settings/locale_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocaleController> controller([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return LocaleController(Prefs(await SharedPreferences.getInstance()));
  }

  test('defaults to null (follow system) when nothing is stored', () async {
    expect((await controller()).locale, isNull);
  });

  test('round-trips a bare language locale', () async {
    final c = await controller();
    await c.setLocale(const Locale('ja'));
    expect(c.locale, const Locale('ja'));
  });

  test('round-trips a script subtag (Simplified Chinese)', () async {
    final c = await controller();
    const simplified = Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
    );
    await c.setLocale(simplified);
    expect(c.locale, simplified);
  });

  test('round-trips script + region (Hong Kong Traditional)', () async {
    final c = await controller();
    const hongKong = Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'HK',
    );
    await c.setLocale(hongKong);
    expect(c.locale, hongKong);
  });

  test('setting null clears the override', () async {
    final c = await controller();
    await c.setLocale(const Locale('en'));
    await c.setLocale(null);
    expect(c.locale, isNull);
  });

  test('parses a legacy underscore-separated tag', () async {
    // Earlier builds may have persisted "zh_Hant_HK" with underscores.
    final c = await controller({'app.locale': 'zh_Hant_HK'});
    expect(
      c.locale,
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      ),
    );
  });
}
