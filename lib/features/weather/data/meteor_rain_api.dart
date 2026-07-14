/// v5 meteor **rain** endpoints on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Rain station directory + accumulation snapshots + per-station trend — **API
/// v5** (`/api/v5/meteor/rain`).
///
/// **Cache-split dual host** (both on `core-tnn1`): a history URL ending in a
/// 10-digit second is immutable and served from `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive], 1-year cache); everything else (latest, list,
/// trend, station) is served from `api.core-tnn1` ([ApiTier.coreExclusiveApi],
/// 1-second cache with ETag/304). Returns raw decoded JSON; the repository
/// decodes the field-arrays / delta-seconds into domain models.
class MeteorRainApi {
  const MeteorRainApi(this._client);

  final ApiClient _client;

  /// Latest / list / directory / trend (mutable) live on `api.core-tnn1`.
  static const ApiTier _api = ApiTier.coreExclusiveApi;

  /// Timestamped history (immutable) lives on `static.core-tnn1`.
  static const ApiTier _static = ApiTier.coreStaticExclusive;

  static const String _base = '/api/v5/meteor/rain';

  /// Static station directory `{ code: {n,c,t,alt,lat,lon} }` (ETag-cached) —
  /// same shape as weather's, so the domain reuses `WeatherStation`.
  Future<Map<String, dynamic>> getStation() async =>
      (await _client.get(_api, '$_base/station')) as Map<String, dynamic>;

  /// Latest field-array snapshot.
  Future<Map<String, dynamic>> getLatest() async =>
      (await _client.get(_api, _base)) as Map<String, dynamic>;

  /// History time list, delta-encoded seconds (`[base, Δ, …]`).
  Future<List<dynamic>> getList() async =>
      (await _client.get(_api, '$_base/list')) as List<dynamic>;

  /// Historical snapshot at [second] (10-digit Unix seconds) — from `static`.
  Future<Map<String, dynamic>> getAt(int second) async =>
      (await _client.get(_static, '$_base/$second')) as Map<String, dynamic>;

  /// Per-station rainfall trend for [id] over [range] (`24h` | `7d`).
  Future<Map<String, dynamic>> getTrend(String id, String range) async =>
      (await _client.get(_api, '$_base/trend/$id', query: {'range': range}))
          as Map<String, dynamic>;
}
