import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/sse_client.dart';
import 'package:dpip/core/network/sse_event.dart';

/// Earthquake endpoints on the region-aware [ApiClient].
///
/// `rts` / `eew` fail over across the LB regions (tpe1, khh1); `report` /
/// `report/{id}` across the Core regions (tyo1, tnn1) — the redundancy is a
/// transport property carried by [ApiTier], not a module boundary. Returns raw
/// decoded JSON; the repository maps it to domain models.
class EarthquakeApi {
  const EarthquakeApi(this._client);

  final ApiClient _client;

  /// Latest real-time station (RTS) shaking data (one-shot snapshot).
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/trem/rts`
  Future<dynamic> getRtsRealtime() =>
      _client.get(ApiTier.lbApi, '/api/v2/trem/rts');

  /// Opens the **live** RTS feed as a Server-Sent Events stream — the transport
  /// the realtime channel runs on. A continuous ~1 Hz snapshot stream.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/trem/rts?sse=1&compress=1`
  ///
  /// `compress=1` streams the payload as `event: g` (base64-gzipped JSON, the
  /// same JSON [getRtsRealtime] returns) — decompressed in the realtime source.
  /// A fresh stream per call, so the source can reconnect by calling again.
  Stream<SseEvent> openRtsSse() => HttpSseClient(_client).connect(
    ApiTier.lbApi,
    '/api/v2/trem/rts',
    query: const {'sse': 1, 'compress': 1},
  );

  /// Latest EEW list (one-shot snapshot).
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/eq/eew`
  Future<List<dynamic>> getEewRealtime() async =>
      (await _client.get(ApiTier.lbApi, '/api/v2/eq/eew')) as List<dynamic>;

  /// Opens the **live** EEW feed as a Server-Sent Events stream — the transport
  /// the realtime channel runs on, replacing per-second polling with one
  /// server-pushed connection.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/eq/eew?sse=1&compress=1`
  ///
  /// `compress=1` streams the payload as `event: g` (base64-gzipped JSON, the
  /// same JSON [getEewRealtime] returns) — decompressed in the realtime source.
  /// A fresh stream per call, so the source can reconnect by calling again.
  Stream<SseEvent> openEewSse() => HttpSseClient(_client).connect(
    ApiTier.lbApi,
    '/api/v2/eq/eew',
    query: const {'sse': 1, 'compress': 1},
  );

  /// Latest earthquake reports including area `list` (no pagination filters).
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v1/eq/report?limit=`
  Future<List<dynamic>> getLatestReports({int limit = 1}) async =>
      (await _client.get(
            ApiTier.coreApi,
            '/api/v1/eq/report',
            query: {'limit': limit},
          ))
          as List<dynamic>;

  /// Paginated earthquake report list (no area `list`; includes `md5` / `int`).
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/report?limit=&page=`
  Future<List<dynamic>> getReportList({
    int limit = 50,
    int page = 1,
    int? minIntensity,
    int? maxIntensity,
    double? minMagnitude,
    double? maxMagnitude,
    double? minDepth,
    double? maxDepth,
    int? startTime,
    int? endTime,
    String? loc,
    String? city,
    int? cityMinInt,
    int? cityMaxInt,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'page': page,
      'minIntensity': ?minIntensity,
      'maxIntensity': ?maxIntensity,
      'minMagnitude': ?minMagnitude,
      'maxMagnitude': ?maxMagnitude,
      'minDepth': ?minDepth,
      'maxDepth': ?maxDepth,
      'startTime': ?startTime,
      'endTime': ?endTime,
      'loc': ?loc,
      'city': ?city,
      'cityMinInt': ?cityMinInt,
      'cityMaxInt': ?cityMaxInt,
    };
    return (await _client.get(
          ApiTier.coreApi,
          '/api/v2/eq/report',
          query: query,
        ))
        as List<dynamic>;
  }

  /// Full earthquake report by [reportId] (includes area `list`).
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/report/{reportId}`
  Future<dynamic> getReport(String reportId) =>
      _client.get(ApiTier.coreApi, '/api/v2/eq/report/$reportId');
}
