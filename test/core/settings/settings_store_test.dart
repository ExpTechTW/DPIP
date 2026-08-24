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
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';

Future<SqliteDatabase> _db() async {
  final db = openMemoryDb();
  await SettingsStore.createSchema(db);
  return db;
}

Future<void> insertRow(SqliteDatabase db, String key, String value) =>
    db.execute('INSERT INTO $settingsTable (key, value) VALUES (?, ?)', [
      key,
      value,
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('one malformed row does not discard onboarding completion', () async {
    final db = await _db();
    await insertRow(db, SettingKeys.locale.name, '{not json');
    await insertRow(db, SettingKeys.onboardingComplete.name, 'true');

    final store = await SettingsStore.open(db);

    expect(store.getString(SettingKeys.locale), isNull);
    expect(store.getBool(SettingKeys.onboardingComplete), isTrue);
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

  test('a degraded session is visible, and attach replays both ways', () async {
    // The launch whose database never opened: writes stay in memory (and are
    // flagged), then the database opens mid-session. The session's own write
    // must reach disk, and rows it never saw must come back — a returning
    // user's onboarding flag among them — without clobbering what the
    // session read or wrote.
    final db = await _db();
    await insertRow(db, SettingKeys.onboardingComplete.name, 'true');
    await insertRow(db, SettingKeys.experimentalUnlocked.name, 'true');

    final store = await SettingsStore.open(null);
    expect(store.isDegraded, isTrue);
    expect(store.getBool(SettingKeys.onboardingComplete), isNull);
    await store.setInt(SettingKeys.channelVersion, 7);
    await store.remove(SettingKeys.experimentalUnlocked);

    expect(await store.attachDatabase(db), isTrue);
    expect(store.isDegraded, isFalse);
    // Disk → session: the unseen row is adopted…
    expect(store.getBool(SettingKeys.onboardingComplete), isTrue);
    // …and session → disk: the backlog landed, removals included.
    expect(
      (await SettingsStore.open(db)).getInt(SettingKeys.channelVersion),
      7,
    );
    expect(store.getBool(SettingKeys.experimentalUnlocked), isNull);
    expect(
      (await SettingsStore.open(db)).getBool(SettingKeys.experimentalUnlocked),
      isNull,
      reason: 'a degraded-session removal must not be adopted back from disk',
    );

    // A second attach is a no-op.
    expect(await store.attachDatabase(db), isFalse);
  });

  test('attach never overwrites what the session holds', () async {
    // The database remembers locale=ja from before a degraded launch; during
    // that launch the user picked th. The session is what the user sees, so
    // th must win in memory *and* on disk after the attach.
    final db = await _db();
    await insertRow(db, SettingKeys.locale.name, '"ja"');

    final store = await SettingsStore.open(null);
    await store.setString(SettingKeys.locale, 'th');
    await store.attachDatabase(db);

    expect(store.getString(SettingKeys.locale), 'th');
    expect((await SettingsStore.open(db)).getString(SettingKeys.locale), 'th');
  });

  test('a write racing attach is drained before the hand-off', () async {
    final db = await _db();
    final store = await SettingsStore.open(null);

    final attaching = store.attachDatabase(db);
    // attach has yielded to its first database read while the store is still
    // degraded. This write must join the backlog, then be drained before _db
    // becomes visible to later writes.
    await store.setString(SettingKeys.locale, 'th');

    expect(await attaching, isTrue);
    expect(store.isDegraded, isFalse);
    expect((await SettingsStore.open(db)).getString(SettingKeys.locale), 'th');
  });

  test('a failed attach stays degraded and preserves its backlog', () async {
    final failed = await _db();
    await failed.execute(
      'CREATE TRIGGER reject_setting BEFORE INSERT ON $settingsTable '
      "BEGIN SELECT RAISE(ABORT, 'blocked'); END",
    );
    final store = await SettingsStore.open(null);
    await store.setString(SettingKeys.locale, 'ja');

    await expectLater(store.attachDatabase(failed), throwsA(anything));
    expect(store.isDegraded, isTrue);

    await failed.execute('DROP TRIGGER reject_setting');
    expect(await store.attachDatabase(failed), isTrue);
    expect(
      (await SettingsStore.open(failed)).getString(SettingKeys.locale),
      'ja',
    );
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
