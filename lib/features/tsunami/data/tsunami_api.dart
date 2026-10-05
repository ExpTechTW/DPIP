/// CWA tsunami endpoints on the region-aware API client.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';

/// `/api/v1/cwa/tsunami` — the bulletin index, and `/…/{id}` for one bulletin.
///
/// **[ApiTier.coreApi], not `coreExclusiveApi`**: both core regions (`tyo1`
/// and `tnn1`) answer `/api/v1/cwa/tsunami` (verified 2026-10-05, index and
/// detail alike), so this is one of the multi-active endpoints and gets the
/// failover rather than being pinned to tpe1's neighbour for no reason.
class TsunamiApi {
  const TsunamiApi(this._client);

  final ApiClient _client;

  /// The index — `{ statistics, count, reports: [...] }`, newest first.
  Future<Map<String, dynamic>> getReports() async =>
      (await _client.get(ApiTier.coreApi, ApiPaths.tsunami))
          as Map<String, dynamic>;

  /// One bulletin in full. The index rows only carry the event summary; this is
  /// where `content` and the `data.area` tuples are.
  Future<Map<String, dynamic>> getReport(String id) async =>
      (await _client.get(ApiTier.coreApi, '${ApiPaths.tsunami}/$id'))
          as Map<String, dynamic>;
}
