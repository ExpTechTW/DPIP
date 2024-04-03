import 'package:json_annotation/json_annotation.dart';
import 'package:dpip/model/area_intensity.dart';

part 'earthquake_report.g.dart';

@JsonSerializable()
class EarthquakeReport {
  final String id;
  final double lon;
  final double lat;
  final String loc;
  final double depth;
  final double mag;
  final Map<String, AreaIntensity> list;
  final int time;
  final int trem;

  EarthquakeReport(
      {required this.id,
      required this.lon,
      required this.lat,
      required this.loc,
      required this.depth,
      required this.mag,
      required this.list,
      required this.time,
      required this.trem});

  factory EarthquakeReport.fromJson(Map<String, dynamic> json) =>
      _$EarthquakeReportFromJson(json);

  Map<String, dynamic> toJson() => _$EarthquakeReportToJson(this);

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

  int? getMaxIntensity() {
    int max = 0;

    list.forEach((areaName, area) {
      area.town.forEach((stationName, station) {
        if (station.intensity > max) max = station.intensity;
      });
    });

    return max;
  }

  String getLocation() {
    if (loc.contains("(")) {
      return loc.substring(loc.indexOf("(") + 3, loc.indexOf(")"));
    } else {
      return loc.substring(0, loc.indexOf("方") + 1);
    }
  }
}
