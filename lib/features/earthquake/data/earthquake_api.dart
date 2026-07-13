import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Earthquake endpoints on the region-aware [ApiClient].
///
/// `rts` / `eew` fail over across the LB regions (tpe1, khh1); `report` /
/// `report/{id}` across the Core regions (tyo1, tnn1) — the redundancy is a
/// transport property carried by [ApiTier], not a module boundary. Returns raw
/// decoded JSON; the repository maps it to domain models.
class EarthquakeApi {
  const EarthquakeApi(this._client);

  final ApiClient _client;

  /// Latest real-time station (RTS) shaking data.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/trem/rts`
  Future<dynamic> getRtsRealtime() =>
      _client.get(ApiTier.lbApi, '/api/v2/trem/rts');

  /// Latest EEW list.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/eq/eew`
  Future<List<dynamic>> getEewRealtime() async =>
      (await _client.get(ApiTier.lbApi, '/api/v2/eq/eew')) as List<dynamic>;

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
}
