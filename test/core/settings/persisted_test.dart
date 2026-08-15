import 'package:dpip/core/settings/persisted.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Fruit {
  apple('a'),
  banana('b');

  const _Fruit(this.code);
  final String code;
}

// Any String-typed registry key exercises the generic mechanism; `.name`
// (public) lets us seed the mock under its address. A test can't mint a
// SettingKey (private ctor), and which key is used is irrelevant to what's under
// test — so reuse a real one rather than add a test-only minting seam.
const _key = SettingKeys.weatherMode;

Future<SettingsStore> _settings([
  Map<String, Object> initial = const {},
]) async {
  return SettingsStore.inMemory(initial);
}

void main() {
  test('falls back when nothing is stored', () async {
    final p = PersistedEnum(
      await _settings(),
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.banana,
    );
    expect(p.value, _Fruit.banana);
  });

  test('reads a stored value via the encoder', () async {
    final p = PersistedEnum(
      await _settings({_key.name: 'a'}),
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.banana,
      encode: (f) => f.code,
    );
    expect(p.value, _Fruit.apple);
  });

  test('set reports change, persists, and is idempotent', () async {
    final settings = await _settings();
    final p = PersistedEnum(
      settings,
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.apple,
      encode: (f) => f.code,
    );

    expect(p.set(_Fruit.banana), isTrue);
    expect(p.value, _Fruit.banana);
    expect(settings.getString(_key), 'b');

    expect(p.set(_Fruit.banana), isFalse);
  });

  test('defaults to the enum name when no encoder is given', () async {
    final settings = await _settings();
    PersistedEnum(
      settings,
      key: _key,
      values: _Fruit.values,
      fallback: _Fruit.apple,
    ).set(_Fruit.banana);
    expect(settings.getString(_key), 'banana');
  });
}
