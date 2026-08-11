/// Shared frame-keyed tile API for the v2 raster overlays (radar, satellite,
/// QPESUMS).
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/meteor_decode.dart';

/// Tile endpoints for one v2 raster overlay — radar / satellite / QPESUMS all
/// share the same shape, differing only in the URL path segment ([path]).
///
/// Everything is keyed by a Unix timestamp (seconds for radar/satellite,
/// milliseconds for QPESUMS); a frame id *is* the timestamp. The frame list is
/// delta-encoded (`[base, Δ, Δ, …]`) and served from `api.core-tnn1` with
/// ETag/304. Tiles are WebP on `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive]); [tileUrl] feeds MapLibre. Prefetch warms
/// SQLite + ambient under the same origin URL. Caching is **ETag-only**.
class FrameTileApi {
  const FrameTileApi(this._client, this.path);

  final ApiClient _client;

  /// The overlay's URL path segment: `radar`, `satellite`, or `qpesums`.
  final String path;

  /// The v2 frame list lives on `api.core-tnn1` (no region failover).
  static const ApiTier _listTier = ApiTier.coreExclusiveApi;

  /// v2 tiles live on `static.core-tnn1` (no region failover).
  static const ApiTier _tileTier = ApiTier.coreStaticExclusive;

  /// Available frame timestamps, **newest first**.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/tiles/<path>/list`
  Future<List<String>> getFrames() async => framesFromList(
    await _client.get(_listTier, '${ApiPaths.tiles}/$path/list') as List,
  );

  /// XYZ WebP raster tile URL template for a [frame] (a Unix timestamp).
  ///
  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/<path>/<ts>/{z}/{x}/{y}.webp`
  String tileUrl(String frame) =>
      '${_client.hostsFor(_tileTier).first}'
      '${ApiPaths.tiles}/$path/$frame/{z}/{x}/{y}.webp';

  /// Restores the delta-encoded list `[base, Δ, Δ, …]` to absolute timestamps
  /// and returns them **newest first** as strings (the frame id used by
  /// [tileUrl]). Empty in → empty out. Exposed for unit testing.
  static List<String> framesFromList(List<dynamic> deltas) => [
    for (final v in MeteorDecode.deltaSeconds(deltas).reversed) v.toString(),
  ];
}
