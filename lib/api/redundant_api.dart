import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Endpoints **with** multi-active redundancy.
///
/// LB-tier services (Taiwan edge realtime/broadcast data) and Core services
/// present in both core regions. Every request fails over across regions
/// automatically via [ApiClient].
///
/// Methods return raw decoded JSON; feature data layers map it to domain
/// models. Paths omit the `api` prefix because it is part of the host
/// subdomain.
class RedundantApi {
  const RedundantApi(this._client);

  final ApiClient _client;

  // ── Realtime seismic (LB) ────────────────────────────────────────────────

  /// Latest real-time station (RTS) shaking data.
  Future<dynamic> getRtsRealtime() =>
      _client.get(ApiTier.lbApi, '/v2/trem/rts');

  /// RTS data at [timeMs] (ms since epoch).
  Future<dynamic> getRtsAt(int timeMs) =>
      _client.get(ApiTier.lbApi, '/v2/trem/rts/${timeMs ~/ 1000}');

  /// Latest EEW list.
  Future<List<dynamic>> getEewRealtime() async =>
      (await _client.get(ApiTier.lbApi, '/v2/eq/eew')) as List<dynamic>;

  // ── Earthquake reports / EEW history (Core, both regions) ────────────────

  /// Full earthquake report by [reportId].
  Future<dynamic> getReport(String reportId) =>
      _client.get(ApiTier.coreApi, '/v2/eq/report/$reportId');

  /// Paginated earthquake report list.
  Future<List<dynamic>> getReportList({int limit = 50, int page = 1}) async =>
      (await _client.get(
            ApiTier.coreApi,
            '/v2/eq/report',
            query: {'limit': limit, 'page': page},
          ))
          as List<dynamic>;

  /// EEW list at [timeMs] (ms since epoch).
  Future<List<dynamic>> getEewAt(int timeMs) async =>
      (await _client.get(ApiTier.coreApi, '/v2/eq/eew/${timeMs ~/ 1000}'))
          as List<dynamic>;

  // ── Stations / radar / meteor stations (LB) ──────────────────────────────

  /// TREM station map, keyed by station ID.
  Future<dynamic> getStations() =>
      _client.get(ApiTier.lbApi, '/v1/trem/station');

  /// Available radar tile timestamps.
  Future<List<dynamic>> getRadarList() async =>
      (await _client.get(ApiTier.lbApi, '/v1/tiles/radar/list'))
          as List<dynamic>;

  /// Meteor station data for [id].
  Future<dynamic> getMeteorStation(String id) =>
      _client.get(ApiTier.lbApi, '/v2/meteor/station/$id');

  // ── Weather / rain / lightning / typhoon (LB) ────────────────────────────

  /// Available weather timestamps.
  Future<List<dynamic>> getWeatherList() async =>
      (await _client.get(ApiTier.lbApi, '/v2/meteor/weather/list'))
          as List<dynamic>;

  /// Weather station data at [time].
  Future<dynamic> getWeather(String time) =>
      _client.get(ApiTier.lbApi, '/v2/meteor/weather/$time');

  /// Realtime weather at the given coordinates (2-decimal precision).
  Future<dynamic> getWeatherRealtime(double lat, double lon) => _client.get(
    ApiTier.lbApi,
    '/v3/weather/realtime/${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',
  );

  /// Weather forecast for [region].
  Future<dynamic> getWeatherForecast(String region) =>
      _client.get(ApiTier.lbApi, '/v3/weather/forecast/$region');

  /// Available rain timestamps.
  Future<List<dynamic>> getRainList() async =>
      (await _client.get(ApiTier.lbApi, '/v2/meteor/rain/list'))
          as List<dynamic>;

  /// Rain station data at [time].
  Future<dynamic> getRain(String time) =>
      _client.get(ApiTier.lbApi, '/v2/meteor/rain/$time');

  /// Available lightning timestamps.
  Future<List<dynamic>> getLightningList() async =>
      (await _client.get(ApiTier.lbApi, '/v2/meteor/lightning/list'))
          as List<dynamic>;

  /// Lightning data at [time].
  Future<dynamic> getLightning(String time) =>
      _client.get(ApiTier.lbApi, '/v2/meteor/lightning/$time');

  /// Available typhoon image timestamps.
  Future<List<dynamic>> getTyphoonImagesList() async =>
      (await _client.get(ApiTier.lbApi, '/v2/meteor/typhoon/images/list'))
          as List<dynamic>;

  /// Typhoon track GeoJSON.
  Future<dynamic> getTyphoonGeojson() =>
      _client.get(ApiTier.lbApi, '/v2/meteor/typhoon/geojson');

  // ── Tsunami (LB) ─────────────────────────────────────────────────────────

  /// Tsunami detail by [id].
  Future<dynamic> getTsunami(String id) =>
      _client.get(ApiTier.lbApi, '/v1/tsunami/$id');

  /// Tsunami event id list.
  Future<List<dynamic>> getTsunamiList() async =>
      (await _client.get(ApiTier.lbApi, '/v1/tsunami/list')) as List<dynamic>;

  // ── DPIP realtime / history (LB) ─────────────────────────────────────────

  /// Realtime event list.
  Future<List<dynamic>> getRealtimeList() async =>
      (await _client.get(ApiTier.lbApi, '/v1/dpip/realtime/list'))
          as List<dynamic>;

  /// Historical event list.
  Future<List<dynamic>> getHistoryList() async =>
      (await _client.get(ApiTier.lbApi, '/v1/dpip/history/list'))
          as List<dynamic>;

  /// Realtime events for [region].
  Future<List<dynamic>> getRealtimeRegion(String region) async =>
      (await _client.get(ApiTier.lbApi, '/v1/dpip/realtime/$region'))
          as List<dynamic>;

  /// Historical events for [region].
  Future<List<dynamic>> getHistoryRegion(String region) async =>
      (await _client.get(ApiTier.lbApi, '/v1/dpip/history/$region'))
          as List<dynamic>;

  /// Event detail by [id].
  Future<dynamic> getEvent(String id) =>
      _client.get(ApiTier.lbApi, '/v1/dpip/event/$id');

  // ── Announcements (LB) ───────────────────────────────────────────────────

  /// Current announcements.
  Future<List<dynamic>> getAnnouncements() async =>
      (await _client.get(ApiTier.lbApi, '/v1/dpip/announcement'))
          as List<dynamic>;

  // ── Time sync / diagnostics (LB) ─────────────────────────────────────────

  /// Server time (ms since epoch) with NTP-style round-trip offset correction.
  Future<int> getNtp() async {
    final t1 = DateTime.now().microsecondsSinceEpoch;
    final res = await _client.request(
      ApiTier.lbApi,
      '/ntp',
      options: Options(responseType: ResponseType.plain),
    );
    final t4 = DateTime.now().microsecondsSinceEpoch;

    final t2 = _microsFromHeader(res.headers.value('x-ntp-t2'));
    final t3 = _microsFromHeader(res.headers.value('x-ntp-t3'));
    if (t2 != null && t3 != null) {
      final offset = ((t2 - t1) + (t3 - t4)) / 2;
      return (t3 + offset).toInt() ~/ 1000;
    }
    return double.parse(res.data as String).toInt();
  }

  /// Reports network diagnostics to the server.
  Future<void> sendNetworkInfo({
    required String? ip,
    required String? isp,
    required List<int?> status,
    required List<int?> statusDev,
  }) async {
    await _client.post(
      ApiTier.lbApi,
      '/v1/dpip/networkInfo',
      data: {'ip': ip, 'isp': isp, 'status': status, 'status_dev': statusDev},
    );
  }

  static int? _microsFromHeader(String? value) =>
      value != null ? (double.parse(value) * 1000).toInt() : null;
}
