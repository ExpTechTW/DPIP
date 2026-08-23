import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:dpip/features/weather/data/frame_tile_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../../core/storage/memory_db.dart';

const terrainUrl =
    'https://static.lb.exptech.dev/api/v1/map/terrain/7/107/55.png';

Uint8List malformedEmptyRadarGif() =>
    base64Decode('R0lGODlhAQABAAAAACH5BAEAAAAALAAAAAABAAEAAAIBADs=');

Uint8List opaqueBlackPlaceholderPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

Uint8List transparentPlaceholderPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUA'
  'AXpeqz8AAAAASUVORK5CYII=',
);

Uint8List wireTileData(Object? raw) => switch (raw) {
  1 => transparentPlaceholderPng(),
  Uint8List data => data,
  _ => throw StateError('unexpected tile wire data: $raw'),
};

const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

Future<int> decodedAlpha(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final rgba = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final alpha = rgba!.getUint8(3);
  frame.image.dispose();
  codec.dispose();
  return alpha;
}

final class _TestFrameRepository extends FrameTileRepository {
  _TestFrameRepository(super.warmer);

  @override
  int get maxZoom => 11;

  @override
  int get sourceMaxZoom => maxZoom;

  @override
  String get tilePathPrefix => '/api/v2/tiles/radar/';

  @override
  Future<Result<List<String>>> frames() async => const Ok(['frame']);

  @override
  String tileUrl(String frame) =>
      'https://static.exptech.dev/api/v2/tiles/radar/'
      '$frame/{z}/{x}/{y}.webp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/maplibre_gl/tile_cache');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();

  late SqliteDatabase db;
  late EtagCacheStore store;
  late MapTileCache cache;
  late List<MethodCall> nativeCalls;
  late Map<String, Uint8List> nativeMemory;
  late int nativeLimit;
  late bool nativeSupportsTileToken;
  late List<String> injectedUrls;
  Completer<void>? blockedInject;
  Completer<void>? injectStarted;

  setUp(() async {
    db = openMemoryDb();
    await EtagCacheStore.createSchema(db);
    await NetworkUsageStore.createSchema(db);
    store = EtagCacheStore(db);
    cache = MapTileCache(store);
    nativeCalls = [];
    nativeMemory = {};
    nativeLimit = 2 * 1024 * 1024;
    nativeSupportsTileToken = true;
    injectedUrls = [];
    blockedInject = null;
    injectStarted = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      final arguments =
          call.arguments as Map<Object?, Object?>? ??
          const <Object?, Object?>{};
      switch (call.method) {
        case 'filterMissing':
          return [
            for (final url in (arguments['urls'] as List).cast<String>())
              if (!nativeMemory.containsKey(url)) url,
          ];
        case 'injectTiles':
          final gate = blockedInject;
          if (gate != null) {
            blockedInject = null;
            injectStarted?.complete();
            await gate.future;
          }
          for (final row
              in (arguments['entries'] as List).cast<Map<Object?, Object?>>()) {
            final url = row['url'] as String;
            injectedUrls.add(url);
            nativeMemory[url] = wireTileData(row['data']);
          }
          return {
            'used': nativeMemory.values.fold<int>(
              0,
              (sum, bytes) => sum + bytes.length,
            ),
            'limit': nativeLimit,
          };
        case 'evictTiles':
          final needles = (arguments['contains'] as List).cast<String>();
          if (needles.isEmpty) {
            nativeMemory.clear();
          } else {
            nativeMemory.removeWhere((url, _) => needles.any(url.contains));
          }
        case 'setMemoryLimit':
          nativeLimit = arguments['bytes'] as int;
          if (nativeSupportsTileToken) {
            return {
              'wireTokens': [1],
            };
          }
          return null;
      }
      return null;
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await db.close();
  });

  /// Drives the handler `bindMapLibreTileCache` installed, as native would.
  Future<Object?> fromNative(String method, Object? arguments) async {
    final reply = await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      null,
    );
    return reply == null ? null : codec.decodeEnvelope(reply);
  }

  test('install hands native the same list the store gates on', () async {
    await cache.install();

    final patterns =
        nativeCalls
                .firstWhere((c) => c.method == 'setCacheablePatterns')
                .arguments
            as Map;
    expect(
      patterns['patterns'],
      EtagInterceptor.immutableAssetMarkers,
      reason:
          'two lists would let native ask forever about a URL the store '
          'refuses to keep',
    );
  });

  test('native can pull the patterns after binding', () async {
    await cache.install();

    // What the plugin does on attach. Binding happens during bootstrap, before
    // any map widget exists and therefore before the plugin is registered, so
    // the push above can land on a channel with no handler — this pull is what
    // makes the cache work regardless of which side came up first.
    expect(
      await fromNative('cacheablePatterns', null),
      EtagInterceptor.immutableAssetMarkers,
      reason:
          'without an answer here native matches no URL at all, and the store '
          'is silently bypassed rather than merely slow',
    );
  });

  test('a live map re-applies the L1 byte cap after channel attach', () async {
    await cache.install(memoryBytes: 48 * 1024 * 1024);
    // Reproduce native attaching after bootstrap: it starts from its 2 MB
    // fallback because the first Dart-to-native message no longer exists.
    nativeLimit = 2 * 1024 * 1024;
    nativeCalls.clear();

    await cache.syncNativeConfiguration();

    expect(nativeLimit, 48 * 1024 * 1024);
    expect(nativeCalls.single.method, 'setMemoryLimit');
  });

  test('glyphs are cached by the app store, not just by MapLibre', () async {
    expect(
      EtagInterceptor.isImmutableTile(
        Uri.parse(
          'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/Noto/0-255.pbf',
        ),
      ),
      isTrue,
      reason: 'otherwise glyph traffic is invisible to the usage accounting',
    );
  });

  test('a downloaded tile lands in the store and is served back', () async {
    await cache.install();
    const url = 'https://static.exptech.dev/api/v2/tiles/radar/1/2/3/4.webp';
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    await fromNative('putBatch', {
      'entries': [
        {'url': url, 'data': bytes, 'contentType': 'image/webp'},
      ],
    });

    final served = await fromNative('getBatch', {
      'urls': [url],
    });
    expect((served! as Map)[url], isNotNull);
    expect(((served as Map)[url] as Map)['data'], bytes);
  });

  test('the malformed empty radar GIF is persisted as a valid PNG', () async {
    await cache.install();
    const url = 'https://static.exptech.dev/api/v2/tiles/radar/1/2/3/4.webp';
    // Native inserts a live response into L1 before its delayed putBatch tells
    // Dart about it. Reproduce that ordering, not an initially empty mirror.
    nativeMemory[url] = malformedEmptyRadarGif();

    await fromNative('putBatch', {
      'entries': [
        {
          'url': url,
          'data': malformedEmptyRadarGif(),
          'contentType': 'image/webp',
        },
      ],
    });

    final stored = await store.readBytes(url);
    expect(stored, isNotNull);
    expect(stored!.bytes.take(pngSignature.length), pngSignature);
    expect(stored.contentType, 'image/png');
    expect(
      await decodedAlpha(stored.bytes),
      0,
      reason: 'a decodable but opaque black pixel becomes a full black tile',
    );
    expect(
      stored.size,
      malformedEmptyRadarGif().length,
      reason: 'replacement bytes must not inflate downloaded traffic',
    );
    expect(
      nativeMemory[url]!.take(pngSignature.length),
      pngSignature,
      reason: 'the repaired L2 body must also overwrite the raw live L1 body',
    );
    final repair = nativeCalls.lastWhere(
      (call) => call.method == 'injectTiles',
    );
    expect(
      (((repair.arguments as Map)['entries'] as List).single as Map)['data'],
      1,
      reason: 'the repeated transparent PNG crosses the channel as a token',
    );

    final served = await fromNative('getBatch', {
      'urls': [url],
    }) as Map;
    final entry = served[url] as Map;
    expect(
      entry['data'],
      1,
      reason: 'L2 lookup also avoids re-sending the shared PNG bytes',
    );
    expect(entry['contentType'], 'image/png');
  });

  test('a native transparent-raster token retains its source size', () async {
    await cache.install();
    const url =
        'https://static.exptech.dev/api/v2/tiles/radar/native/2/3/4.webp';

    await fromNative('putBatch', {
      'entries': [
        {'url': url, 'data': 1, 'contentType': 'image/png', 'sourceSize': 35},
      ],
    });

    final stored = await store.readBytes(url);
    expect(stored, isNotNull);
    expect(await decodedAlpha(stored!.bytes), 0);
    expect(stored.size, 35);
    expect(
      nativeCalls.where((call) => call.method == 'injectTiles'),
      isEmpty,
      reason: 'native already canonicalised L1; Dart must not inject it again',
    );
  });

  test('an older native bridge receives transparent PNG bytes', () async {
    nativeSupportsTileToken = false;
    await cache.install();
    const url =
        'https://static.exptech.dev/api/v2/tiles/radar/legacy-native/2/3/4.webp';
    await store.writeBytes(
      url,
      etag: 'legacy-native',
      bytes: transparentPlaceholderPng(),
      contentType: 'image/png',
    );

    await cache.warm([url], refreshResident: true);

    final inject = nativeCalls.lastWhere(
      (call) => call.method == 'injectTiles',
    );
    final data =
        (((inject.arguments as Map)['entries'] as List).single as Map)['data'];
    expect(
      data,
      isA<Uint8List>(),
      reason: 'data: 1 would be silently ignored by the old Android bridge',
    );
    expect(await decodedAlpha(data as Uint8List), 0);
  });

  test('a warm repairs malformed empty radar GIFs already in L2', () async {
    await cache.install();
    const url = 'https://static.exptech.dev/api/v2/tiles/radar/old/2/3/4.webp';
    await store.writeBytes(
      url,
      etag: 'old',
      bytes: malformedEmptyRadarGif(),
      contentType: 'image/webp',
    );
    nativeMemory[url] = malformedEmptyRadarGif();

    await cache.warm([url], refreshResident: true);

    expect(nativeMemory[url], isNotNull);
    expect(nativeMemory[url]!.take(pngSignature.length), pngSignature);
    final inject = nativeCalls.lastWhere(
      (call) => call.method == 'injectTiles',
    );
    final entry =
        (((inject.arguments as Map)['entries'] as List).single as Map);
    expect(entry['contentType'], 'image/png');
    expect(entry['data'], 1);
    expect(await decodedAlpha(wireTileData(entry['data'])), 0);
  });

  test(
    'a warm upgrades the old opaque black L2 placeholder before L1',
    () async {
      await cache.install();
      const url =
          'https://static.exptech.dev/api/v2/tiles/radar/old-black/2/3/4.webp';
      await store.writeBytes(
        url,
        etag: 'old-black',
        bytes: opaqueBlackPlaceholderPng(),
        contentType: 'image/png',
      );
      nativeMemory[url] = opaqueBlackPlaceholderPng();

      await cache.warm([url], refreshResident: true);

      expect(nativeMemory[url], isNotNull);
      expect(await decodedAlpha(nativeMemory[url]!), 0);
    },
  );

  test('clearing drops the store and the native mirror together', () async {
    await cache.install();
    await store.writeBytes(
      'https://static.exptech.dev/api/v2/tiles/radar/1/2/3/4.webp',
      etag: 'W/"t"',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/webp',
    );

    await store.clear();
    await cache.evict(const []);

    expect((await store.stats()).rows, 0);
    final evict = nativeCalls.lastWhere((c) => c.method == 'evictTiles');
    expect(
      (evict.arguments as Map)['contains'],
      isEmpty,
      reason:
          'an empty match list drops everything — otherwise the mirror '
          'keeps serving bytes the store no longer has, and "cleared" would '
          'not look cleared until the app restarted',
    );
  });

  test('an empty body is kept for the basemap but dropped elsewhere', () async {
    await cache.install();
    const hole = 'https://static.lb.exptech.dev/api/v1/map/tiles/7/1/2.pbf';
    const glyph =
        'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/Noto/0-255.pbf';

    await fromNative('putBatch', {
      'entries': [
        {'url': hole, 'data': Uint8List(0)},
        {'url': glyph, 'data': Uint8List(0)},
      ],
    });

    final served = await fromNative('getBatch', {
      'urls': [hole, glyph],
    }) as Map;
    expect(
      served[hole],
      isNotNull,
      reason: 'ocean / uncovered z-x-y is stable',
    );
    expect(
      served[glyph],
      isNull,
      reason: 'caching a momentary glyph failure would blank labels for a week',
    );
  });

  test('a terrain tile is stored and served byte-for-byte', () async {
    await cache.install();
    // Arbitrary PNG bytes — the encoding is MapLibre's job now (`encoding:
    // 'mapbox'` decodes the server's terrain-RGB natively), so the store must
    // never rewrite them.
    final bytes = Uint8List.fromList([9, 8, 7, 6, 5]);

    await fromNative('putBatch', {
      'entries': [
        {'url': terrainUrl, 'data': bytes, 'contentType': 'image/png'},
      ],
    });

    final stored = await store.readBytes(terrainUrl);
    expect(stored, isNotNull);
    expect(stored!.bytes, bytes);
    final served = await fromNative('getBatch', {
      'urls': [terrainUrl],
    }) as Map;
    expect((served[terrainUrl] as Map)['data'], bytes);
  });

  test('a fill warm preserves caller priority over SQLite row order', () async {
    await cache.install(memoryBytes: 1024);
    const first =
        'https://static.exptech.dev/api/v2/tiles/radar/priority-z/2/3/4.webp';
    const second =
        'https://static.exptech.dev/api/v2/tiles/radar/priority-a/2/3/4.webp';
    // Insert in the opposite order. SQL IN queries do not promise to return
    // rows in argument order, but fill mode must inject nearest-frame URLs
    // first because it may stop before reaching the tail.
    await store.writeBytes(
      second,
      etag: 'second',
      bytes: Uint8List.fromList([2]),
    );
    await store.writeBytes(
      first,
      etag: 'first',
      bytes: Uint8List.fromList([1]),
    );
    nativeCalls.clear();

    await cache.warm([first, second], fillUntil: 0.9);

    final inject = nativeCalls.firstWhere((c) => c.method == 'injectTiles');
    final entries =
        ((inject.arguments as Map<Object?, Object?>)['entries'] as List)
            .cast<Map<Object?, Object?>>();
    expect([for (final row in entries) row['url']], [first, second]);
  });

  test('a fill stops reading L2 once native reaches its target', () async {
    MapTileCache.traceEnabled = true;
    addTearDown(() => MapTileCache.traceEnabled = false);
    await cache.install(memoryBytes: 100);
    final urls = [
      for (var i = 0; i < 800; i++)
        'https://static.exptech.dev/api/v2/tiles/radar/frame-$i/2/3/4.webp',
    ];
    await store.writeBytesBatch([
      for (final url in urls)
        (
          url: url,
          etag: url,
          bytes: Uint8List(10),
          contentType: 'image/webp',
          size: 10,
        ),
    ]);
    final baseline = Log.talker.history.length;

    await cache.warm(urls, fillUntil: 0.9);

    expect(injectedUrls, urls.take(9));
    final probeSizes = nativeCalls
        .where((call) => call.method == 'filterMissing')
        .map(
          (call) => (((call.arguments as Map)['urls'] as List<Object?>).length),
        )
        .toList();
    expect(probeSizes, [384, 384, 32, 384, 384, 32]);
    expect(
      probeSizes,
      everyElement(lessThanOrEqualTo(384)),
      reason: '12k-frame probes must never become one platform-thread task',
    );
    final lines = Log.talker.history
        .skip(baseline)
        .map((entry) => entry.generateTextMessage());
    expect(
      lines,
      contains(contains('scanned=384/800')),
      reason: 'the remaining 416 bodies must stay on disk once L1 reaches 90%',
    );
  });

  test('trace separates L1, L2, injection, and demand fallback', () async {
    MapTileCache.traceEnabled = true;
    addTearDown(() => MapTileCache.traceEnabled = false);
    await cache.install(memoryBytes: 1024);
    const hot = 'https://static.exptech.dev/api/v2/tiles/radar/hot/2/3/4.webp';
    const cold =
        'https://static.exptech.dev/api/v2/tiles/radar/cold/2/3/4.webp';
    const absent =
        'https://static.exptech.dev/api/v2/tiles/radar/absent/2/3/4.webp';
    nativeMemory[hot] = Uint8List.fromList([1]);
    await store.writeBytes(
      cold,
      etag: 'cold',
      bytes: Uint8List.fromList([2, 3]),
    );
    final baseline = Log.talker.history.length;

    await cache.warm([hot, cold], fillUntil: 0.9);
    await fromNative('getBatch', {
      'urls': [absent],
    });

    final lines = Log.talker.history
        .skip(baseline)
        .map((entry) => entry.generateTextMessage())
        .where((line) => line.contains('TILE TRACE'))
        .toList();
    expect(lines, contains(contains('probe l1-hit=1 l1-miss=1')));
    expect(lines, contains(contains('l2-hit=1 l2-miss=0 bytes=2B')));
    expect(lines, contains(contains('inject count=1 bytes=2B')));
    expect(lines, contains(contains('done injected=1 resident=2/2')));
    expect(lines, contains(contains('demand l1-miss=1 l2-hit=0 l2-miss=1')));
  });

  test('frame readiness requires the native display zoom', () async {
    await cache.install();
    final repository = _TestFrameRepository(
      MapTileWarmer(cache, settleDelay: Duration.zero),
    );
    final display = viewportTiles(
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: 7,
      maxZoom: 11,
      pad: 0,
    );
    for (final tile in display) {
      nativeMemory[repository
          .tileUrl('frame')
          .replaceFirst('{z}', '${tile.z}')
          .replaceFirst('{x}', '${tile.x}')
          .replaceFirst('{y}', '${tile.y}')] = Uint8List.fromList([
        1,
      ]);
    }

    final readiness = await repository.frameTileReadiness(
      frame: 'frame',
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: 6,
    );

    expect(readiness.ready, isTrue);
    expect(readiness.resident, display.length);
    expect(readiness.required, display.length);
  });

  test('a complete parent alone is not display-ready', () async {
    await cache.install();
    final repository = _TestFrameRepository(
      MapTileWarmer(cache, settleDelay: Duration.zero),
    );
    final parent = viewportTiles(
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: 5,
      maxZoom: 11,
      pad: 0,
    );
    for (final tile in parent) {
      nativeMemory[repository
          .tileUrl('frame')
          .replaceFirst('{z}', '${tile.z}')
          .replaceFirst('{x}', '${tile.x}')
          .replaceFirst('{y}', '${tile.y}')] = Uint8List.fromList([
        1,
      ]);
    }

    final readiness = await repository.frameTileReadiness(
      frame: 'frame',
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: 6,
    );

    expect(readiness.ready, isFalse);
    expect(readiness.resident, 0);
  });

  test('frame warming covers native display and prefetch zooms', () async {
    await cache.install();
    final repository = _TestFrameRepository(
      MapTileWarmer(cache, settleDelay: Duration.zero),
    );
    nativeCalls.clear();

    await repository.warmFrameTiles(
      frames: const ['frame'],
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: 6,
      immediate: true,
    );

    final probe = nativeCalls.firstWhere(
      (call) => call.method == 'filterMissing',
    );
    final urls = ((probe.arguments as Map)['urls'] as List).cast<String>();
    final zooms = {
      for (final url in urls)
        int.parse(
          RegExp(r'/frame/(\d+)/').firstMatch(Uri.parse(url).path)!.group(1)!,
        ),
    };
    expect(zooms, {7, 6, 5, 3});
  });

  test('a newer working set evicts stale L1 URLs before filling', () async {
    await cache.install(memoryBytes: 1024);
    final warmer = MapTileWarmer(cache, settleDelay: Duration.zero);
    const old = 'https://static.exptech.dev/api/v2/tiles/radar/old/2/3/4.webp';
    const keep =
        'https://static.exptech.dev/api/v2/tiles/radar/keep/2/3/4.webp';
    const fresh =
        'https://static.exptech.dev/api/v2/tiles/radar/fresh/2/3/4.webp';
    for (final (url, value) in [(old, 1), (keep, 2), (fresh, 3)]) {
      await store.writeBytes(
        url,
        etag: '$value',
        bytes: Uint8List.fromList([value]),
      );
    }
    await warmer.warmUrls([old, keep], immediate: true);
    nativeCalls.clear();

    await warmer.warmUrls([keep, fresh], immediate: true);

    final evict = nativeCalls.firstWhere((c) => c.method == 'evictTiles');
    expect((evict.arguments as Map)['contains'], [old]);
    expect(nativeMemory.keys, unorderedEquals([keep, fresh]));
  });

  test(
    'a viewport change evicts one raster family, never every stale URL',
    () async {
      await cache.install(memoryBytes: 1024);
      final warmer = MapTileWarmer(cache, settleDelay: Duration.zero);
      const retiredFrame =
          'https://static.exptech.dev/api/v2/tiles/radar/1787236800';
      const retainedFrame =
          'https://static.exptech.dev/api/v2/tiles/radar/1787237400';
      const retiredA = '$retiredFrame/7/106/55.webp?style=jma';
      const retiredB = '$retiredFrame/7/107/55.webp?style=jma';
      const staleInRetained = '$retainedFrame/7/106/55.webp?style=jma';
      const keep = '$retainedFrame/7/107/55.webp?style=jma';
      for (final (url, value) in [
        (retiredA, 1),
        (retiredB, 2),
        (staleInRetained, 3),
        (keep, 4),
      ]) {
        await store.writeBytes(
          url,
          etag: '$value',
          bytes: Uint8List.fromList([value]),
        );
      }
      await warmer.warmUrls([
        retiredA,
        retiredB,
        staleInRetained,
        keep,
      ], immediate: true);
      nativeCalls.clear();

      await warmer.warmUrls([keep], immediate: true);

      final evict = nativeCalls.firstWhere((c) => c.method == 'evictTiles');
      expect((evict.arguments as Map)['contains'], [
        'https://static.exptech.dev/api/v2/tiles/radar/',
      ]);
      expect(nativeMemory.keys, [keep]);
    },
  );

  test('many retired raster frames collapse to one family eviction', () async {
    await cache.install(memoryBytes: 1024);
    final warmer = MapTileWarmer(cache, settleDelay: Duration.zero);
    final old = [
      for (var i = 0; i < 12; i++)
        'https://static.exptech.dev/api/v2/tiles/radar/'
            '${1700000000 + i * 600}/7/106/55.webp',
    ];
    const fresh =
        'https://static.exptech.dev/api/v2/tiles/radar/'
        '1800000000/7/106/55.webp';
    for (final url in [...old, fresh]) {
      await store.writeBytes(url, etag: url, bytes: Uint8List.fromList([1]));
    }
    await warmer.warmUrls(old, immediate: true);
    nativeCalls.clear();

    await warmer.warmUrls([fresh], immediate: true);

    final evict = nativeCalls.firstWhere((call) => call.method == 'evictTiles');
    expect((evict.arguments as Map)['contains'], [
      'https://static.exptech.dev/api/v2/tiles/radar/',
    ]);
    expect(nativeMemory.keys, [fresh]);
  });

  test('named working sets do not evict each other', () async {
    await cache.install(memoryBytes: 1024);
    final warmer = MapTileWarmer(cache, settleDelay: Duration.zero);
    const baseOld = 'https://static.lb.exptech.dev/api/v1/map/tiles/7/1/1.pbf';
    const baseNew = 'https://static.lb.exptech.dev/api/v1/map/tiles/7/1/2.pbf';
    const terrain =
        'https://static.lb.exptech.dev/api/v1/map/terrain/7/1/1.png';
    for (final (url, value) in [(baseOld, 1), (baseNew, 2), (terrain, 3)]) {
      await store.writeBytes(
        url,
        etag: '$value',
        bytes: Uint8List.fromList([value]),
      );
    }
    await warmer.warmUrls([baseOld], workingSet: 'basemap', immediate: true);
    await warmer.warmUrls([terrain], workingSet: 'terrain', immediate: true);

    await warmer.warmUrls([baseNew], workingSet: 'basemap', immediate: true);

    expect(nativeMemory.keys, unorderedEquals([baseNew, terrain]));

    await warmer.discardWorkingSet('terrain');
    expect(nativeMemory.keys, [baseNew]);
  });

  test('a superseded fill stops before its next injection chunk', () async {
    await cache.install(memoryBytes: 1024);
    final warmer = MapTileWarmer(cache, settleDelay: Duration.zero);
    final old = [
      for (var i = 0; i < 30; i++)
        'https://static.exptech.dev/api/v2/tiles/radar/old/$i/3/4.webp',
    ];
    const fresh =
        'https://static.exptech.dev/api/v2/tiles/radar/fresh/99/3/4.webp';
    for (final url in [...old, fresh]) {
      await store.writeBytes(url, etag: url, bytes: Uint8List.fromList([1]));
    }
    final gate = Completer<void>();
    blockedInject = gate;
    injectStarted = Completer<void>();

    final oldWarm = warmer.warmUrls(old, fillUntil: 0.9, immediate: true);
    await injectStarted!.future;
    final freshWarm = warmer.warmUrls([fresh], fillUntil: 0.9, immediate: true);
    gate.complete();
    await Future.wait([oldWarm, freshWarm]);

    final oldSet = old.toSet();
    expect(
      injectedUrls.where(oldSet.contains),
      hasLength(24),
      reason:
          'the final six stale bodies must never cross the platform channel',
    );
    expect(nativeMemory.keys, [fresh]);
  });

  test(
    'cancelling during debounce performs no native or SQLite warm',
    () async {
      await cache.install(memoryBytes: 1024);
      final warmer = MapTileWarmer(
        cache,
        settleDelay: const Duration(milliseconds: 20),
      );
      const url =
          'https://static.exptech.dev/api/v2/tiles/radar/settled/2/3/4.webp';
      await store.writeBytes(
        url,
        etag: 'settled',
        bytes: Uint8List.fromList([1]),
      );
      nativeCalls.clear();

      final scheduled = warmer.warmUrls([url]);
      warmer.cancel();
      await scheduled;

      expect(
        nativeCalls.where(
          (call) =>
              call.method == 'filterMissing' || call.method == 'injectTiles',
        ),
        isEmpty,
        reason: 'the cancelled settle must stop before L1 probing or L2 reads',
      );
      expect(nativeMemory, isEmpty);
    },
  );
}
