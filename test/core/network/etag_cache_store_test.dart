import 'dart:io';

import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late EtagCacheStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('etag_store_test');
    store = EtagCacheStore(dir);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  File entryFile() => dir.listSync().whereType<File>().firstWhere(
    (f) => f.path.endsWith('.entry'),
  );

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

  test('the entry is one file with a gzip-compressed body', () async {
    final body = List.filled(500, 'compressible').join(',');
    await store.write('https://x/big', etag: '1', body: body);
    final entries = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.entry'),
    );
    expect(entries, hasLength(1), reason: 'a single file per entry');
    expect(
      entries.single.lengthSync(),
      lessThan(body.length),
      reason: 'body is gzipped',
    );
  });

  test('distinct URLs are independent entries', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await store.write('https://x/b', etag: '2', body: 'B');
    expect((await store.read('https://x/a'))!.body, 'A');
    expect((await store.read('https://x/b'))!.body, 'B');
  });

  test('a corrupt entry reads as a miss, not a crash', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await entryFile().writeAsBytes([0, 1, 2, 3]); // no header separator
    expect(await store.read('https://x/a'), isNull);
    expect(await store.readEtag('https://x/a'), isNull);
  });

  test('clear removes every entry', () async {
    await store.write('https://x/a', etag: '1', body: 'A');
    await store.clear();
    expect(await store.read('https://x/a'), isNull);
  });

  test('evicts oldest-first when over the byte budget', () async {
    // Same body and same-length URLs → identical entry size; sizing maxBytes to
    // exactly one entry means the second write must evict the first.
    final body = List.generate(40, (i) => 'item-$i-payload').join(',');
    await store.write('https://x/old', etag: '1', body: body);
    final oneSize = entryFile().lengthSync();
    await store.clear();

    final bounded = EtagCacheStore(dir, maxBytes: oneSize);
    await bounded.write('https://x/old', etag: '1', body: body);
    await bounded.write('https://x/new', etag: '2', body: body);

    expect(
      await bounded.read('https://x/old'),
      isNull,
      reason: 'oldest evicted',
    );
    expect(
      await bounded.read('https://x/new'),
      isNotNull,
      reason: 'newest kept',
    );
  });
}
