/// [DpmTilePrefetcher] is a thin, layer-parameterised call into the shared
/// [MapTileWarmer] spine: it fixes the region-pinned tier, builds the exact
/// `.mvt` path MapLibre's own baked style requests, and caps the warm at
/// [dpmSourceMaxZoom] rather than the warmer's own generic default.
///
/// Getting any of those wrong is invisible without a test: a wrong tier or
/// path warms keys nothing ever reads, so nothing errors — the viewport
/// simply falls back to MapLibre's own on-demand fetch, one tile slower, with
/// no signal that the warm was pointed at nothing. And giving every layer the
/// same working-set name would make switching from, say, `shelter` to `aed`
/// silently evict the layer you're still on — this pins that each layer gets
/// its own working set and log label, keyed off nothing but its own name.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/disaster_map/data/dpm_tile_prefetcher.dart';
import 'package:dpip/features/disaster_map/domain/dpm_tile_contract.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every [warmViewport]/[cancel] call instead of touching MapLibre or
/// the tile cache. Built on a `null`-cache [MapTileWarmer] — safe by that
/// class's own design, since every cache-touching method is then a no-op —
/// and every method [DpmTilePrefetcher] actually calls is overridden here, so
/// nothing falls through to the (harmless, but unobservable) real behaviour.
class _RecordingWarmer extends MapTileWarmer {
  _RecordingWarmer() : super(null);

  int cancelCalls = 0;
  final List<
    ({
      ApiClient client,
      ApiTier tier,
      String Function(int z, int x, int y) pathFor,
      double south,
      double west,
      double north,
      double east,
      double zoom,
      int maxZoom,
      String? logLabel,
      String workingSet,
    })
  >
  warmViewportCalls = [];

  @override
  void cancel() {
    cancelCalls++;
    super.cancel();
  }

  @override
  Future<void> warmViewport({
    required ApiClient client,
    required ApiTier tier,
    required String Function(int z, int x, int y) pathFor,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    int maxZoom = 16,
    int pad = 1,
    String? logLabel,
    String workingSet = 'default',
    bool immediate = false,
  }) async {
    warmViewportCalls.add((
      client: client,
      tier: tier,
      pathFor: pathFor,
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
      maxZoom: maxZoom,
      logLabel: logLabel,
      workingSet: workingSet,
    ));
  }
}

void main() {
  late ApiClient client;

  setUp(() {
    client = ApiClient(Dio(), RegionSelection(SettingsStore.inMemory({})));
  });

  test(
    'prefetch targets the static-exclusive tier and the dpm mvt path template',
    () async {
      final warmer = _RecordingWarmer();
      final prefetcher = DpmTilePrefetcher(client, warmer);

      await prefetcher.prefetch(
        layer: 'shelter',
        south: 21.9,
        west: 120.0,
        north: 25.3,
        east: 122.0,
        zoom: 12,
      );

      expect(warmer.warmViewportCalls, hasLength(1));
      final call = warmer.warmViewportCalls.single;
      expect(call.tier, ApiTier.coreStaticExclusive);
      expect(call.pathFor(10, 5, 3), '/api/v2/tiles/dpm/shelter/10/5/3.mvt');
      expect(call.south, 21.9);
      expect(call.west, 120.0);
      expect(call.north, 25.3);
      expect(call.east, 122.0);
      expect(call.zoom, 12.0);
      expect(call.maxZoom, dpmSourceMaxZoom.toInt());
      expect(call.logLabel, 'dpm-shelter');
      expect(call.workingSet, 'dpm-shelter');
    },
  );

  test('each layer gets its own working set, log label and path — one layer '
      'never collides with another', () async {
    final warmer = _RecordingWarmer();
    final prefetcher = DpmTilePrefetcher(client, warmer);

    await prefetcher.prefetch(
      layer: 'aed',
      south: 0,
      west: 0,
      north: 1,
      east: 1,
      zoom: 10,
    );
    await prefetcher.prefetch(
      layer: 'restroom',
      south: 0,
      west: 0,
      north: 1,
      east: 1,
      zoom: 10,
    );

    expect(warmer.warmViewportCalls.map((c) => c.workingSet), [
      'dpm-aed',
      'dpm-restroom',
    ]);
    expect(warmer.warmViewportCalls.map((c) => c.logLabel), [
      'dpm-aed',
      'dpm-restroom',
    ]);
    expect(warmer.warmViewportCalls.map((c) => c.pathFor(1, 1, 1)), [
      '/api/v2/tiles/dpm/aed/1/1/1.mvt',
      '/api/v2/tiles/dpm/restroom/1/1/1.mvt',
    ]);
  });

  test('cancel delegates to the shared warmer', () {
    final warmer = _RecordingWarmer();
    final prefetcher = DpmTilePrefetcher(client, warmer);

    prefetcher.cancel();

    expect(warmer.cancelCalls, 1);
  });
}
