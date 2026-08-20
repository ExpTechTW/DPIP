/// Warms DPM MVT viewport tiles into MapLibre's tile memory.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';

/// Thin DPM wrapper over the shared warm spine ([MapTileWarmer]).
class DpmTilePrefetcher {
  DpmTilePrefetcher(this._client, this._warmer);

  final ApiClient _client;
  final MapTileWarmer _warmer;

  static const ApiTier _tier = ApiTier.coreStaticExclusive;

  void cancel() => _warmer.cancel();

  Future<void> prefetch({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) => _warmer.warmViewport(
    client: _client,
    tier: _tier,
    pathFor: (z, x, y) => '${ApiPaths.dpm}/$layer/$z/$x/$y.mvt',
    south: south,
    west: west,
    north: north,
    east: east,
    zoom: zoom,
    maxZoom: 16,
    logLabel: 'dpm-$layer',
    workingSet: 'dpm-$layer',
  );
}
