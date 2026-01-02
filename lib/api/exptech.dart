import 'dart:convert';
import 'dart:io';

import 'package:dpip/api/model/announcement.dart';
import 'package:dpip/api/model/changelog/changelog.dart';
import 'package:dpip/api/model/crowdin/localization_progress.dart';
import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/meteor_station.dart';
import 'package:dpip/api/model/notification_record.dart';
import 'package:dpip/api/model/notify/notify_settings.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/api/model/rts/rts.dart';
import 'package:dpip/api/model/server_status.dart';
import 'package:dpip/api/model/station.dart';
import 'package:dpip/api/model/tsunami/tsunami.dart';
import 'package:dpip/api/model/weather/lightning.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/api/route.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/response.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:option_result/result.dart';
import 'package:zstandard/zstandard.dart';

class _GzipClient extends http.BaseClient {
  final http.Client _inner;
  final Zstandard _zstd = Zstandard();

  _GzipClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Accept-Encoding'] = 'gzip, deflate, zstd';
    final response = await _inner.send(request);

    final contentEncoding =
        response.headers['content-encoding'] ??
        response.headers['Content-Encoding'];
    if (contentEncoding?.toLowerCase() == 'zstd') {
      final compressedBody = await response.stream.toBytes();

      try {
        final decompressedBody = await _zstd.decompress(compressedBody);

        if (decompressedBody == null) {
          throw HttpException(
            'Failed to decompress zstd response',
            uri: request.url,
          );
        }

        final headers = Map<String, String>.from(response.headers);
        headers.remove('content-encoding');
        headers.remove('Content-Encoding');

        return http.StreamedResponse(
          Stream.value(decompressedBody),
          response.statusCode,
          contentLength: decompressedBody.length,
          headers: headers,
          reasonPhrase: response.reasonPhrase,
          request: response.request,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
        );
      } catch (_) {
        return http.StreamedResponse(
          Stream.value(compressedBody),
          response.statusCode,
          contentLength: compressedBody.length,
          headers: response.headers,
          reasonPhrase: response.reasonPhrase,
          request: response.request,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
        );
      }
    }

    return response;
  }

  @override
  void close() => _inner.close();
}

http.Client _createHttpClient() {
  final httpClient = HttpClient();

  final proxyEnabled = Preference.proxyEnabled ?? false;
  final proxyHost = Preference.proxyHost;
  final proxyPort = Preference.proxyPort;

  if (proxyEnabled && proxyHost != null && proxyPort != null) {
    httpClient.findProxy = (uri) {
      return 'PROXY $proxyHost:$proxyPort';
    };
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => false;
  }

  return IOClient(httpClient);
}

final http.Client _sharedClient = _GzipClient(_createHttpClient());

class Rtsnodata implements Exception {
  const Rtsnodata();
}

class ExpTech {
  String? apikey;

  ExpTech({this.apikey});

  Future<EarthquakeReport> getReport(String reportId) async {
    final requestUrl = Routes.report(reportId);

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final json = jsonDecode(res.body);

    return EarthquakeReport.fromJson(json as Map<String, dynamic>);
  }

  Future<List<PartialEarthquakeReport>> getReportList({
    int? limit = 50,
    int? page = 1,
    int? minIntensity = 0,
    int? maxIntensity = 9,
    int? minMagnitude = 0,
    int? maxMagnitude = 8,
    int? minDepth = 0,
    int? maxDepth = 700,
  }) async {
    final requestUrl = Routes.reportList(
      limit: limit,
      page: page,
      minIntensity: minIntensity,
      maxIntensity: maxIntensity,
      minMagnitude: minMagnitude,
      maxMagnitude: maxMagnitude,
      minDepth: minDepth,
      maxDepth: maxDepth,
    );

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map((e) => PartialEarthquakeReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Rts> getRts([int? time]) async {
    var requestUrl = Routes.rts();

    if (time != null) {
      requestUrl = Uri.parse(
        requestUrl
            .toString()
            .replaceAll('rts', 'rts/${time ~/ 1000}')
            .replaceAll('lb-', 'api-')
            .replaceAll('-3', '-1')
            .replaceAll('-4', '-2')
            .replaceAll(RegExp(r'api-\d+'), 'api-1'),
      );
    }

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode == 404 && time != null) {
      throw const Rtsnodata();
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    return Rts.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Eew>> getEew([int? time]) async {
    var requestUrl = Routes.eew();

    if (time != null) {
      requestUrl = Uri.parse(
        requestUrl
            .toString()
            .replaceAll('eew', 'eew/${time ~/ 1000}')
            .replaceAll('lb-', 'api-')
            .replaceAll('-3', '-1')
            .replaceAll('-4', '-2')
            .replaceAll(RegExp(r'api-\d+'), 'api-1'),
      );
    }

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode == 200) {
      final eewList = (jsonDecode(res.body) as List<dynamic>).map(
        (e) => Eew.fromJson(e as Map<String, dynamic>),
      );

      if (Preference.experimentalEewAllSource == true) {
        return eewList.toList();
      }

      return eewList.where((e) => e.agency == 'cwa').toList();
    } else {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }
  }

  Future<int> getNtp() async {
    final requestUrl = Routes.ntp();

    final t1 = DateTime.now().microsecondsSinceEpoch;

    final res = await _sharedClient.get(requestUrl);

    final t4 = DateTime.now().microsecondsSinceEpoch;

    if (res.statusCode == 200) {
      final t2Header = res.headers['x-ntp-t2'];
      final t3Header = res.headers['x-ntp-t3'];

      final t2 = t2Header != null
          ? (double.parse(t2Header) * 1000).toInt()
          : null;
      final t3 = t3Header != null
          ? (double.parse(t3Header) * 1000).toInt()
          : null;

      if (t2 != null && t3 != null) {
        final offset = ((t2 - t1) + (t3 - t4)) / 2;
        final serverTime = (t3 + offset).toInt();
        return serverTime ~/ 1000;
      }

      return double.parse(res.body).toInt();
    } else {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }
  }

  Future<Map<String, Station>> getStations() async {
    final requestUrl = Routes.station();
    final host = requestUrl.host;

    TalkerManager.instance.debug('🌐 Station API: GET $requestUrl');

    final headers = <String, String>{};
    final etagKey = '${PreferenceKeys.stationEtag}:$host';
    final cacheKey = '${PreferenceKeys.stationCache}:$host';
    final cachedEtag = Preference.instance.getString(etagKey);
    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
      TalkerManager.instance.debug(
        '🌐 Station API: Using ETag: $cachedEtag (host: $host)',
      );
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 Station API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(cacheKey);
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 Station API: Using cached data (304 Not Modified)',
        );
        final json = jsonDecode(cachedData) as Map<String, dynamic>;
        return json.map((key, value) {
          return MapEntry(key, Station.fromJson(value as Map<String, dynamic>));
        });
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(etagKey, etag);
      TalkerManager.instance.debug(
        '🌐 Station API: Saved ETag: $etag (host: $host)',
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    await Preference.instance.setString(cacheKey, res.body);
    TalkerManager.instance.debug(
      '🌐 Station API: Saved cached data (host: $host)',
    );

    return json.map((key, value) {
      return MapEntry(key, Station.fromJson(value as Map<String, dynamic>));
    });
  }

  Future<Tsunami> getTsunami(String tsuId) async {
    final requestUrl = Routes.tsunami(tsuId);

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;

    return Tsunami.fromJson(json);
  }

  Future<List<String>> getTsunamiList() async {
    final requestUrl = Routes.tsunamiList();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => e as String).toList();
  }

  Future<Result<List<CrowdinLocalizationProgress>, String>>
  getLocalizationProgress() async {
    final requestUrl = Routes.locale();

    final response = await _sharedClient.get(requestUrl);

    if (response.statusCode != 200) {
      return Err('無法從 Crowdin 取得翻譯狀態');
    }

    final data = response.json()['data'] as List;
    final progress = data
        .cast<Map<String, dynamic>>()
        .map((e) => CrowdinLocalizationProgress.fromJson(e))
        .toList();

    return Ok(progress);
  }

  Future<List<String>> getRadarList() async {
    final requestUrl = Routes.radarList();

    TalkerManager.instance.debug('🌐 Radar List API: GET $requestUrl');

    final headers = <String, String>{};
    await Preference.reload();
    final cachedEtag = Preference.instance.getString(
      PreferenceKeys.radarListEtag,
    );
    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
      TalkerManager.instance.debug(
        '🌐 Radar List API: Using ETag: $cachedEtag',
      );
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 Radar List API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(
        PreferenceKeys.radarListCache,
      );
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 Radar List API: Using cached data (304 Not Modified)',
        );
        final List<dynamic> jsonData = jsonDecode(cachedData) as List<dynamic>;
        return jsonData.map((item) => item.toString()).toList();
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(PreferenceKeys.radarListEtag, etag);
      TalkerManager.instance.debug('🌐 Radar List API: Saved ETag: $etag');
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;
    await Preference.instance.setString(
      PreferenceKeys.radarListCache,
      res.body,
    );
    TalkerManager.instance.debug('🌐 Radar List API: Saved cached data');

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<String>> getWeatherList() async {
    final requestUrl = Routes.weatherList();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<WeatherStation>> getWeather(String time) async {
    final requestUrl = Routes.weather(time);

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map((item) => WeatherStation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RealtimeWeather> getWeatherRealtimeByCoords(
    double lat,
    double lon,
  ) async {
    final requestUrl = Routes.weatherRealtimeByCoords(lat, lon);

    TalkerManager.instance.debug('🌐 API: GET $requestUrl');

    final cacheKey = PreferenceKeys.weatherCache;
    final etagKey = PreferenceKeys.weatherEtag;
    final coordsKey = '${PreferenceKeys.weatherCache}:coords';
    final currentCoords = '$lat:$lon';
    final cachedCoords = Preference.instance.getString(coordsKey);

    final headers = <String, String>{};
    if (cachedCoords == currentCoords) {
      final cachedEtag = Preference.instance.getString(etagKey);
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
        TalkerManager.instance.debug('🌐 API: Using ETag: $cachedEtag');
      }
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(cacheKey);
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 API: Using cached data (304 Not Modified)',
        );
        final json = jsonDecode(cachedData) as Map<String, dynamic>;
        return RealtimeWeather.fromJson(json);
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(etagKey, etag);
      TalkerManager.instance.debug('🌐 API: Saved ETag: $etag');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    await Preference.instance.setString(cacheKey, res.body);
    await Preference.instance.setString(coordsKey, currentCoords);
    TalkerManager.instance.debug('🌐 API: Saved cached data');

    TalkerManager.instance.debug('🌐 API: JSON decoded successfully');

    final weather = RealtimeWeather.fromJson(json);
    TalkerManager.instance.debug('🌐 API: RealtimeWeather.fromJson completed');

    return weather;
  }

  Future<Map<String, dynamic>> getWeatherForecast(String region) async {
    final requestUrl = Routes.weatherForecast(region);

    TalkerManager.instance.debug('🌐 Forecast API: GET $requestUrl');

    final cacheKey = PreferenceKeys.forecastCache;
    final etagKey = PreferenceKeys.forecastEtag;
    final regionKey = '${PreferenceKeys.forecastCache}:region';
    final cachedRegion = Preference.instance.getString(regionKey);

    final headers = <String, String>{};
    if (cachedRegion == region) {
      final cachedEtag = Preference.instance.getString(etagKey);
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
        TalkerManager.instance.debug(
          '🌐 Forecast API: Using ETag: $cachedEtag',
        );
      }
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 Forecast API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(cacheKey);
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 Forecast API: Using cached data (304 Not Modified)',
        );
        return jsonDecode(cachedData) as Map<String, dynamic>;
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(etagKey, etag);
      TalkerManager.instance.debug('🌐 Forecast API: Saved ETag: $etag');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    await Preference.instance.setString(cacheKey, res.body);
    await Preference.instance.setString(regionKey, region);
    TalkerManager.instance.debug('🌐 Forecast API: Saved cached data');

    TalkerManager.instance.debug('🌐 Forecast API: Response JSON: $json');

    return json;
  }

  Future<List<String>> getRainList() async {
    final requestUrl = Routes.rainList();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<RainStation>> getRain(String time) async {
    final requestUrl = Routes.rain(time);

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map((item) => RainStation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List> getTyphoonImagesList() async {
    final requestUrl = Routes.typhoonImagesList();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item).toList();
  }

  Future<List<String>> getLightningList() async {
    final requestUrl = Routes.lightningList();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<Map<String, dynamic>> getTyphoonGeojson() async {
    final requestUrl = Routes.typhoonGeojson();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final jsonData = jsonDecode(res.body) as Map<String, dynamic>;

    return jsonData;
  }

  Future<List<Lightning>> getLightning(String time) async {
    final requestUrl = Routes.lightning(time);

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map((item) => Lightning.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<History>> getRealtime() async {
    final requestUrl = Routes.realtime();

    TalkerManager.instance.debug('🌐 Realtime List API: GET $requestUrl');

    final headers = <String, String>{};
    await Preference.reload();
    final cachedEtag = Preference.instance.getString(
      PreferenceKeys.realtimeListEtag,
    );
    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
      TalkerManager.instance.debug(
        '🌐 Realtime List API: Using ETag: $cachedEtag',
      );
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 Realtime List API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(
        PreferenceKeys.realtimeListCache,
      );
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 Realtime List API: Using cached data (304 Not Modified)',
        );
        final List<dynamic> jsonData = jsonDecode(cachedData) as List<dynamic>;
        return jsonData
            .map((item) => History.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(
        PreferenceKeys.realtimeListEtag,
        etag,
      );
      TalkerManager.instance.debug('🌐 Realtime List API: Saved ETag: $etag');
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;
    await Preference.instance.setString(
      PreferenceKeys.realtimeListCache,
      res.body,
    );
    TalkerManager.instance.debug('🌐 Realtime List API: Saved cached data');

    return jsonData
        .map((item) => History.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<History>> getHistory() async {
    final requestUrl = Routes.history();

    TalkerManager.instance.debug('🌐 History List API: GET $requestUrl');

    final headers = <String, String>{};
    await Preference.reload();
    final cachedEtag = Preference.instance.getString(
      PreferenceKeys.historyListEtag,
    );
    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
      TalkerManager.instance.debug(
        '🌐 History List API: Using ETag: $cachedEtag',
      );
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 History List API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(
        PreferenceKeys.historyListCache,
      );
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 History List API: Using cached data (304 Not Modified)',
        );
        final List<dynamic> jsonData = jsonDecode(cachedData) as List<dynamic>;
        return jsonData
            .map((item) => History.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(PreferenceKeys.historyListEtag, etag);
      TalkerManager.instance.debug('🌐 History List API: Saved ETag: $etag');
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;
    await Preference.instance.setString(
      PreferenceKeys.historyListCache,
      res.body,
    );
    TalkerManager.instance.debug('🌐 History List API: Saved cached data');

    return jsonData
        .map((item) => History.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<History>> getRealtimeRegion(String region) async {
    final requestUrl = Routes.realtimeRegion(region);

    TalkerManager.instance.debug('🌐 Realtime Region API: GET $requestUrl');

    final cacheKey = PreferenceKeys.realtimeRegionCache;
    final etagKey = PreferenceKeys.realtimeRegionEtag;
    final regionKey = '${PreferenceKeys.realtimeRegionCache}:region';

    final headers = <String, String>{};
    await Preference.reload();
    final cachedRegion = Preference.instance.getString(regionKey);
    if (cachedRegion == region) {
      final cachedEtag = Preference.instance.getString(etagKey);
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
        TalkerManager.instance.debug(
          '🌐 Realtime Region API: Using ETag: $cachedEtag',
        );
      }
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 Realtime Region API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(cacheKey);
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 Realtime Region API: Using cached data (304 Not Modified)',
        );
        final List<dynamic> jsonData = jsonDecode(cachedData) as List<dynamic>;
        return jsonData
            .map((item) => History.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(etagKey, etag);
      TalkerManager.instance.debug('🌐 Realtime Region API: Saved ETag: $etag');
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;
    await Preference.instance.setString(cacheKey, res.body);
    await Preference.instance.setString(regionKey, region);
    TalkerManager.instance.debug('🌐 Realtime Region API: Saved cached data');

    return jsonData
        .map((item) => History.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<History>> getHistoryRegion(String region) async {
    final requestUrl = Routes.historyRegion(region);

    TalkerManager.instance.debug('🌐 History Region API: GET $requestUrl');

    final cacheKey = PreferenceKeys.historyRegionCache;
    final etagKey = PreferenceKeys.historyRegionEtag;
    final regionKey = '${PreferenceKeys.historyRegionCache}:region';

    final headers = <String, String>{};
    await Preference.reload();
    final cachedRegion = Preference.instance.getString(regionKey);
    if (cachedRegion == region) {
      final cachedEtag = Preference.instance.getString(etagKey);
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
        TalkerManager.instance.debug(
          '🌐 History Region API: Using ETag: $cachedEtag',
        );
      }
    }

    final res = await _sharedClient.get(requestUrl, headers: headers);

    TalkerManager.instance.debug(
      '🌐 History Region API: Response status=${res.statusCode}, body length=${res.body.length}',
    );

    if (res.statusCode == 304) {
      final cachedData = Preference.instance.getString(cacheKey);
      if (cachedData != null) {
        TalkerManager.instance.debug(
          '🌐 History Region API: Using cached data (304 Not Modified)',
        );
        final List<dynamic> jsonData = jsonDecode(cachedData) as List<dynamic>;
        return jsonData
            .map((item) => History.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException(
          '304 Not Modified but no cached data available',
          uri: requestUrl,
        );
      }
    }

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final etag = res.headers['etag'] ?? res.headers['ETag'];
    if (etag != null) {
      await Preference.instance.setString(etagKey, etag);
      TalkerManager.instance.debug('🌐 History Region API: Saved ETag: $etag');
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;
    await Preference.instance.setString(cacheKey, res.body);
    await Preference.instance.setString(regionKey, region);
    TalkerManager.instance.debug('🌐 History Region API: Saved cached data');

    return jsonData
        .map((item) => History.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getSupport() async {
    final requestUrl = Routes.support();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Result<List<GithubRelease>, String>> getReleases() async {
    try {
      final requestUrl =
          'https://api.github.com/repos/ExpTechTW/DPIP-Pocket/releases'.asUri;

      final response = await _sharedClient.get(requestUrl);

      if (!response.ok) {
        return Err('無法從 GitHub 取得更新紀錄，狀態 ${response.statusCode}');
      }

      final data = response.list().cast<Map<String, dynamic>>();
      final releases = data.map(GithubRelease.fromJson).toList();

      return Ok(releases);
    } catch (e) {
      return Err('無法從 GitHub 取得更新紀錄');
    }
  }

  Future<List<Announcement>> getAnnouncement() async {
    final requestUrl = Routes.announcement();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificationRecord>> getNotificationHistory() async {
    final requestUrl = Routes.notificationHistory();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map(
          (item) => NotificationRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ServerStatus>> getStatus() async {
    final requestUrl = Routes.status();

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map((item) => ServerStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MeteorStation> getMeteorStation(String id) async {
    final requestUrl = Routes.meteorStation(id);

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final Map<String, dynamic> jsonData =
        jsonDecode(res.body) as Map<String, dynamic>;

    return MeteorStation.fromJson(jsonData);
  }

  Future<List<History>> getEvent(String id) async {
    final requestUrl = Routes.event(id);

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData
        .map((item) => History.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 回傳所在地
  Future<String> updateDeviceLocation({
    required String token,
    required LatLng coordinates,
  }) async {
    final requestUrl = Routes.location(
      token: token,
      lat: '${coordinates.latitude}',
      lng: '${coordinates.longitude}',
    );

    final res = await _sharedClient.get(requestUrl);

    if (res.statusCode == 200) {
      Preference.lastUpdateToServerTime = DateTime.now().millisecondsSinceEpoch;

      return res.body;
    } else if (res.statusCode == 202) {
      return '${res.statusCode} $requestUrl';
    } else {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }
  }

  /// 取得通知
  Future<NotifySettings> getNotify({required String token}) async {
    final requestUrl = Routes.notify(token: token);

    final res = await _sharedClient.get(requestUrl);

    if (!res.ok) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return NotifySettings.fromJson(jsonData.map((e) => e as int).toList());
  }

  /// 設定通知
  Future<NotifySettings> setNotify({
    required String token,
    required NotifyChannel channel,
    required Enum status,
  }) async {
    final requestUrl = Routes.notifyStatus(
      token: token,
      channel: channel,
      status: status,
    );

    final res = await _sharedClient.get(requestUrl);

    if (!res.ok) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return NotifySettings.fromJson(jsonData.map((e) => e as int).toList());
  }

  Future<void> sendNetWorkInfo({
    required String? ip,
    required String? isp,
    required List<int?> status,
    required List<int?> status_dev,
  }) async {
    final requestUrl = Routes.networkInfo();

    String body = jsonEncode({
      'ip': ip,
      'isp': isp,
      'status': status,
      'status_dev': status_dev,
    });

    final res = await _sharedClient.post(requestUrl, body: body);

    if (!res.ok) {
      throw HttpException(
        'The server returned a status of ${res.statusCode}',
        uri: requestUrl,
      );
    }
  }
}
