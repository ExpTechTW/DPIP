/// Planting the bundled basemap: everything on a fresh install, nothing on a
/// launch that already has it, never over a downloaded tile, again after the
/// OS empties the cache, and a newer bundle replacing an older one's rows.
library;

import 'dart:io';

import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/shared/map/basemap_seed.g.dart';
import 'package:dpip/shared/map/basemap_seed_format.dart';
import 'package:dpip/shared/map/basemap_seeder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../../core/storage/memory_db.dart';

/// The real bundle, counting what is asked of it.
class _Bundle extends AssetBundle {
  final List<String> loads = [];
  final Set<String> failing = {};
  final Set<String> truncated = {};
  int _inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (failing.contains(key)) throw StateError('no asset $key');
      final data = await rootBundle.load(key);
      if (!truncated.contains(key)) return data;
      return ByteData.sublistView(data, 0, data.lengthInBytes - 1);
    } finally {
      _inFlight--;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const seed = bundledBasemapSeed;
  final etag = EtagCacheStore.seedEtag(seed.version);
  final allUrls = [
    for (final part in seed.parts)
      for (final tile in part.tiles)
        basemapSeedUrl(seed.source, tile.z, tile.x, tile.y),
  ];
  final tileCount = allUrls.length;

  late SqliteDatabase db;
  late EtagCacheStore store;
  late _Bundle bundle;

  setUp(() async {
    db = openMemoryDb();
    await EtagCacheStore.createSchema(db);
    store = EtagCacheStore(db);
    bundle = _Bundle();
  });

  tearDown(() async => db.close());

  BasemapSeeder seeder() => BasemapSeeder(store, bundle: bundle);

  test(
    'a fresh install plants every bundled tile, one part at a time',
    () async {
      final report = await seeder().run();

      expect(report.planted, tileCount);
      expect(report.loaded, seed.parts.length);
      expect(bundle.maxInFlight, 1, reason: 'one part in memory at a time');
      final etags = await store.etagsFor(allUrls);
      expect(etags.length, tileCount);
      expect(etags.values.toSet(), {etag});
    },
  );

  test('a planted tile reads back as the tile the origin served', () async {
    await seeder().run();

    final part = seed.parts.first;
    final tile = part.tiles.first;
    final asset = (await rootBundle.load(part.asset)).buffer.asUint8List();
    final expected = gzip.decode(
      asset.sublist(tile.offset, tile.offset + tile.length),
    );
    final row = await store.readBytes(
      basemapSeedUrl(seed.source, tile.z, tile.x, tile.y),
    );
    expect(row?.bytes, expected);
    expect(row?.etag, etag);
  });

  test('a tile the origin has nothing for is planted empty', () async {
    await seeder().run();

    final empty = [
      for (final part in seed.parts)
        for (final tile in part.tiles)
          if (tile.length == 0) tile,
    ];
    expect(empty, isNotEmpty, reason: 'open sea at z8–9');
    final tile = empty.first;
    final row = await store.readBytes(
      basemapSeedUrl(seed.source, tile.z, tile.x, tile.y),
    );
    expect(row?.bytes, isEmpty);
  });

  test('a launch that already has the bundle reads no asset at all', () async {
    await seeder().run();
    bundle.loads.clear();

    final again = await seeder().run();

    expect(again.planted, 0);
    expect(again.loaded, 0);
    expect(bundle.loads, isEmpty);
  });

  test('a downloaded tile is never replaced', () async {
    final url = allUrls[3];
    await store.writeBytes(
      url,
      etag: EtagInterceptor.etagFromUrl(Uri.parse(url)),
      bytes: Uint8List.fromList([9, 9, 9]),
    );
    final cached404 = allUrls[40];
    await store.writeBytes(
      cached404,
      etag: EtagInterceptor.negativeTileEtag,
      bytes: Uint8List(0),
    );

    final report = await seeder().run();

    expect(report.planted, tileCount - 2);
    expect((await store.readBytes(url))?.bytes, [9, 9, 9]);
    expect(
      (await store.readBytes(cached404))?.etag,
      EtagInterceptor.negativeTileEtag,
    );
  });

  test('a part whose tiles are all downloaded is not even loaded', () async {
    final first = seed.parts.first;
    for (final tile in first.tiles) {
      final url = basemapSeedUrl(seed.source, tile.z, tile.x, tile.y);
      await store.writeBytes(
        url,
        etag: EtagInterceptor.etagFromUrl(Uri.parse(url)),
        bytes: Uint8List.fromList([1]),
      );
    }

    await seeder().run();

    expect(bundle.loads, isNot(contains(first.asset)));
    expect(bundle.loads, hasLength(seed.parts.length - 1));
  });

  test('a newer bundle replaces what an older one planted', () async {
    final old = EtagCacheStore.seedEtag('older');
    await store.seedBytesBatch([
      for (final url in allUrls.take(10))
        (url: url, body: Uint8List.fromList(GZipCodec().encode([0]))),
    ], etag: old);

    final report = await seeder().run();

    expect(report.planted, tileCount);
    final etags = await store.etagsFor(allUrls);
    expect(etags.values.toSet(), {etag});
  });

  test(
    'after the OS empties the cache, the next launch plants again',
    () async {
      await seeder().run();
      await store.clear();

      final report = await seeder().run();

      expect(report.planted, tileCount);
    },
  );

  test('a part that does not match the index is skipped, not sliced', () async {
    final bad = seed.parts[1];
    bundle.truncated.add(bad.asset);

    final report = await seeder().run();

    expect(report.planted, tileCount - bad.tiles.length);
    final etags = await store.etagsFor([
      for (final tile in bad.tiles)
        basemapSeedUrl(seed.source, tile.z, tile.x, tile.y),
    ]);
    expect(etags, isEmpty);
  });

  test('a part that fails to load is retried on the next launch', () async {
    final bad = seed.parts.last;
    bundle.failing.add(bad.asset);

    final first = await seeder().run();
    expect(first.planted, tileCount - bad.tiles.length);

    bundle
      ..failing.clear()
      ..loads.clear();
    final second = await seeder().run();

    expect(second.planted, bad.tiles.length);
    expect(bundle.loads, [bad.asset]);
  });
}
