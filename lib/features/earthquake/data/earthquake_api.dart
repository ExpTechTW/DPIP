import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/stale_if_error.dart';

/// Earthquake endpoints on the region-aware [ApiClient].
///
/// The live feeds fail over across the LB regions (tpe1, khh1); reports and
/// the replay archives across the Core regions (tyo1, tnn1) — the redundancy is a
/// transport property carried by [ApiTier], not a module boundary. Returns raw
/// decoded JSON; the repository maps it to domain models.
class EarthquakeApi {
  const EarthquakeApi(this._client);

  final ApiClient _client;

  /// The shared-stream topic carrying RTS frames (`SseMux`); also each
  /// frame's event name. Has a sleep mode: without `mode=live` the server
  /// sends only the frames in which a station is alerting.
  static const String rtsTopic = 'trem.rts.v1';

  /// The shared-stream topic carrying the live EEW list (`SseMux`); also each
  /// frame's event name. Every frame is the whole list [getEewRealtime]
  /// returns — a snapshot that replaces the last one, never a delta — and the
  /// server sends the current one as soon as a connection opens.
  static const String eewTopic = 'eq.eew.v1';

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

  /// Latest EEW list (one-shot snapshot) — what the live feed polls while
  /// its stream is down.
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v2/eq/eew`
  Future<List<dynamic>> getEewRealtime() async =>
      (await _client.get(ApiTier.lbApi, ApiPaths.eew)) as List<dynamic>;

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
  ///
  /// Stale-if-error ([ApiClientStaleIfError.getOrSaved]): offline, the page
  /// saved last time comes back marked as a saved copy. Past reports do not
  /// change, so an old page is still a true one — it may only be missing the
  /// newest, which the marker tells the reader.
  Future<Fetched<List<dynamic>>> getReportList({
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
    final fetched = await _client.getOrSaved(
      ApiTier.coreApi,
      '/api/v2/eq/report',
      query: query,
    );
    return (data: fetched.data as List<dynamic>, stale: fetched.stale);
  }

  /// Full earthquake report by [reportId] (includes area `list`).
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/eq/report/{reportId}`
  Future<dynamic> getReport(String reportId) =>
      _client.get(ApiTier.coreApi, '/api/v2/eq/report/$reportId');
}
