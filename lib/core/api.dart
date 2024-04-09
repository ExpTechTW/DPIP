import 'dart:convert';

import 'package:dpip/model/earthquake_report.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:http/http.dart' as http;

class ExpTechApi {
  String? apikey;

  ExpTechApi({this.apikey});

  Future<List<PartialEarthquakeReport>> getReportList({int limit = 20}) async {
    final response = await http.get(Uri.parse('https://lb-3.exptech.com.tw/api/v2/eq/report?limit=$limit'));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>).map((e) => PartialEarthquakeReport.fromJson(e)).toList();
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }

  Future<EarthquakeReport> getReport(String id) async {
    final response = await http.get(Uri.parse('https://lb-3.exptech.com.tw/api/v2/eq/report/$id'));

    if (response.statusCode == 200) {
      return EarthquakeReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }

  Future<List<String>> getNotificationTopics(String fcmToken) async {
    final response = await http.get(Uri.parse('https://api-1.exptech.com.tw/dpip/$fcmToken/topics'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<String>;
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }
}
