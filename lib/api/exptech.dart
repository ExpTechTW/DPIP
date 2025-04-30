import "dart:convert";
import "dart:io";

import "package:http/http.dart";

import "package:dpip/api/model/announcement.dart";
import "package:dpip/api/model/crowdin/localization_progress.dart";
import "package:dpip/api/model/eew.dart";
import "package:dpip/api/model/history.dart";
import "package:dpip/api/model/meteor_station.dart";
import "package:dpip/api/model/notification_record.dart";
import "package:dpip/api/model/report/earthquake_report.dart";
import "package:dpip/api/model/report/partial_earthquake_report.dart";
import "package:dpip/api/model/rts/rts.dart";
import "package:dpip/api/model/server_status.dart";
import "package:dpip/api/model/station.dart";
import "package:dpip/api/model/tsunami/tsunami.dart";
import "package:dpip/api/model/weather/lightning.dart";
import "package:dpip/api/model/weather/rain.dart";
import "package:dpip/api/model/weather/weather.dart";
import "package:dpip/api/model/weather_schema.dart";
import "package:dpip/api/route.dart";
import "package:dpip/models/settings/notify.dart";
import "package:dpip/utils/extensions/response.dart";

class ExpTech {
  String? apikey;

  ExpTech({this.apikey});

  Future<EarthquakeReport> getReport(String reportId) async {
    final requestUrl = Route.report(reportId);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body);

    return EarthquakeReport.fromJson(json);
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

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => PartialEarthquakeReport.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Rts> getRts(int time) async {
    var requestUrl = Route.rts();

    if (time != 0) {
      requestUrl = Uri.parse(
        requestUrl
            .toString()
            .replaceAll("rts", "rts/${time ~/ 1000}")
            .replaceAll("lb-", "api-")
            .replaceAll("-3", "-1")
            .replaceAll("-4", "-2")
            .replaceAll(RegExp(r'api-\d+'), 'api-1'),
      );
    }

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    return Rts.fromJson(jsonDecode(res.body));
  }

  Future<List<Eew>> getEew(int time) async {
    var requestUrl = Route.eew();

    if (time != 0) {
      requestUrl = Uri.parse(
        requestUrl
            .toString()
            .replaceAll("eew", "eew/${time ~/ 1000}")
            .replaceAll("lb-", "api-")
            .replaceAll("-3", "-1")
            .replaceAll("-4", "-2")
            .replaceAll(RegExp(r'api-\d+'), 'api-1'),
      );
    }

    var res = await get(requestUrl);

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List<dynamic>).map((e) => Eew.fromJson(e)).toList();
    } else {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }
  }

  Future<int> getNtp() async {
    final requestUrl = Route.ntp();

    var res = await get(requestUrl);

    if (res.statusCode == 200) {
      return int.parse(res.body);
    } else {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }
  }

  Future<Map<String, Station>> getStations() async {
    final requestUrl = Route.station();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    return (jsonDecode(res.body) as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, Station.fromJson(value as Map<String, dynamic>));
    });
  }

  Future<Tsunami> getTsunami(String tsuId) async {
    final requestUrl = Route.tsunami(tsuId);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body);

    return Tsunami.fromJson(json);
  }

  Future<List<String>> getTsunamiList() async {
    final requestUrl = Route.tsunamiList();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => e as String).toList();
  }

  Future<String> getNotifyLocation(String token, String lat, String lng) async {
    final requestUrl = Route.location(token, lat, lng);

    var res = await get(requestUrl);

    if (res.statusCode == 200) {
      return res.body;
    } else if (res.statusCode == 204) {
      return "${res.statusCode} $requestUrl";
    } else {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }
  }

  Future<List<CrowdinLocalizationProgress>> getLocalizationProgress() async {
    final requestUrl = Route.locale();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => CrowdinLocalizationProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getRadarList() async {
    final requestUrl = Route.radarList();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<String>> getWeatherList() async {
    final requestUrl = Route.weatherList();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<WeatherStation>> getWeather(String time) async {
    final requestUrl = Route.weather(time);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => WeatherStation.fromJson(item)).toList();
  }

  Future<RealtimeWeather> getWeatherRealtime(String region) async {
    final requestUrl = Route.weatherRealtime(region);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body);

    return RealtimeWeather.fromJson(json);
  }

  Future<List<String>> getRainList() async {
    final requestUrl = Route.rainList();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<List<RainStation>> getRain(String time) async {
    final requestUrl = Route.rain(time);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => RainStation.fromJson(item)).toList();
  }

  Future<List> getTyphoonImagesList() async {
    final requestUrl = Route.typhoonImagesList();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => item).toList();
  }

  Future<List<String>> getLightningList() async {
    final requestUrl = Route.lightningList();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => item.toString()).toList();
  }

  Future<Map<String, dynamic>> getTyphoonGeojson() async {
    final requestUrl = Route.typhoonGeojson();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final jsonData = jsonDecode(res.body);

    return jsonData;
  }

  Future<List<Lightning>> getLightning(String time) async {
    final requestUrl = Route.lightning(time);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => Lightning.fromJson(item)).toList();
  }

  Future<List<History>> getRealtime() async {
    final requestUrl = Route.realtime();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => History.fromJson(item)).toList();
  }

  Future<List<History>> getHistory() async {
    final requestUrl = Route.history();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => History.fromJson(item)).toList();
  }

  Future<List<History>> getRealtimeRegion(String region) async {
    final requestUrl = Route.realtimeRegion(region);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => History.fromJson(item)).toList();
  }

  Future<List<History>> getHistoryRegion(String region) async {
    final requestUrl = Route.historyRegion(region);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => History.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> getSupport() async {
    final requestUrl = Route.support();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getChangelog() async {
    final requestUrl = Route.changelog();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    return jsonDecode(res.body);
  }

  Future<List<Announcement>> getAnnouncement() async {
    final requestUrl = Route.announcement();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => Announcement.fromJson(item)).toList();
  }

  Future<List<NotificationRecord>> getNotificationHistory() async {
    final requestUrl = Route.notificationHistory();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => NotificationRecord.fromJson(item)).toList();
  }

  Future<List<ServerStatus>> getStatus() async {
    final requestUrl = Route.status();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => ServerStatus.fromJson(item)).toList();
  }

  Future<MeteorStation> getMeteorStation(String id) async {
    final requestUrl = Route.meteorStation(id);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final Map<String, dynamic> jsonData = jsonDecode(res.body);

    return MeteorStation.fromJson(jsonData);
  }

  Future<List<History>> getEvent(String id) async {
    final requestUrl = Route.event(id);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final List<dynamic> jsonData = jsonDecode(res.body);

    return jsonData.map((item) => History.fromJson(item)).toList();
  }

  Future<void> setNotify({required String token, required NotifyChannel channel, required Enum status}) async {
    final requestUrl = Route.notify(token: token, channel: channel, status: status);

    var res = await get(requestUrl);

    if (!res.ok) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }
  }
}
