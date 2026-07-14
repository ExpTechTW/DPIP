import 'package:dpip/core/settings/persisted.dart';
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Fruit {
  apple('a'),
  banana('b');

  const _Fruit(this.code);
  final String code;
}

// Any String-typed registry key exercises the generic mechanism; `.name`
// (public) lets us seed the mock under its address. A test can't mint a
// PrefKey (private ctor), and which key is used is irrelevant to what's under
// test — so reuse a real one rather than add a test-only minting seam.
const _key = PreferenceKeys.weatherMode;

Future<Prefs> _prefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return Prefs(await SharedPreferences.getInstance());
}

void main() {
  test('falls back when nothing is stored', () async {
    final p = PersistedEnum(
      await _prefs(),
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.banana,
    );
    expect(p.value, _Fruit.banana);
  });

  test('reads a stored value via the encoder', () async {
    final p = PersistedEnum(
      await _prefs({_key.name: 'a'}),
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.banana,
      encode: (f) => f.code,
    );
    expect(p.value, _Fruit.apple);
  });

  test('set reports change, persists, and is idempotent', () async {
    final prefs = await _prefs();
    final p = PersistedEnum(
      prefs,
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.apple,
      encode: (f) => f.code,
    );

    expect(p.set(_Fruit.banana), isTrue);
    expect(p.value, _Fruit.banana);
    expect(prefs.getString(_key), 'b');

    expect(p.set(_Fruit.banana), isFalse);
  });

  test('defaults to the enum name when no encoder is given', () async {
    final prefs = await _prefs();
    PersistedEnum(
      prefs,
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.apple,
    ).set(_Fruit.banana);
    expect(prefs.getString(_key), 'banana');
  });
}
