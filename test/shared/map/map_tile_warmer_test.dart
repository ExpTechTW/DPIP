import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/storage/memory_db.dart';

class _NoHosts extends ApiClient {
  _NoHosts() : super(Dio(), RegionSelection(SettingsStore.inMemory()));

  @override
  List<String> hostsFor(ApiTier tier) => const [];
}

class _Cache extends MapTileCache {
  _Cache(super.store);

  final evicted = <List<String>>[];
  final cancelled = <List<String>>[];
  Completer<void>? gate;
  int injected = 1;

  @override
  Future<TileWarmResult> warm(
    List<String> urls, {
    double fillUntil = 0,
    bool refreshResident = false,
    bool Function()? shouldContinue,
  }) async {
    final waiting = gate;
    if (waiting != null) await waiting.future;
    return (injected: injected, resident: urls.toSet());
  }

  @override
  Future<void> evict(List<String> urlContains) async {
    evicted.add(urlContains);
  }

  @override
  Future<void> cancelFetches({List<String> urlContains = const []}) async {
    cancelled.add(urlContains);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Cache cache;
  late MapTileWarmer warmer;

  setUp(() async {
    final db = openMemoryDb();
    addTearDown(db.close);
    await EtagCacheStore.createSchema(db);
    cache = _Cache(EtagCacheStore(db));
    warmer = MapTileWarmer(cache, settleDelay: Duration.zero);
  });

  test('a null cache and an empty request do nothing', () async {
    final idle = MapTileWarmer(null);
    await idle.abandon(const []);
    await idle.release(const ['https://example/']);
    await idle.warmUrls(const []);
    await idle.discardWorkingSet('terrain');
  });

  test('an unsettled camera and a host-less client warm nothing', () async {
    await warmer.warmViewportAbsolute(
      urlFor: (z, x, y) => 'https://example/$z/$x/$y.png',
      south: double.nan,
      west: 120,
      north: 25,
      east: 122,
      zoom: 8,
      immediate: true,
    );
    await MapTileWarmer(cache).warmViewport(
      client: _NoHosts(),
      tier: ApiTier.lbStatic,
      pathFor: (z, x, y) => '/$z/$x/$y.png',
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: 8,
    );
    expect(cache.evicted, isEmpty);
  });

  test('a newer schedule drops the one still waiting to run', () async {
    cache.gate = Completer<void>();
    final first = warmer.warmUrls(
      ['https://example/a.png'],
      immediate: true,
      logLabel: 'radar',
    );
    await Future<void>.delayed(Duration.zero);
    final second = warmer.warmUrls(['https://example/b.png'], immediate: true);
    warmer.cancel();
    cache.gate!.complete();
    await first;
    await second;
    expect(cache.cancelled, isEmpty);
  });

  test(
    'changing the working set evicts what the new one does not want',
    () async {
      const frame = 'https://static.example/api/v2/tiles/radar/1700000000';
      await warmer.warmUrls(
        ['$frame/5/1/2.png', 'https://example/basemap/1.png'],
        immediate: true,
        logLabel: 'radar',
      );
      await warmer.warmUrls(
        ['https://example/only.png'],
        immediate: true,
        logLabel: 'radar',
      );
      expect(cache.evicted, isNotEmpty);

      await warmer.discardWorkingSet('default');
      await warmer.release(['https://example/']);
      expect(cache.cancelled, isNotEmpty);
      await warmer.abandon(['https://example/']);
      expect(cache.cancelled.length, greaterThan(1));
    },
  );

  test(
    'a schedule cancelled during its settle never reaches the cache',
    () async {
      final slow = MapTileWarmer(
        cache,
        settleDelay: const Duration(milliseconds: 30),
      );
      final pending = slow.warmUrls(['https://example/later.png']);
      slow.cancel();
      await pending;
      expect(cache.evicted, isEmpty);
    },
  );
}
