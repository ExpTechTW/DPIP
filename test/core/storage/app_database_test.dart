/// The line between the cache and everything else.
///
/// The requirement is "clearing the cache must not delete anything else", and
/// the design answer is that it *cannot*: the cache is a separate database
/// file and [AppDatabase.clearCache] holds no handle to the durable one. This
/// file is what makes that a fact rather than an intention — it fills every
/// durable table, clears the cache, and checks all of it is still there.
///
/// It also pins the table map, because the failure mode is a future table
/// added to the wrong file. A table of user data created in the cache database
/// would be silently destroyed on the first cache clear and nothing else would
/// notice.
library;

import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/app_database.dart';
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

Future<Database> _durable() async {
  final db = await _openMemory();
  await SettingsStore.createSchema(db);
  await TleStore.createSchema(db);
  await MeshStore.createSchema(db);
  return db;
}

Future<Database> _cache() async {
  final db = await _openMemory();
  await EtagCacheStore.createSchema(db);
  await NetworkUsageStore.createSchema(db);
  return db;
}

Future<Set<String>> _tables(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
  );
  return {for (final row in rows) row['name']! as String};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('clearing the cache leaves every other category intact', () async {
    final durable = await _durable();
    final cache = await _cache();
    final database = AppDatabase(durable: durable, cache: cache);

    // Fill one row in every durable category.
    final settings = await SettingsStore.open(durable);
    await settings.setBool(SettingKeys.onboardingComplete, true);
    await TleStore(durable)
        .write(text: 'ISS\n1 ...\n2 ...', fetchedAt: DateTime.utc(2026, 8, 14));
    await MeshStore(durable).addMessage(
      MeshStoredMessage(
        from: 7,
        channel: 0,
        text: 'still here',
        timestamp: DateTime.utc(2026, 8, 14),
        outgoing: false,
      ),
    );
    await MeshStore(durable).writeNodes([
      {'num': 7, 'name': 'repeater', 'snr': 0.0, 'via_mqtt': 0},
    ]);
    // And something in the cache.
    await cache.insert('http_cache', {
      'key': 'https://example.test/a',
      'etag': 'x',
      'kind': EtagCacheStore.kindJson,
      'body': 'hello',
      'size': 5,
      'time': 0,
    });

    expect(await database.clearCache(), greaterThan(0));

    // The cache is empty…
    expect(
      (await cache.rawQuery('SELECT COUNT(*) AS n FROM http_cache')).first['n'],
      0,
    );
    // …and every other category survived.
    final after = await SettingsStore.open(durable);
    expect(after.getBool(SettingKeys.onboardingComplete), isTrue);
    expect((await TleStore(durable).read())?.text, contains('ISS'));
    expect(await MeshStore(durable).messages(channel: 0), isNotEmpty);
    expect(await MeshStore(durable).readNodes(), hasLength(1));
  });

  test(
    'clearCache cannot reach the durable file — it holds no handle',
    () async {
      // Constructed with a cache and *no* durable database at all. If clearing
      // ever needed the other file, this would throw rather than quietly work.
      final cache = await _cache();
      await cache.insert('http_cache', {
        'key': 'https://example.test/b',
        'etag': 'y',
        'kind': EtagCacheStore.kindJson,
        'body': 'bytes',
        'size': 5,
        'time': 0,
      });
      const database = AppDatabase(durable: null, cache: null);
      expect(await database.clearCache(), 0, reason: 'no cache, nothing to do');

      final wired = AppDatabase(durable: null, cache: cache);
      expect(await wired.clearCache(), 1);
    },
  );

  test('the cache database holds only cache tables', () async {
    // The failure this guards: a future table of user data created in the
    // cache file would be destroyed by the first clear, and nothing else in
    // the app would notice. The check is one-directional because a fresh
    // install has none of the cache tables yet.
    expect(await _tables(await _cache()), everyElement(isIn(cacheTables)));
    expect(await _tables(await _cache()), contains('http_cache'));
  });

  test('the durable database holds no cache table', () async {
    final tables = await _tables(await _durable());
    for (final table in cacheTables) {
      expect(tables, isNot(contains(table)));
    }
    expect(tables, contains(settingsTable));
    expect(tables, contains(tleTable));
    expect(tables, contains('mesh_messages'));
    expect(tables, contains('mesh_nodes'));
  });

  test('a missing database degrades instead of throwing', () async {
    const database = AppDatabase(durable: null, cache: null);
    expect(await database.clearCache(), 0);
    expect(await database.cacheBytes(), 0);
    // Settings still work, they simply do not survive the session.
    final settings = await SettingsStore.open(null);
    await settings.setBool(SettingKeys.onboardingComplete, true);
    expect(settings.getBool(SettingKeys.onboardingComplete), isTrue);
  });
}
