import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'partial_earthquake_report.g.dart';

@JsonSerializable()
class PartialEarthquakeReport {
  final String id;
  final double lon;
  final double lat;
  final String loc;
  final double depth;
  final double mag;
  @JsonKey(name: "int")
  final int intensity;
  final int time;
  final int trem;
  final String md5;

  PartialEarthquakeReport(
      {required this.id,
      required this.lon,
      required this.lat,
      required this.loc,
      required this.depth,
      required this.mag,
      required this.intensity,
      required this.time,
      required this.trem,
      required this.md5});

  factory PartialEarthquakeReport.fromJson(Map<String, dynamic> json) =>
      _$PartialEarthquakeReportFromJson(json);

  Map<String, dynamic> toJson() => _$PartialEarthquakeReportToJson(this);

  Uri get cwaUrl {
    final arr = id.split("-");
    arr.removeAt(1);
    return Uri.parse(
        "https://www.cwa.gov.tw/V8/C/E/EQ/EQ${arr.join('-')}.html");
  }

  String? getNumber() {
    final n = id.split("-").first;

    if (!n.endsWith("000")) {
      return n;
    }

    return null;
  }

  String getLocation() {
    if (loc.contains("(")) {
      return loc.substring(loc.indexOf("(") + 3, loc.indexOf(")"));
    } else {
      return loc.substring(0, loc.indexOf("方") + 1);
    }
  }

  Color getReportColor() {
    if (mag > 6.5 && intensity >= 7) {
      return Colors.red;
    }
    if (mag > 6.0 && intensity >= 5) {
      return Colors.orange;
    }
    if (mag > 5.5 && intensity >= 4) {
      return Colors.yellow;
    }
    return Colors.green;
  }
}
