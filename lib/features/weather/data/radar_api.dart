import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Radar echo (雷達回波) tile endpoints — **API v2**.
///
/// Everything is keyed by 10-digit Unix **seconds**; a frame id *is* the second.
/// The frame list is delta-encoded (`[baseSec, Δ, Δ, …]`) and served from
/// `api.core-tnn1` with ETag/304 — revalidation and gzip-9 storage are handled
/// transparently by the global ETag cache, so the list costs ~one round trip per
/// change. Tiles are WebP served from a **different host**, `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive]), fetched directly by MapLibre ([tileUrl]
/// hands out a concrete host URL); the server sets `Cache-Control: max-age=300`,
/// so scrubbing the timeline reuses MapLibre's own tile cache.
class RadarApi {
  const RadarApi(this._client);

  final ApiClient _client;

  /// The v2 frame list lives on `api.core-tnn1` (no region failover).
  static const ApiTier _listTier = ApiTier.coreExclusiveApi;

  /// v2 tiles live on `static.core-tnn1` (no region failover).
  static const ApiTier _tileTier = ApiTier.coreStaticExclusive;

  /// Available radar frame seconds, **newest first**.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/tiles/radar/list`
  Future<List<String>> getFrames() async => framesFromList(
    await _client.get(_listTier, '/api/v2/tiles/radar/list') as List,
  );

  /// XYZ WebP raster tile URL template for a radar [frame] (a Unix second).
  ///
  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/radar/<sec>/{z}/{x}/{y}.webp`
  String tileUrl(String frame) =>
      '${_client.hostsFor(_tileTier).first}'
      '/api/v2/tiles/radar/$frame/{z}/{x}/{y}.webp';

  /// Restores the delta-encoded list `[baseSec, Δ, Δ, …]` to absolute seconds
  /// and returns them **newest first** as strings (the frame id used by
  /// [tileUrl]). Empty in → empty out. Exposed for unit testing.
  static List<String> framesFromList(List<dynamic> deltas) {
    if (deltas.isEmpty) return const [];
    var second = (deltas.first as num).toInt();
    final seconds = <int>[second];
    for (var i = 1; i < deltas.length; i++) {
      second += (deltas[i] as num).toInt();
      seconds.add(second);
    }
    return [for (final s in seconds.reversed) s.toString()];
  }
}
