/// Disaster-prevention map (DPM) HTTP surface on `static.core-tnn1`.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';

/// Tile templates + JSON detail for `/api/v2/tiles/dpm/…`.
///
/// Detail GETs go through [ApiClient] for ETag / gzip / errors. MVT tiles keep
/// the HTTPS [tileUrl] template in the style and are fetched by MapLibre
/// itself, served from the app's tile store through the Dart bridge;
/// `DpmTilePrefetcher` warms the viewport ahead of that.
class DisasterMapApi {
  const DisasterMapApi(this._client);

  final ApiClient _client;

  static const ApiTier _tier = ApiTier.coreStaticExclusive;

  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt`
  String tileUrl(String layer) =>
      '${_client.hostsFor(_tier).first}'
      '${ApiPaths.dpm}/$layer/{z}/{x}/{y}.mvt';

  Future<Map<String, dynamic>> getAedDetail(int id) => _detail('aed', id);

  Future<Map<String, dynamic>> getRestroomDetail(int id) =>
      _detail('restroom', id);

  Future<Map<String, dynamic>> getShelterDetail(int id) =>
      _detail('shelter', id);

  /// `GET /api/v2/tiles/dpm/<kind>/{id}` — the three venue detail endpoints
  /// share shape and response decoding.
  Future<Map<String, dynamic>> _detail(String kind, int id) async {
    final raw = await _client.get(_tier, '${ApiPaths.dpm}/$kind/$id');
    return Map<String, dynamic>.from(raw as Map);
  }
}
