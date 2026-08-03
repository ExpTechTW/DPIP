/// Disaster-prevention map (DPM) HTTP surface on `api.core-tnn1`.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Tile templates + JSON detail for `/api/v2/tiles/dpm/…`.
///
/// MVT tiles are fetched by MapLibre via [tileUrl]; detail GETs go through
/// [ApiClient] so ETag / gzip / errors stay consistent with the rest of the app.
class DisasterMapApi {
  const DisasterMapApi(this._client);

  final ApiClient _client;

  static const ApiTier _tier = ApiTier.coreExclusiveApi;

  /// `https://api.core-tnn1.exptech.dev/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt`
  String tileUrl(String layer) =>
      '${_client.hostsFor(_tier).first}'
      '/api/v2/tiles/dpm/$layer/{z}/{x}/{y}.mvt';

  /// `GET /api/v2/tiles/dpm/aed/{id}`
  Future<Map<String, dynamic>> getAedDetail(int id) async {
    final raw = await _client.get(_tier, '/api/v2/tiles/dpm/aed/$id');
    return Map<String, dynamic>.from(raw as Map);
  }
}
