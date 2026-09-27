import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/sse_client.dart';
import 'package:dpip/core/network/sse_event.dart';

/// Earthquake endpoints on the region-aware [ApiClient].
///
/// The live feeds fail over across the LB regions (tpe1, khh1); reports and
/// the replay archives across the Core regions (tyo1, tnn1) — the redundancy is a
/// transport property carried by [ApiTier], not a module boundary. Returns raw
/// decoded JSON; the repository maps it to domain models.
class EarthquakeApi {
  const EarthquakeApi(this._client);

  final ApiClient _client;

  /// Opens the **TREM stream** carrying the RTS frames — one Server-Sent Events
  /// connection whose frames are named for their topic (`event: trem.rts.v1`)
  /// and carry base64-gzipped `rts.v1` JSON. No token: the public topics are
  /// anonymous.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v1/trem/sse?topics=trem.rts.v1[&mode=live]`
  ///
  /// [live] asks for every frame (~2 Hz). Without it the server is in its
  /// sleep mode and sends only the frames in which a station is alerting — the
  /// only ones anybody not watching the monitor needs, at a fraction of the
  /// traffic. A fresh stream per call, so the source reconnects by calling
  /// again and reads [live] anew each time.
  Stream<SseEvent> openTremSse({required bool live}) => HttpSseClient(_client)
      .connect(
        ApiTier.lbApi,
        ApiPaths.tremSse,
        query: {'topics': rtsTopic, if (live) 'mode': 'live'},
      );

  /// The TREM stream topic carrying RTS frames; also each frame's event name.
  static const String rtsTopic = 'trem.rts.v1';

  /// The archived `rts.v1` frame at [seconds] (Unix seconds, ten digits) —
  /// the same JSON the live topic carries, for replaying past shaking.
  ///
  /// `https://api.core-{tnn1,tyo1}.exptech.dev/api/v3/trem/rts/{seconds}`
  ///
  /// A second not archived yet — or no longer kept — answers 404. Each region
  /// archives the network on its own, and a second that has just passed can be
  /// on one region and not yet on the other.
  Future<Map<String, dynamic>> getRtsAt(int seconds) async =>
      (await _client.get(ApiTier.coreApi, '${ApiPaths.rtsArchive}/$seconds'))
          as Map<String, dynamic>;

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
