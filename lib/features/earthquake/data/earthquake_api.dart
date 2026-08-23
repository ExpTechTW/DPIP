import 'dart:convert';

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
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
  Future<dynamic> getRtsRealtime() => _client.get(ApiTier.lbApi, ApiPaths.rts);

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
    ApiPaths.rts,
    query: const {'sse': 1, 'compress': 1},
  );

  /// Historical RTS snapshot at [seconds] (Unix seconds) — same shape as
  /// [getRtsRealtime], for replaying past shaking instead of the live feed.
  ///
  /// **`legacyApi`, not `lbApi`:** verified by comparing responses at several
  /// offsets (2026-08-08) — `api.lb-{tpe1,khh1}` silently **ignores**
  /// `{seconds}` and returns the live snapshot regardless (its `time` matches
  /// the plain `/rts` response exactly, for every offset tried); only `api-1`
  /// actually returns a payload whose `time` tracks the requested second. A
  /// same-tier guess from `getEewAt`'s working case would have been wrong here.
  ///
  /// `https://api-1.exptech.dev/api/v2/trem/rts/{seconds}`
  Future<dynamic> getRtsAt(int seconds) async {
    final data = await _client.get(
      ApiTier.legacyApi,
      '${ApiPaths.rts}/$seconds',
    );
    // Verified 2026-08-09: unlike every other endpoint here (including the
    // bare `/trem/rts` and `/trem/station` on this same host), api-1 serves
    // *this* route's body as `text/plain`, so Dio's default transformer
    // doesn't auto-decode it — the caller gets a raw JSON string instead of
    // a Map. Decode it here so this method's return shape matches the rest
    // of [EarthquakeApi] regardless of the host's content-type quirk.
    //
    // Inline on purpose, not an isolate: the snapshot is ~5 KB (~111
    // stations, re-measured 2026-08-24 against api-1), so the decode is tens
    // of microseconds even at replay's 1 Hz — an isolate spawn would cost
    // more than it saves.
    return data is String ? jsonDecode(data) : data;
  }

  /// Latest EEW list (one-shot snapshot).
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/eq/eew`
  Future<List<dynamic>> getEewRealtime() async =>
      (await _client.get(ApiTier.lbApi, ApiPaths.eew)) as List<dynamic>;

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
    ApiPaths.eew,
    query: const {'sse': 1, 'compress': 1},
  );

  /// Historical EEW list at [seconds] (Unix seconds) — same shape as
  /// [getEewRealtime], for replaying a past event instead of the live feed.
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/eew/{seconds}`
  Future<List<dynamic>> getEewAt(int seconds) async =>
      (await _client.get(ApiTier.coreApi, '${ApiPaths.eew}/$seconds'))
          as List<dynamic>;

  /// Paginated earthquake report list (no area `list`; includes `md5` / `int`).
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/report`
  ///
  /// [startTime] / [endTime] are `YYYY-MM-DD` (Asia/Taipei). Defaults and
  /// unknown keys are stripped server-side (302 to a canonical query).
  Future<List<dynamic>> getReportList({
    int limit = 50,
    int page = 1,
    int? minIntensity,
    int? maxIntensity,
    double? minMagnitude,
    double? maxMagnitude,
    double? minDepth,
    double? maxDepth,
    String? startTime,
    String? endTime,
    String? sort,
    String? order,
    String? city,
    int? cityMinInt,
    int? cityMaxInt,
  }) async {
    final query = <String, dynamic>{
      // Omit page=1 / sort=time / order=desc so the URL matches the server's
      // canonical form and ETag/cache hit more often.
      'limit': limit,
      if (page != 1) 'page': page,
      'minIntensity': ?minIntensity,
      'maxIntensity': ?maxIntensity,
      'minMagnitude': ?minMagnitude,
      'maxMagnitude': ?maxMagnitude,
      'minDepth': ?minDepth,
      'maxDepth': ?maxDepth,
      'startTime': ?startTime,
      'endTime': ?endTime,
      if (sort != null && sort != 'time') 'sort': sort,
      if (order != null && order != 'desc') 'order': order,
      'city': ?city,
      'cityMinInt': ?cityMinInt,
      'cityMaxInt': ?cityMaxInt,
    };
    return (await _client.get(
      ApiTier.coreApi,
      '/api/v2/eq/report',
      query: query,
    )) as List<dynamic>;
  }

  /// Full earthquake report by [reportId] (includes area `list`).
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/report/{reportId}`
  Future<dynamic> getReport(String reportId) =>
      _client.get(ApiTier.coreApi, '/api/v2/eq/report/$reportId');
}
