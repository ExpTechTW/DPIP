/// v5 meteor snapshot endpoints shared by the weather / rain / lightning
/// repositories on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// The snapshot surface every meteor dataset shares: a station directory
/// (weather / rain only), latest + historical field-array snapshots, the delta-
/// encoded history time list, and a per-station trend (weather / rain only).
///
/// **Cache-split dual host** (both on `core-tnn1`): a history URL ending in a
/// 10-digit second is immutable and served from `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive], 1-year cache); everything else (latest, list,
/// trend, station) is served from `api.core-tnn1` ([ApiTier.coreExclusiveApi],
/// 1-second cache with ETag/304). Returns raw decoded JSON; the repository
/// decodes the field-arrays / delta-seconds into domain models.
class MeteorSnapshotApi {
  const MeteorSnapshotApi(this._client, this._base);

  final ApiClient _client;

  /// The dataset root path (e.g. `/api/v5/meteor/weather`).
  final String _base;

  /// Latest / list / directory / trend (mutable) live on `api.core-tnn1`.
  static const ApiTier _api = ApiTier.coreExclusiveApi;

  /// Timestamped history (immutable) lives on `static.core-tnn1`.
  static const ApiTier _static = ApiTier.coreStaticExclusive;

  /// Static station directory `{ code: {n,c,t,alt,lat,lon} }` (ETag-cached) —
  /// same shape for weather and rain.
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

  /// Per-station trend for [id] over [range] (`24h` | `7d`).
  Future<Map<String, dynamic>> getTrend(String id, String range) async =>
      (await _client.get(_api, '$_base/trend/$id', query: {'range': range}))
          as Map<String, dynamic>;
}
