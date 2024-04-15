import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

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

  factory PartialEarthquakeReport.fromJson(Map<String, dynamic> json) => _$PartialEarthquakeReportFromJson(json);

  Map<String, dynamic> toJson() => _$PartialEarthquakeReportToJson(this);

  String? get number {
    final n = id.split("-").first;

    if (!n.endsWith("000")) {
      return n;
    }

    return null;
  }

  bool get hasNumber => number != null;

  Uri get cwaUrl {
    final arr = id.split("-");
    arr.removeAt(1);
    return Uri.parse("https://www.cwa.gov.tw/V8/C/E/EQ/EQ${arr.join('-')}.html");
  }

  String get reportImageName {
    final date = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation("Asia/Taipei"), time);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final mag = "${(this.mag * 10).floor()}";

    if (hasNumber) {
      final id = number!.substring(3);
      return "EC$month$day$hour$minute$mag${id}_H.png";
    } else {
      final year = date.year.toString();
      final second = date.second.toString().padLeft(2, '0');
      return "ECL$year$month$day$hour$minute$second${mag}_H.png";
    }
  }

  String get reportImageUrl => "https://www.cwa.gov.tw/Data/earthquake/img/$reportImageName";

  String get zipName {
    final date = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation("Asia/Taipei"), time);
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return "EQ$number-$year-$month$day-$hour$minute$second";
  }

  String get zipUrl => "https://www.cwa.gov.tw/Data/earthquake/zip/$zipName";

  String? get intensityMapImageName {
    if (!hasNumber) return null;

    final date = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation("Asia/Taipei"), time);
    final year = date.year.toString();
    return "$year${number!.substring(3)}i.png";
  }

  String? get intensityMapImageUrl => intensityMapImageName == null ? null : "$zipUrl/$intensityMapImageName";

  String? get pgaMapImageName {
    if (!hasNumber) return null;

    final date = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation("Asia/Taipei"), time);
    final year = date.year.toString();
    return "$year${number!.substring(3)}a.png";
  }

  String? get pgaMapImageUrl => pgaMapImageName == null ? null : "$zipUrl/$pgaMapImageName";

  String? get pgvMapImageName {
    if (!hasNumber) return null;

    final date = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation("Asia/Taipei"), time);
    final year = date.year.toString();
    return "$year${number!.substring(3)}v.png";
  }

  String? get pgvMapImageUrl => pgvMapImageName == null ? null : "$zipUrl/$pgvMapImageName";

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
