/// v5 meteor **typhoon** endpoints on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';

/// CWA typhoon datasets (005/002/003/001) — **API v5**
/// (`/api/v5/meteor/typhoon`).
///
/// **Cache-split dual host** (both on `core-tnn1`): a history URL ending in a
/// 10-digit second is immutable and served from `static.core-tnn1`
/// ([ApiTier.coreStaticExclusive], 1-year cache) — the `/{kind}/:time` snapshots
/// and `/images/:time` PNGs; everything else (the latest datasets, `/{kind}/list`,
/// `/geojson`, `/images/list`) is mutable and served from `api.core-tnn1`
/// ([ApiTier.coreExclusiveApi], ETag/304). Returns raw decoded JSON; the
/// repository maps it to domain models (geometry is `[lng, lat]`, times are Unix
/// seconds, missing is `null`).
class MeteorTyphoonApi {
  const MeteorTyphoonApi(this._client);

  final ApiClient _client;

  /// Latest datasets, `/list`s, `/geojson`, `/images/list` (mutable) live on
  /// `api.core-tnn1`.
  static const ApiTier _api = ApiTier.coreExclusiveApi;

  /// Timestamped history snapshots + PNGs (immutable) live on `static.core-tnn1`.
  static const ApiTier _static = ApiTier.coreStaticExclusive;

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
  Future<Map<String, dynamic>> getAt(TyphoonKind kind, int second) async =>
      (await _client.get(_static, '$_base/${kind.path}/$second'))
          as Map<String, dynamic>;

  /// Overlay GeoJSON `FeatureCollection` composed from potential + probability
  /// (v2-compatible); `features: []` when no cyclone is active.
  Future<Map<String, dynamic>> getGeojson() async =>
      (await _client.get(_api, '$_base/geojson')) as Map<String, dynamic>;

  /// Available track-image times (Unix seconds). **Not** delta-encoded — a plain
  /// `number[]` (the payload is tiny).
  Future<List<dynamic>> getImagesList() async =>
      (await _client.get(_api, '$_base/images/list')) as List<dynamic>;

  /// The concrete URL of the track-image PNG at [second] (`image/png`, from
  /// `static`). Handed out for direct fetch (like a tile URL), not decoded to a
  /// model; the server returns 404 when the image is absent.
  ///
  /// `https://static.core-tnn1.exptech.dev/api/v5/meteor/typhoon/images/<sec>`
  String imagesUrl(int second) =>
      '${_client.hostsFor(_static).first}$_base/images/$second';
}
