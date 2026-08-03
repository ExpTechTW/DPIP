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

  test('JSON bodies are lightly gzip-compressed on disk', () async {
    final body = List.filled(500, 'compressible').join(',');
    await store.write('https://x/big', etag: '1', body: body);
    final rows = await db.query(
      'http_cache',
      columns: ['body'],
      where: 'key = ?',
      whereArgs: ['https://x/big'],
    );
    final blob = rows.first['body'] as Uint8List;
    expect(blob[0], 0x1f, reason: 'gzip magic');
    expect(blob.length, lessThan(body.length));
  });

  test('binary write stores raw bytes (no base64/gzip envelope)', () async {
    final bytes = Uint8List.fromList(List.generate(64, (i) => i));
    await store.writeBytes(
      'https://x/t.webp',
      etag: 'W/"t"',
      bytes: bytes,
      contentType: 'image/webp',
    );
    final rows = await db.query(
      'http_cache',
      columns: ['kind', 'body'],
      where: 'key = ?',
      whereArgs: ['https://x/t.webp'],
    );
    expect(rows.first['kind'], EtagCacheStore.kindBinary);
    expect(rows.first['body'], bytes);

    final hit = await store.readBytes('https://x/t.webp');
    expect(hit!.bytes, bytes);
    expect(hit.contentType, 'image/webp');
  });

  test(
    'binary memory LRU serves a second read without re-querying shape',
    () async {
      final bytes = Uint8List.fromList([9, 8, 7]);
      await store.writeBytes('https://x/m', etag: '1', bytes: bytes);
      final first = await store.readBytes('https://x/m');
      final second = await store.readBytes('https://x/m');
      expect(identical(first!.bytes, second!.bytes), isTrue);
    },
  );

  test('readBytesMany returns parallel hits', () async {
    await store.writeBytes(
      'https://x/1',
      etag: '1',
      bytes: Uint8List.fromList([1]),
    );
    await store.writeBytes(
      'https://x/2',
      etag: '2',
      bytes: Uint8List.fromList([2]),
    );
    final hits = await store.readBytesMany([
      'https://x/1',
      'https://x/miss',
      'https://x/2',
    ]);
    expect(hits[0]!.bytes, [1]);
    expect(hits[1], isNull);
    expect(hits[2]!.bytes, [2]);
  });

  test('distinct URLs are independent entries', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await store.write('https://x/b', etag: '2', body: 'B');
    expect((await store.read('https://x/a'))!.body, 'A');
    expect((await store.read('https://x/b'))!.body, 'B');
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
      expect(await store.read('https://x/kept'), isNotNull);
      // Allow async touch to land.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await store.write('https://x/new', etag: '2', body: 'B');
      expect(await store.read('https://x/kept'), isNotNull);
    },
  );

  test('size round-trips', () async {
    await store.write('https://x/a', etag: '1', body: 'ABCDE', size: 4096);
    expect((await store.read('https://x/a'))!.size, 4096);
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
    final tight = EtagCacheStore(db, maxBytes: 120, memoryMaxBytes: 0);
    final fat = Uint8List(100);
    await tight.writeBytes('https://x/old', etag: '1', bytes: fat);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await tight.writeBytes('https://x/new', etag: '2', bytes: fat);

    expect(await tight.readBytes('https://x/old'), isNull, reason: 'LRU trimmed');
    expect(await tight.readBytes('https://x/new'), isNotNull);
    expect((await tight.stats()).bytes, lessThanOrEqualTo(120));
  });

  test('size trim prefers unread rows over recently-read ones', () async {
    final fat = Uint8List(100);
    await store.writeBytes('https://x/probe1', etag: '1', bytes: fat);
    await store.writeBytes('https://x/probe2', etag: '2', bytes: fat);
    final two = (await store.stats()).bytes;
    await store.clear();
    final tight = EtagCacheStore(db, maxBytes: two, memoryMaxBytes: 0);

    await tight.writeBytes('https://x/a', etag: '1', bytes: fat);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await tight.writeBytes('https://x/b', etag: '2', bytes: fat);
    await tight.readBytes('https://x/a');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await tight.writeBytes('https://x/c', etag: '3', bytes: fat);

    expect(await tight.readBytes('https://x/b'), isNull, reason: 'unread LRU');
    expect(await tight.readBytes('https://x/a'), isNotNull);
    expect(await tight.readBytes('https://x/c'), isNotNull);
  });
}
