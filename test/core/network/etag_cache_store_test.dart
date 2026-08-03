import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late EtagCacheStore store;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await EtagCacheStore.createSchema(db);
    store = EtagCacheStore(db);
  });

  tearDown(() async => db.close());

  test('read on an empty cache is a miss', () async {
    expect(await store.read('https://x/a'), isNull);
    expect(await store.readEtag('https://x/a'), isNull);
  });

  test('write then read round-trips etag, body, and content-type', () async {
    await store.write(
      'https://x/a',
      etag: 'W/"1"',
      body: '{"k":1}',
      contentType: 'application/json',
    );
    final entry = await store.read('https://x/a');
    expect(entry, isNotNull);
    expect(entry!.etag, 'W/"1"');
    expect(entry.body, '{"k":1}');
    expect(entry.contentType, 'application/json');
    expect(await store.readEtag('https://x/a'), 'W/"1"');
  });

  test('the same key updates in place (upsert) — one row', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await store.write('https://x/a', etag: '2', body: 'B');
    final entry = await store.read('https://x/a');
    expect(entry!.etag, '2');
    expect(entry.body, 'B');
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM http_cache');
    expect(rows.first['c'], 1, reason: 'replaced, not duplicated');
  });

  test('the stored value is gzip-compressed', () async {
    final body = List.filled(500, 'compressible').join(',');
    await store.write('https://x/big', etag: '1', body: body);
    final rows = await db.query(
      'http_cache',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['https://x/big'],
    );
    final blob = rows.first['value'] as Uint8List;
    expect(blob.length, lessThan(body.length), reason: 'gzipped');
  });

  test('distinct URLs are independent entries', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await store.write('https://x/b', etag: '2', body: 'B');
    expect((await store.read('https://x/a'))!.body, 'A');
    expect((await store.read('https://x/b'))!.body, 'B');
  });

  test('a corrupt value reads as a miss, not a crash', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await db.update(
      'http_cache',
      {
        'value': Uint8List.fromList([0, 1, 2, 3]),
      }, // not gzip
      where: 'key = ?',
      whereArgs: ['https://x/a'],
    );
    expect(await store.read('https://x/a'), isNull);
    expect(await store.readEtag('https://x/a'), isNull);
  });

  test('clear removes every entry', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await store.clear();
    expect(await store.read('https://x/a'), isNull);
  });

  test('a write sweeps entries last-used older than maxAge (7 days)', () async {
    await store.write('https://x/old', etag: '1', body: 'A');
    final eightDaysAgo = DateTime.now()
        .subtract(const Duration(days: 8))
        .millisecondsSinceEpoch;
    await db.update(
      'http_cache',
      {'time': eightDaysAgo},
      where: 'key = ?',
      whereArgs: ['https://x/old'],
    );

    // Any fresh write triggers the age sweep.
    await store.write('https://x/new', etag: '2', body: 'B');

    expect(
      await store.read('https://x/old'),
      isNull,
      reason: 'expired evicted',
    );
    expect(await store.read('https://x/new'), isNotNull);
  });

  test(
    'a recent read keeps an otherwise-old entry past the age sweep',
    () async {
      await store.write('https://x/kept', etag: '1', body: 'A');
      final eightDaysAgo = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      await db.update(
        'http_cache',
        {'time': eightDaysAgo},
        where: 'key = ?',
        whereArgs: ['https://x/kept'],
      );
      // Touch last-used to now.
      expect(await store.read('https://x/kept'), isNotNull);

      await store.write('https://x/new', etag: '2', body: 'B');
      expect(await store.read('https://x/kept'), isNotNull);
    },
  );

  test('size round-trips', () async {
    await store.write('https://x/a', etag: '1', body: 'ABCDE', size: 4096);
    expect((await store.read('https://x/a'))!.size, 4096);
  });

  test('a legacy entry without a size falls back to body length', () async {
    // Simulate a pre-`size` entry: a gzipped payload lacking the 'size' key.
    final payload = GZipCodec(level: 9).encode(
      utf8.encode(
        jsonEncode({'etag': '1', 'contentType': null, 'body': 'ABCDE'}),
      ),
    );
    await db.insert('http_cache', {
      'key': 'https://x/legacy',
      'value': Uint8List.fromList(payload),
      'time': DateTime.now().millisecondsSinceEpoch,
    });
    expect((await store.read('https://x/legacy'))!.size, 'ABCDE'.length);
  });

  test('stats reports row count and total stored bytes', () async {
    expect(await store.stats(), (rows: 0, bytes: 0));

    await store.write('https://x/a', etag: '1', body: 'A');
    await store.write('https://x/b', etag: '2', body: 'B');
    final stats = await store.stats();
    expect(stats.rows, 2);
    expect(stats.bytes, greaterThan(0));
  });

  test('size trim drops least-recently-used rows when over maxBytes', () async {
    // Tiny ceiling so a few compressible-but-non-empty rows overflow.
    final tight = EtagCacheStore(db, maxBytes: 80);
    final fat = List.filled(200, 'x').join();
    await tight.write('https://x/old', etag: '1', body: fat);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await tight.write('https://x/new', etag: '2', body: fat);

    expect(await tight.read('https://x/old'), isNull, reason: 'LRU trimmed');
    expect(await tight.read('https://x/new'), isNotNull);
    expect((await tight.stats()).bytes, lessThanOrEqualTo(80));
  });

  test('size trim prefers unread rows over recently-read ones', () async {
    final fat = List.filled(200, 'x').join();
    // Find a ceiling that holds two rows but not three.
    await store.write('https://x/probe1', etag: '1', body: fat);
    await store.write('https://x/probe2', etag: '2', body: fat);
    final two = (await store.stats()).bytes;
    await store.clear();
    final tight = EtagCacheStore(db, maxBytes: two);

    await tight.write('https://x/a', etag: '1', body: fat);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await tight.write('https://x/b', etag: '2', body: fat);
    await tight.read('https://x/a'); // bump last-used
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await tight.write('https://x/c', etag: '3', body: fat);

    expect(await tight.read('https://x/b'), isNull, reason: 'unread LRU');
    expect(await tight.read('https://x/a'), isNotNull);
    expect(await tight.read('https://x/c'), isNotNull);
  });
}
