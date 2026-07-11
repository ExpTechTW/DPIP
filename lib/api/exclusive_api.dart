import 'package:dio/dio.dart';
import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Endpoints **without** multi-active redundancy — served only from
/// `core-tnn1`. There is no failover: if `tnn1` is unavailable, these fail.
///
/// This is every service except the five multi-active ones in [RedundantApi].
/// All URLs are `https://api.core-tnn1.exptech.dev/api/...`. Methods return raw
/// decoded JSON; feature data layers map it to domain models.
class ExclusiveApi {
  const ExclusiveApi(this._client);

  final ApiClient _client;

  // ── Seismic history ──────────────────────────────────────────────────────

  /// RTS data at [timeMs] (ms since epoch).
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/trem/rts/{sec}`
  Future<dynamic> getRtsAt(int timeMs) => _client.get(
    ApiTier.coreExclusiveApi,
    '/api/v2/trem/rts/${timeMs ~/ 1000}',
  );

  /// EEW list at [timeMs] (ms since epoch).
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/eq/eew/{sec}`
  Future<List<dynamic>> getEewAt(int timeMs) async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v2/eq/eew/${timeMs ~/ 1000}',
          ))
          as List<dynamic>;

  // ── Meteor stations / radar ──────────────────────────────────────────────

  /// Meteor station data for [id].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/station/{id}`
  Future<dynamic> getMeteorStation(String id) =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v2/meteor/station/$id');

  /// Available radar tile timestamps.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/tiles/radar/list`
  Future<List<dynamic>> getRadarList() async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v1/tiles/radar/list'))
          as List<dynamic>;

  // ── Weather / rain / lightning / typhoon ─────────────────────────────────

  /// Available weather timestamps.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/weather/list`
  Future<List<dynamic>> getWeatherList() async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v2/meteor/weather/list',
          ))
          as List<dynamic>;

  /// Weather station data at [time].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/weather/{time}`
  Future<dynamic> getWeather(String time) =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v2/meteor/weather/$time');

  /// Realtime weather at the given coordinates (2-decimal precision).
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v3/weather/realtime/{lat},{lon}`
  Future<dynamic> getWeatherRealtime(double lat, double lon) => _client.get(
    ApiTier.coreExclusiveApi,
    '/api/v3/weather/realtime/${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',
  );

  /// Weather forecast for [region].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v3/weather/forecast/{region}`
  Future<dynamic> getWeatherForecast(String region) =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v3/weather/forecast/$region');

  /// Available rain timestamps.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/rain/list`
  Future<List<dynamic>> getRainList() async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v2/meteor/rain/list'))
          as List<dynamic>;

  /// Rain station data at [time].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/rain/{time}`
  Future<dynamic> getRain(String time) =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v2/meteor/rain/$time');

  /// Available lightning timestamps.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/lightning/list`
  Future<List<dynamic>> getLightningList() async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v2/meteor/lightning/list',
          ))
          as List<dynamic>;

  /// Lightning data at [time].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/lightning/{time}`
  Future<dynamic> getLightning(String time) =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v2/meteor/lightning/$time');

  /// Available typhoon image timestamps.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/typhoon/images/list`
  Future<List<dynamic>> getTyphoonImagesList() async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v2/meteor/typhoon/images/list',
          ))
          as List<dynamic>;

  /// Typhoon track GeoJSON.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/meteor/typhoon/geojson`
  Future<dynamic> getTyphoonGeojson() =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v2/meteor/typhoon/geojson');

  // ── Tsunami ──────────────────────────────────────────────────────────────

  /// Tsunami detail by [id].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/tsunami/{id}`
  Future<dynamic> getTsunami(String id) =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v1/tsunami/$id');

  /// Tsunami event id list.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/tsunami/list`
  Future<List<dynamic>> getTsunamiList() async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v1/tsunami/list'))
          as List<dynamic>;

  // ── DPIP realtime / history ──────────────────────────────────────────────

  /// Realtime event list.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/dpip/realtime/list`
  Future<List<dynamic>> getRealtimeList() async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v1/dpip/realtime/list',
          ))
          as List<dynamic>;

  /// Historical event list.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/dpip/history/list`
  Future<List<dynamic>> getHistoryList() async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v1/dpip/history/list'))
          as List<dynamic>;

  /// Realtime events for [region].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/dpip/realtime/{region}`
  Future<List<dynamic>> getRealtimeRegion(String region) async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v1/dpip/realtime/$region',
          ))
          as List<dynamic>;

  /// Historical events for [region].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/dpip/history/{region}`
  Future<List<dynamic>> getHistoryRegion(String region) async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v1/dpip/history/$region',
          ))
          as List<dynamic>;

  /// Event detail by [id].
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/dpip/event/{id}`
  Future<dynamic> getEvent(String id) =>
      _client.get(ApiTier.coreExclusiveApi, '/api/v1/dpip/event/$id');

  // ── Announcements ────────────────────────────────────────────────────────

  /// Current announcements.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/dpip/announcement`
  Future<List<dynamic>> getAnnouncements() async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v1/dpip/announcement'))
          as List<dynamic>;

  // ── Device / notification settings (stateful) ────────────────────────────

  /// Registers/updates this device's location for push targeting.
  /// [platform] is 1 for iOS, 0 for Android; [version] is the app version.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/location/{platform}/{token}/{version}/{lat},{lng}`
  Future<dynamic> updateDeviceLocation({
    required String token,
    required int platform,
    required String version,
    required LatLng coordinates,
  }) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token is empty');
    }
    return _client.get(
      ApiTier.coreExclusiveApi,
      '/api/v2/location/$platform/$token/$version/'
      '${coordinates.latitude},${coordinates.longitude}',
    );
  }

  /// Reads this device's notification settings (a list of per-channel ints).
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/notify/{token}`
  Future<List<dynamic>> getNotify({required String token}) async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v2/notify/$token'))
          as List<dynamic>;

  /// Updates a single notification [channel] to [status]; returns new settings.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v2/notify/{token}/{channel}/{status}`
  Future<List<dynamic>> setNotify({
    required String token,
    required int channel,
    required int status,
  }) async {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token is empty');
    }
    return (await _client.get(
          ApiTier.coreExclusiveApi,
          '/api/v2/notify/$token/$channel/$status',
        ))
        as List<dynamic>;
  }

  /// Notification delivery history for this device.
  ///
  /// `https://api.core-tnn1.exptech.dev/api/v1/notify/history`
  Future<List<dynamic>> getNotificationHistory() async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v1/notify/history'))
          as List<dynamic>;

  // ── Time sync / diagnostics ──────────────────────────────────────────────

  /// Server time (ms since epoch) with NTP-style round-trip offset correction.
  ///
  /// `https://api.core-tnn1.exptech.dev/ntp`
  Future<int> getNtp() async {
    final t1 = DateTime.now().microsecondsSinceEpoch;
    final res = await _client.request(
      ApiTier.coreExclusiveApi,
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
  ///
  /// `POST https://api.core-tnn1.exptech.dev/api/v1/dpip/networkInfo`
  Future<void> sendNetworkInfo({
    required String? ip,
    required String? isp,
    required List<int?> status,
    required List<int?> statusDev,
  }) async {
    await _client.post(
      ApiTier.coreExclusiveApi,
      '/api/v1/dpip/networkInfo',
      data: {'ip': ip, 'isp': isp, 'status': status, 'status_dev': statusDev},
    );
  }

  static int? _microsFromHeader(String? value) =>
      value != null ? (double.parse(value) * 1000).toInt() : null;
}
