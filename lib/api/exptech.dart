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
import 'package:http/http.dart';

class ExpTech {
  String? apikey;

  ExpTech({this.apikey});

  Future<EarthquakeReport> getReport(String reportId) async {
    final requestUrl = Route.report(reportId);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
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
    final requestUrl = Route.reportList(
      limit: limit,
      page: page,
      minIntensity: minIntensity,
      maxIntensity: maxIntensity,
      minMagnitude: minMagnitude,
      maxMagnitude: maxMagnitude,
      minDepth: minDepth,
      maxDepth: maxDepth,
    );

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((e) => PartialEarthquakeReport.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Rts> getRts([int? time]) async {
    var requestUrl = Route.rts();

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

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    return Rts.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Eew>> getEew([int? time]) async {
    var requestUrl = Route.eew();

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

    final res = await get(requestUrl);

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List<dynamic>).map((e) => Eew.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }
  }

  Future<int> getNtp() async {
    final requestUrl = Route.ntp();

    final res = await get(requestUrl);

    if (res.statusCode == 200) {
      return int.parse(res.body);
    } else {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }
  }

  Future<Map<String, Station>> getStations() async {
    final requestUrl = Route.station();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    return (jsonDecode(res.body) as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, Station.fromJson(value as Map<String, dynamic>));
    });
  }

  Future<Tsunami> getTsunami(String tsuId) async {
    final requestUrl = Route.tsunami(tsuId);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;

    return Tsunami.fromJson(json);
  }

  Future<List<String>> getTsunamiList() async {
    final requestUrl = Route.tsunamiList();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => e as String).toList();
  }

  Future<List<CrowdinLocalizationProgress>> getLocalizationProgress() async {
    final requestUrl = Route.locale();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => CrowdinLocalizationProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getRadarList() async {
    final requestUrl = Route.radarList();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<String>> getWeatherList() async {
    final requestUrl = Route.weatherList();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<WeatherStation>> getWeather(String time) async {
    final requestUrl = Route.weather(time);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => WeatherStation.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<RealtimeWeather> getWeatherRealtime(String region) async {
    final requestUrl = Route.weatherRealtime(region);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;

    return RealtimeWeather.fromJson(json);
  }

  Future<List<String>> getRainList() async {
    final requestUrl = Route.rainList();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<RainStation>> getRain(String time) async {
    final requestUrl = Route.rain(time);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => RainStation.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List> getTyphoonImagesList() async {
    final requestUrl = Route.typhoonImagesList();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item).toList();
  }

  Future<List<String>> getLightningList() async {
    final requestUrl = Route.lightningList();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<Map<String, dynamic>> getTyphoonGeojson() async {
    final requestUrl = Route.typhoonGeojson();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final jsonData = jsonDecode(res.body) as Map<String, dynamic>;

    return jsonData;
  }

  Future<List<Lightning>> getLightning(String time) async {
    final requestUrl = Route.lightning(time);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => Lightning.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<History>> getRealtime() async {
    final requestUrl = Route.realtime();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => History.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<History>> getHistory() async {
    final requestUrl = Route.history();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => History.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<History>> getRealtimeRegion(String region) async {
    final requestUrl = Route.realtimeRegion(region);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => History.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<History>> getHistoryRegion(String region) async {
    final requestUrl = Route.historyRegion(region);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => History.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getSupport() async {
    final requestUrl = Route.support();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<GithubRelease>> getReleases() async {
    final requestUrl = 'https://api.github.com/repos/ExpTechTW/DPIP/releases'.asUri;

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => GithubRelease.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Announcement>> getAnnouncement() async {
    final requestUrl = Route.announcement();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => Announcement.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<NotificationRecord>> getNotificationHistory() async {
    final requestUrl = Route.notificationHistory();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => NotificationRecord.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ServerStatus>> getStatus() async {
    final requestUrl = Route.status();

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => ServerStatus.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<MeteorStation> getMeteorStation(String id) async {
    final requestUrl = Route.meteorStation(id);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final Map<String, dynamic> jsonData = jsonDecode(res.body) as Map<String, dynamic>;

    return MeteorStation.fromJson(jsonData);
  }

  Future<List<History>> getEvent(String id) async {
    final requestUrl = Route.event(id);

    final res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return jsonData.map((item) => History.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// 回傳所在地
  Future<String> updateDeviceLocation({required String token, required String lat, required String lng}) async {
    final requestUrl = Route.location(token: token, lat: lat, lng: lng);

    final res = await get(requestUrl);

    if (res.statusCode == 200) {
      Preference.lastUpdateToServerTime = DateTime.now().millisecondsSinceEpoch;

      return res.body;
    } else if (res.statusCode == 202) {
      return '${res.statusCode} $requestUrl';
    } else {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }
  }

  /// 取得通知
  Future<NotifySettings> getNotify({required String token}) async {
    final requestUrl = Route.notify(token: token);

    final res = await get(requestUrl);

    if (!res.ok) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return NotifySettings.fromJson(jsonData.map((e) => e as int).toList());
  }

  /// 設定通知
  Future<NotifySettings> setNotify({required String token, required NotifyChannel channel, required Enum status}) async {
    final requestUrl = Route.notifyStatus(token: token, channel: channel, status: status);

    final res = await get(requestUrl);

    if (!res.ok) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body) as List<dynamic>;

    return NotifySettings.fromJson(jsonData.map((e) => e as int).toList());
  }

  Future<void> sendNetWorkInfo({required String? ip,required String? isp, required List<int?> status, required List<int?> status_dev}) async {
    final requestUrl = Route.networkInfo();

    String body=jsonEncode({
      'ip':ip,
      'isp':isp,
      'status':status,
      'status-dev':status_dev
    });

    final res = await post(requestUrl,body: body);

    if (!res.ok) {
      throw HttpException('The server returned a status of ${res.statusCode}', uri: requestUrl);
    }
  }
}
