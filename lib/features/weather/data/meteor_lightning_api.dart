/// v5 meteor **lightning** endpoints on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Lightning-strike snapshots — **API v5** (`/api/v5/meteor/lightning`).
///
/// **Cache-split dual host** (both on `core-tnn1`): a history URL ending in a
/// 10-digit second is immutable and served from `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive], 1-year cache); everything else (latest, list)
/// is served from `api.core-tnn1` ([ApiTier.coreExclusiveApi], 1-second cache
/// with ETag/304). Lightning has no station directory; returns raw decoded JSON,
/// and the repository aligns the parallel arrays into domain models.
class MeteorLightningApi {
  const MeteorLightningApi(this._client);

  final ApiClient _client;

  /// Latest / list (mutable) live on `api.core-tnn1`.
  static const ApiTier _api = ApiTier.coreExclusiveApi;

  /// Timestamped history (immutable) lives on `static.core-tnn1`.
  static const ApiTier _static = ApiTier.coreStaticExclusive;

  static const String _base = '/api/v5/meteor/lightning';

  /// Latest field-array snapshot of recent strikes.
  Future<Map<String, dynamic>> getLatest() async =>
      (await _client.get(_api, _base)) as Map<String, dynamic>;

  /// History time list, delta-encoded seconds (`[base, Δ, …]`).
  Future<List<dynamic>> getList() async =>
      (await _client.get(_api, '$_base/list')) as List<dynamic>;

  /// Historical snapshot at [second] (10-digit Unix seconds) — from `static`.
  Future<Map<String, dynamic>> getAt(int second) async =>
      (await _client.get(_static, '$_base/$second')) as Map<String, dynamic>;
}
