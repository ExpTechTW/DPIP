/// v5 meteor **typhoon** endpoints on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';

/// CWA typhoon datasets (005/002/003/001) — **API v5**
/// (`/api/v5/meteor/typhoon`).
///
/// **Cache-split dual host, on both core regions**: a history URL ending in a
/// 10-digit second is immutable and served from `static.core-{tyo1,tnn1}`
/// ([ApiTier.coreStatic], 1-year cache) — the `/{kind}/:time` snapshots;
/// everything else (the latest datasets, `/{kind}/list`) is mutable and served
/// from `api.core-{tyo1,tnn1}` ([ApiTier.coreApi], ETag/304). Both regions
/// answer every v5 typhoon path (verified 2026-11-28), so a request goes to the
/// selected region and fails over to the other one.
/// Returns raw decoded JSON; the repository maps it to domain models
/// (geometry is `[lng, lat]`, times are Unix seconds, missing is `null`).
///
/// The map overlay is built client-side from typed payloads (`/track`,
/// `/potential`, `/probability`, `/`) — `/geojson` is not fetched.
class MeteorTyphoonApi {
  const MeteorTyphoonApi(this._client);

  final ApiClient _client;

  /// Latest datasets and `/list`s (mutable) live on `api.core-*`.
  static const ApiTier _api = ApiTier.coreApi;

  /// Timestamped history snapshots (immutable) live on `static.core-*`.
  static const ApiTier _static = ApiTier.coreStatic;

  static const String _base = '/api/v5/meteor/typhoon';

  /// In-progress cyclone index (`GET /`).
  Future<Map<String, dynamic>> getCyclones() async =>
      (await _client.get(_api, _base)) as Map<String, dynamic>;

  /// Latest track dataset (005).
  Future<Map<String, dynamic>> getTrack() async =>
      (await _client.get(_api, '$_base/track')) as Map<String, dynamic>;

  /// Latest track-potential dataset (002).
  Future<Map<String, dynamic>> getPotential() async =>
      (await _client.get(_api, '$_base/potential')) as Map<String, dynamic>;

  /// Latest strike-probability dataset (003).
  Future<Map<String, dynamic>> getProbability() async =>
      (await _client.get(_api, '$_base/probability')) as Map<String, dynamic>;

  /// Latest warning bulletin (001).
  Future<Map<String, dynamic>> getWarning() async =>
      (await _client.get(_api, '$_base/warning')) as Map<String, dynamic>;

  /// History time list for [kind], delta-encoded seconds (`[base, Δ, …]`).
  Future<List<dynamic>> getList(TyphoonKind kind) async =>
      (await _client.get(_api, '$_base/${kind.path}/list')) as List<dynamic>;

  /// Historical [kind] snapshot at [second] (10-digit Unix seconds) — from
  /// `static`; the shape matches the kind's latest endpoint (404 when absent).
  ///
  /// Each region keeps its own history, so a 404 asks the other region before
  /// it is taken as the answer (see `MeteorSnapshotApi.getAt`).
  Future<Map<String, dynamic>> getAt(TyphoonKind kind, int second) async =>
      (await _client.get(
        _static,
        '$_base/${kind.path}/$second',
        notFoundFailsOver: true,
      )) as Map<String, dynamic>;
}
