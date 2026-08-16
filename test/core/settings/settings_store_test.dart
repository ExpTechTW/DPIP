/// The settings store and its key registry.
///
/// The compile-time guarantees — no raw-string key, no type-mismatched read —
/// cannot be tested at runtime, because the point is that such code does not
/// compile. What is testable is everything else: that a value survives a
/// reopen, that reads stay synchronous, that a key added to the registry is
/// also listed for the import, and that a database which will not open
/// degrades to a session-only store instead of taking the app down.
library;

import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fresh in-memory database per call.
///
/// `singleInstance: false` matters: sqflite hands back the *same* handle for a
/// repeated path, and `:memory:` is a path — so without it every test in the
/// file shares one database and the second test starts with the first one's
/// rows. That is exactly the kind of shared state that makes a suite pass in
/// isolation and fail as a group.
Future<Database> _openMemory() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(singleInstance: false),
);

Future<Database> _db() async {
  final db = await _openMemory();
  await SettingsStore.createSchema(db);
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('a value survives a reopen', () async {
    final db = await _db();
    final first = await SettingsStore.open(db);
    await first.setString(SettingKeys.locale, 'ja');
    await first.setBool(SettingKeys.onboardingComplete, true);
    await first.setInt(SettingKeys.channelVersion, 3);
    await first.setStringList(SettingKeys.savedRegionCodes, ['100', '970']);

    final reopened = await SettingsStore.open(db);
    expect(reopened.getString(SettingKeys.locale), 'ja');
    expect(reopened.getBool(SettingKeys.onboardingComplete), isTrue);
    expect(reopened.getInt(SettingKeys.channelVersion), 3);
    expect(reopened.getStringList(SettingKeys.savedRegionCodes), [
      '100',
      '970',
    ]);
  });

  test('reads are synchronous — the table is in memory', () async {
    // Settings are read during `build` all over the app. If a read ever became
    // a Future this would stop compiling, which is the point.
    final store = await SettingsStore.open(await _db());
    await store.setBool(SettingKeys.experimentalUnlocked, true);
    final bool? value = store.getBool(SettingKeys.experimentalUnlocked);
    expect(value, isTrue);
  });

  test('an absent key reads null, not a default', () async {
    final store = await SettingsStore.open(await _db());
    expect(store.getBool(SettingKeys.onboardingComplete), isNull);
    expect(store.getString(SettingKeys.locale), isNull);
    expect(store.getInt(SettingKeys.channelVersion), isNull);
    expect(store.getStringList(SettingKeys.savedRegionCodes), isNull);
  });

  test('remove clears both memory and the table', () async {
    final db = await _db();
    final store = await SettingsStore.open(db);
    await store.setString(SettingKeys.locale, 'ko');
    await store.remove(SettingKeys.locale);
    expect(store.getString(SettingKeys.locale), isNull);
    expect(
      (await SettingsStore.open(db)).getString(SettingKeys.locale),
      isNull,
    );
  });

  test('with no database it still works, for this session only', () async {
    // The launch path where the database would not open. Losing settings on
    // restart is bad; refusing to launch is worse.
    final store = await SettingsStore.open(null);
    await store.setString(SettingKeys.locale, 'th');
    expect(store.getString(SettingKeys.locale), 'th');
  });

  test('a value written under one key is invisible under another', () {
    // The registry is the whole persisted surface; two keys sharing a storage
    // address would make one setting silently overwrite another.
    final store = SettingsStore.inMemory();
    store.setString(SettingKeys.locale, 'ja');
    expect(store.getString(SettingKeys.themeMode), isNull);
    expect(store.getString(SettingKeys.pushToken), isNull);
  });
}
