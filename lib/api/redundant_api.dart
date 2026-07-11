import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Endpoints **with** multi-active redundancy — the only services replicated
/// across regions. Every request fails over across its regions via [ApiClient].
///
/// Verified availability (curl, 2026-07):
/// - `rts` / `station`: LB regions (tpe1, khh1)
/// - `eew`: every region (both LB and Core)
/// - `report` / `report/{id}`: Core regions (tyo1, tnn1)
///
/// Methods return raw decoded JSON; feature data layers map it to domain models.
class RedundantApi {
  const RedundantApi(this._client);

  final ApiClient _client;

  /// Latest real-time station (RTS) shaking data.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/trem/rts`
  Future<dynamic> getRtsRealtime() =>
      _client.get(ApiTier.lbApi, '/api/v2/trem/rts');

  /// Latest EEW list (replicated in every region).
  ///
  /// `https://api.{lb-tpe1,lb-khh1,core-tyo1,core-tnn1}.exptech.dev/api/v2/eq/eew`
  Future<List<dynamic>> getEewRealtime() async =>
      (await _client.get(ApiTier.globalApi, '/api/v2/eq/eew')) as List<dynamic>;

  /// Paginated earthquake report list.
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/report?limit=&page=`
  Future<List<dynamic>> getReportList({int limit = 50, int page = 1}) async =>
      (await _client.get(
            ApiTier.coreApi,
            '/api/v2/eq/report',
            query: {'limit': limit, 'page': page},
          ))
          as List<dynamic>;

  /// Full earthquake report by [reportId].
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/report/{reportId}`
  Future<dynamic> getReport(String reportId) =>
      _client.get(ApiTier.coreApi, '/api/v2/eq/report/$reportId');

  /// TREM station map, keyed by station ID.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v1/trem/station`
  Future<dynamic> getStations() =>
      _client.get(ApiTier.lbApi, '/api/v1/trem/station');
}
