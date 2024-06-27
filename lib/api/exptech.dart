import 'dart:convert';
import 'dart:io';

import 'package:dpip/api/route.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
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

  Future<List<PartialEarthquakeReport>> getReportList() async {
    final requestUrl = Route.reportList();

    var res = await get(requestUrl);

    if (res.statusCode != 200) {
      throw HttpException("The server returned a status of ${res.statusCode}", uri: requestUrl);
    }

    final json = jsonDecode(res.body) as List;

    return json.map((e) => PartialEarthquakeReport.fromJson(e as Map<String, dynamic>)).toList();
  }
}
