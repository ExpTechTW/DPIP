/// Prefetches DPM MVT tiles through [AmbientPrefetcher] (ApiClient + ETag).
library;

import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/shared/map/ambient_prefetcher.dart';

/// Thin DPM wrapper over the shared ambient spine.
class DpmTilePrefetcher {
  DpmTilePrefetcher(this._ambient);

  final AmbientPrefetcher _ambient;

  static const ApiTier _tier = ApiTier.coreStaticExclusive;

  void cancel() => _ambient.cancel();

  Future<void> prefetch({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) => _ambient.prefetchViewport(
    tier: _tier,
    pathFor: (z, x, y) => '/api/v2/tiles/dpm/$layer/$z/$x/$y.mvt',
    south: south,
    west: west,
    north: north,
    east: east,
    zoom: zoom,
    maxZoom: 16,
    logLabel: 'dpm-$layer',
  );
}
