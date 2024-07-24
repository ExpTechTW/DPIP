import 'dart:convert';
import 'dart:io';

import 'package:dpip/api/route.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/model/tsunami/tsunami.dart';
import 'package:http/http.dart';

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

  Future<List<PartialEarthquakeReport>> getReportList({int? limit = 50, int? page = 1}) async {
    final requestUrl = Route.reportList(limit: limit, page: page);

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => PartialEarthquakeReport.fromJson(e as Map<String, dynamic>)).toList();
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
      return '${res.statusCode} $requestUrl';
    } else {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }
  }
}
