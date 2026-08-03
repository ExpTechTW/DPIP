/// Disaster-prevention map (DPM) HTTP surface on `static.core-tnn1`.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Tile templates + JSON detail for `/api/v2/tiles/dpm/…`.
///
/// Both MVT tiles and AED detail live on **static** (`static.core-tnn1`), same
/// host pattern as radar/satellite tiles. MapLibre fetches [tileUrl] directly;
/// detail GETs go through [ApiClient] for ETag / gzip / errors.
class DisasterMapApi {
  const DisasterMapApi(this._client);

  final ApiClient _client;

  static const ApiTier _tier = ApiTier.coreStaticExclusive;

  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt`
  String tileUrl(String layer) =>
      '${_client.hostsFor(_tier).first}'
      '/api/v2/tiles/dpm/$layer/{z}/{x}/{y}.mvt';

  /// `GET /api/v2/tiles/dpm/aed/{id}`
  Future<Map<String, dynamic>> getAedDetail(int id) async {
    final raw = await _client.get(_tier, '/api/v2/tiles/dpm/aed/$id');
    return Map<String, dynamic>.from(raw as Map);
  }
}
