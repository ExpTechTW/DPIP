import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Satellite IR cloud (衛星雲圖) tile endpoints — **API v2**.
///
/// Everything is keyed by 10-digit Unix **seconds**; a frame id *is* the second.
/// The frame list is delta-encoded (`[baseSec, Δ, Δ, …]`) and served from
/// `api.core-tnn1` with ETag/304. Tiles are WebP on `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive]), fetched directly by MapLibre. Same dual-host
/// + delta-list shape as the v2 radar feed.
class SatelliteApi {
  const SatelliteApi(this._client);

  final ApiClient _client;

  /// The v2 frame list lives on `api.core-tnn1` (no region failover).
  static const ApiTier _listTier = ApiTier.coreExclusiveApi;

  /// v2 tiles live on `static.core-tnn1` (no region failover).
  static const ApiTier _tileTier = ApiTier.coreStaticExclusive;

  /// Available satellite frame seconds, **newest first**.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/tiles/satellite/list`
  Future<List<String>> getFrames() async => framesFromList(
    await _client.get(_listTier, '/api/v2/tiles/satellite/list') as List,
  );

  /// XYZ WebP raster tile URL template for a satellite [frame] (a Unix second).
  ///
  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/satellite/<sec>/{z}/{x}/{y}.webp`
  String tileUrl(String frame) =>
      '${_client.hostsFor(_tileTier).first}'
      '/api/v2/tiles/satellite/$frame/{z}/{x}/{y}.webp';

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
