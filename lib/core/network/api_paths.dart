/// Wire path constants shared by the region-aware API clients and the ETag
/// interceptor, so the cache's URL markers can never drift from the calls.
library;

/// Single source of truth for the path segments that appear in both a feature's
/// API client and [EtagInterceptor]'s cache policy.
abstract final class ApiPaths {
  /// v2 raster / disaster overlay tiles root (`/api/v2/tiles/<layer>/…`).
  static const String tiles = '/api/v2/tiles';

  /// v1 wind-field binaries (`/api/v1/wind/<model>/<ts>.bin`) — the WND1
  /// grids that drive the particle animation over the wind tiles.
  static const String windV1 = '/api/v1/wind';

  /// Disaster-point tiles: `/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt`.
  static const String dpm = '/api/v2/tiles/dpm';

  /// v1 basemap vector tiles (`/api/v1/map/tiles/…`).
  static const String mapTilesV1 = '/api/v1/map/tiles/';

  /// Detailed Taiwan street/building vector tiles
  /// (`/api/v1/map/gsi/{z}/{x}/{y}.pbf`). The route name is legacy; the
  /// payload is OpenMapTiles data sourced from OpenStreetMap, not Japan GSI.
  static const String mapOsmV1 = '/api/v1/map/gsi/';

  /// v1 terrain vector tiles (`/api/v1/map/terrain/…`) — the static CDN's
  /// elevation mesh, same XYZ shape as [mapTilesV1].
  static const String mapTerrainV1 = '/api/v1/map/terrain/';

  /// Live EEW feed (with `?sse=1&compress=1` for the stream).
  static const String eew = '/api/v2/eq/eew';

  /// Live RTS feed (with `?sse=1&compress=1` for the stream).
  static const String rts = '/api/v2/trem/rts';

  /// Device location registration — `/api/v2/location/{platform}/{token}/…`.
  static const String location = '/api/v2/location/';

  /// Push notification config — `/api/v2/notify/{token}/…`.
  static const String notify = '/api/v2/notify/';
}
