import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const terrainUrl =
    'https://static.lb.exptech.dev/api/v1/map/terrain/7/107/55.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/maplibre_gl/tile_cache');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();

  late Database db;
  late EtagCacheStore store;
  late MapTileCache cache;
  late List<MethodCall> nativeCalls;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await EtagCacheStore.createSchema(db);
    await NetworkUsageStore.createSchema(db);
    store = EtagCacheStore(db);
    cache = MapTileCache(store);
    nativeCalls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      // filterMissing: pretend native holds nothing.
      if (call.method == 'filterMissing') {
        return (call.arguments as Map)['urls'];
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
}
