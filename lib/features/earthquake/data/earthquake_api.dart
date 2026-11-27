import 'package:dio/dio.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/stale_if_error.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input_v3.dart';

/// Earthquake endpoints on the region-aware [ApiClient].
///
/// The live feeds fail over across the LB regions (tpe1, khh1); reports and
/// the replay archives across the Core regions (tyo1, tnn1) — the redundancy is a
/// transport property carried by [ApiTier], not a module boundary. The
/// repository maps response bodies to domain models.
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

  /// Whether the replay archives still hold the moment at [seconds].
  ///
  /// Two feeds make a replay: the EEW alerts around the event and the RTS
  /// frames from its start. They are pruned on different schedules, and the
  /// EEW history is the longer-lived of the two (an old event can still have
  /// alerts to replay and no shaking left to draw), so an EEW hit is enough.
  ///
  /// EEW alerts trail the origin by a few seconds, so the EEW probe looks
  /// just past it rather than at the replay's lead-in second. A 404 from the
  /// RTS archive is a "no such second", not a fault — what it retains moves
  /// with time, which is exactly why this asks instead of comparing against
  /// a fixed date. Every other failure is rethrown.
  Future<bool> hasReplayAt(int seconds) async {
    if (await _hasEewAt(seconds + 60)) return true;
    try {
      await getRtsAt(seconds);
      return true;
    } on DioException catch (error) {
      if (_isMissing(error)) return false;
      rethrow;
    }
  }

  /// An EEW point query, with the archive's two "nothing there" answers —
  /// 404, and 400 for a timestamp too old to be ten digits — folded to empty.
  Future<bool> _hasEewAt(int seconds) async {
    try {
      return (await getEewAt(seconds)).isNotEmpty;
    } on DioException catch (error) {
      if (_isMissing(error)) return false;
      rethrow;
    }
  }

  /// Whether [error] is the archive saying it has nothing for that second,
  /// rather than a transport/server fault.
  static bool _isMissing(DioException error) {
    final code = error.response?.statusCode;
    return code == 404 || code == 400;
  }

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
  Future<BytePayload> getReport(String reportId) => _client.getBytes(
    ApiTier.coreApi,
    '/api/v2/eq/report/${Uri.encodeComponent(reportId)}',
    requireOriginBody: true,
    validateCacheBody: (bytes) {
      final snapshot = CoreEarthquakeReportSnapshot.decode(
        bytes,
        requestedReportId: reportId,
      );
      try {
        adaptEarthquakeShareSnapshotV3(snapshot);
      } on EarthquakeReportSourceException catch (error) {
        if (error.code != EarthquakeReportSourceError.unsupportedProfile) {
          rethrow;
        }
        // Historical detail is still useful as an ordinary report, with its
        // existing display schema. V3 eligibility is always checked separately.
        EarthquakeReportSnapshot.decode(bytes, requestedReportId: reportId);
      }
    },
  );
}
