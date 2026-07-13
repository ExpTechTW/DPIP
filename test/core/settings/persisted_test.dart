import 'package:dpip/core/settings/persisted.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Fruit {
  apple('a'),
  banana('b');

  const _Fruit(this.code);
  final String code;
}

Future<SharedPreferences> _prefs([Map<String, Object> initial = const {}]) {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

void main() {
  test('falls back when nothing is stored', () async {
    final p = PersistedEnum(
      await _prefs(),
      key: 'k',
      values: _Fruit.values,
      fallback: _Fruit.banana,
    );
    expect(p.value, _Fruit.banana);
  });

  test('reads a stored value via the encoder', () async {
    final p = PersistedEnum(
      await _prefs({'k': 'a'}), // encoded as .code
      key: 'k',
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
      key: 'k',
      values: _Fruit.values,
      fallback: _Fruit.apple,
      encode: (f) => f.code,
    );

    expect(p.set(_Fruit.banana), isTrue); // changed
    expect(p.value, _Fruit.banana);
    expect(prefs.getString('k'), 'b'); // persisted via encoder

    expect(p.set(_Fruit.banana), isFalse); // unchanged
  });

  test('defaults to the enum name when no encoder is given', () async {
    final prefs = await _prefs();
    PersistedEnum(
      prefs,
      key: 'k',
      values: _Fruit.values,
      fallback: _Fruit.apple,
    ).set(_Fruit.banana);
    expect(prefs.getString('k'), 'banana');
  });
}
