/// v5 meteor **weather** endpoints on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';

/// Weather station directory + observation snapshots — **API v5**
/// (`/api/v5/meteor/weather`).
///
/// The shared station / latest / list / history / trend surface lives in
/// [MeteorSnapshotApi] (same cache-split dual host contract); this class adds
/// the weather-only [getRealtime] and [getForecast] endpoints. Returns raw
/// decoded JSON; the repository decodes the field-arrays / delta-seconds into
/// domain models.
class MeteorWeatherApi {
  MeteorWeatherApi(this._client)
    : snapshots = MeteorSnapshotApi(_client, '/api/v5/meteor/weather');

  final ApiClient _client;

  /// The weather dataset's shared snapshot endpoints.
  final MeteorSnapshotApi snapshots;

  /// Nearest station to [latitude],[longitude] (the `:coords` = `lat,lng` path).
  /// Returns `{}` when the coordinate is outside Taiwan.
  Future<Map<String, dynamic>> getRealtime(
    double latitude,
    double longitude,
  ) async =>
      (await _client.get(
            _api,
            '/api/v5/meteor/weather/realtime/$latitude,$longitude',
          ))
          as Map<String, dynamic>;

  /// Township forecast for the 3-digit [code].
  Future<Map<String, dynamic>> getForecast(String code) async =>
      (await _client.get(_api, '/api/v5/meteor/weather/forecast/$code'))
          as Map<String, dynamic>;

  static const ApiTier _api = ApiTier.coreExclusiveApi;
}
