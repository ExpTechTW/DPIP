import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// QPESUMS next-1-hour precipitation forecast (未來一小時降水預報) tile
/// endpoints — **API v2**, region topology.
///
/// Everything is keyed by 13-digit Unix **milliseconds**; a frame id *is* the
/// millisecond. The frame list is delta-encoded (`[baseMs, Δ, Δ, …]`) and
/// served from `api.core-tnn1`; tiles are WebP on `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive]); [tileUrl] feeds MapLibre. Same dual-host +
/// delta-list shape as the v2 radar/satellite tiles.
class QpesumsApi {
  const QpesumsApi(this._client);

  final ApiClient _client;

  /// The v2 frame list lives on `api.core-tnn1` (no region failover).
  static const ApiTier _listTier = ApiTier.coreExclusiveApi;

  /// v2 tiles live on `static.core-tnn1` (no region failover).
  static const ApiTier _tileTier = ApiTier.coreStaticExclusive;

  /// Available forecast frame milliseconds, **newest first**.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/tiles/qpesums/list`
  Future<List<String>> getFrames() async => framesFromList(
    await _client.get(_listTier, '/api/v2/tiles/qpesums/list') as List,
  );

  /// XYZ WebP raster tile URL template for a QPESUMS [frame] (a Unix
  /// millisecond).
  ///
  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/qpesums/<ms>/{z}/{x}/{y}.webp`
  String tileUrl(String frame) =>
      '${_client.hostsFor(_tileTier).first}'
      '/api/v2/tiles/qpesums/$frame/{z}/{x}/{y}.webp';

  /// Restores the delta-encoded list `[baseMs, Δ, Δ, …]` to absolute
  /// milliseconds and returns them **newest first** as strings (the frame id
  /// used by [tileUrl]). Empty in → empty out. Exposed for unit testing.
  static List<String> framesFromList(List<dynamic> deltas) {
    if (deltas.isEmpty) return const [];
    var millis = (deltas.first as num).toInt();
    final values = <int>[millis];
    for (var i = 1; i < deltas.length; i++) {
      millis += (deltas[i] as num).toInt();
      values.add(millis);
    }
    return [for (final v in values.reversed) v.toString()];
  }
}
