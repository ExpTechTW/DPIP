import 'dart:convert';
import 'dart:math';

import 'package:dpip/model/earthquake_report.dart';
import 'package:dpip/model/eew.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/model/rts.dart';
import 'package:dpip/model/station.dart';
import 'package:http/http.dart' as http;

enum EewSource {
  /// 交通部中央氣象署
  cwa,

  /// 기상청 날씨누리
  kma,

  /// 気象庁
  jma,

  /// 防災科研
  nied,

  /// 四川省地震局
  scdzj
}

int randomNum(int max) {
  return Random().nextInt(max) + 1;
}

class ExpTechApi {
  String? apikey;

  ExpTechApi({this.apikey});

  Future<List<PartialEarthquakeReport>> getReportList({int limit = 20}) async {
    final response =
        await http.get(Uri.parse('https://api-${randomNum(2)}.exptech.com.tw/api/v2/eq/report?limit=$limit'));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>).map((e) => PartialEarthquakeReport.fromJson(e)).toList();
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }

  Future<EarthquakeReport> getReport(String id) async {
    final response = await http.get(Uri.parse('https://api-${randomNum(2)}.exptech.com.tw/api/v2/eq/report/$id'));

    if (response.statusCode == 200) {
      return EarthquakeReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }

  Future<List<String>> getNotificationTopics(String fcmToken) async {
    final response =
        await http.get(Uri.parse('https://api-${randomNum(2)}.exptech.com.tw/api/v2/dpip/topic?token=$fcmToken'));

    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body) as List);
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }

  Future<Map<String, Station>> getStations() async {
    final response =
        await http.get(Uri.parse('https://raw.githubusercontent.com/exptechtw/api/master/resource/station.json'));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>).map((key, value) {
        return MapEntry(key, Station.fromJson(value as Map<String, dynamic>));
      });
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }

  Future<Rts> getRts() async {
    final response = await http.get(Uri.parse('https://lb-${randomNum(4)}.exptech.com.tw/api/v1/trem/rts'));

    if (response.statusCode == 200) {
      return Rts.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }

  Future<List<Eew>> getEew(EewSource source) async {
    final response =
        await http.get(Uri.parse('https://lb-${randomNum(4)}.exptech.com.tw/api/v1/eq/eew?type=${source.name}'));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>).map((e) => Eew.fromJson(e)).toList();
    } else {
      throw Exception('The server returned a status code of ${response.statusCode}');
    }
  }
}
