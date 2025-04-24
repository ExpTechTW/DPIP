import "package:dpip/api/model/report/area_intensity.dart";
import "package:dpip/util/parser.dart";
import "package:json_annotation/json_annotation.dart";
import "package:maplibre_gl/maplibre_gl.dart";
import "package:timezone/timezone.dart";

part "earthquake_report.g.dart";

@JsonSerializable()
class EarthquakeReport {
  final String id;

  @JsonKey(name: "lon")
  final double longitude;

  @JsonKey(name: "lat")
  final double latitude;

  @JsonKey(name: "loc")
  final String location;

  final double depth;

  @JsonKey(name: "mag")
  final double magnitude;

  final Map<String, AreaIntensity> list;

  @JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)
  final TZDateTime time;

  final int trem;

  EarthquakeReport({
    required this.id,
    required this.longitude,
    required this.latitude,
    required this.location,
    required this.depth,
    required this.magnitude,
    required this.list,
    required this.time,
    required this.trem,
  });

  factory EarthquakeReport.fromJson(Map<String, dynamic> json) =>
      _$EarthquakeReportFromJson(json);

  Map<String, dynamic> toJson() => _$EarthquakeReportToJson(this);

  String? get number {
    final n = id.split("-").first;

    if (!n.endsWith("000")) {
      return n;
    }

    return null;
  }

  LatLng get latlng => LatLng(latitude, longitude);

  bool get hasNumber => number != null;

  Uri get reportUrl {
    final arr = id.split("-");
    arr.removeAt(0);
    final mag = "${(magnitude * 10).floor()}";

    if (hasNumber) {
      final id = number!.substring(3);
      return Uri.parse(
        "https://scweb.cwa.gov.tw/zh-tw/earthquake/details/${arr.join("")}$mag$id",
      );
    }

    return Uri.parse(
      "https://scweb.cwa.gov.tw/zh-tw/earthquake/details/${arr.join("")}$mag",
    );
  }

  String get reportImageName {
    final year = time.year.toString();
    final month = time.month.toString().padLeft(2, "0");
    final day = time.day.toString().padLeft(2, "0");
    final hour = time.hour.toString().padLeft(2, "0");
    final minute = time.minute.toString().padLeft(2, "0");
    final second = time.second.toString().padLeft(2, "0");
    final mag = "${(magnitude * 10).floor()}";

    if (hasNumber) {
      final id = number!.substring(3);
      return "$year$month$day$hour$minute$second$mag${id}_H.png";
    }

    return "$year$month$day$hour$minute$second${mag}_H.png";
  }

  String get reportImageUrl {
    final name = reportImageName;
    final time = name.substring(0, 6);
    return "https://scweb.cwa.gov.tw/webdata/OLDEQ/$time/$reportImageName";
  }

  String? get mapImageBaseName {
    if (!hasNumber) return null;

    final year = time.year.toString();
    final id = number!.substring(3);

    return "$year$id";
  }

  String get traceBaseUrl {
    final year = time.year.toString();
    return "https://scweb.cwa.gov.tw/webdata/drawTrace/plotContour/$year/";
  }

  String? get intensityMapImageName {
    if (!hasNumber) return null;

    return "${mapImageBaseName}i.png";
  }

  String? get intensityMapImageUrl =>
      intensityMapImageName == null
          ? null
          : "$traceBaseUrl/$intensityMapImageName";

  String? get pgaMapImageName {
    if (!hasNumber) return null;

    return "${mapImageBaseName}a.png";
  }

  String? get pgaMapImageUrl =>
      pgaMapImageName == null ? null : "$traceBaseUrl/$pgaMapImageName";

  String? get pgvMapImageName {
    if (!hasNumber) return null;

    return "${mapImageBaseName}v.png";
  }

  String? get pgvMapImageUrl =>
      pgvMapImageName == null ? null : "$traceBaseUrl/$pgvMapImageName";

  int getMaxIntensity() {
    int max = 0;

    list.forEach((areaName, area) {
      area.town.forEach((stationName, station) {
        if (station.intensity > max) max = station.intensity;
      });
    });

    return max;
  }

  String getLocation() {
    if (location.contains("(")) {
      return location.substring(
        location.indexOf("(") + 3,
        location.indexOf(")"),
      );
    } else {
      return location.substring(0, location.indexOf("方") + 1);
    }
  }

  String convertLatLon() {
    var latFormat = "";
    var lonFormat = "";
    var latTemp = latitude;
    var lonTemp = longitude;
    if (latTemp > 90) {
      latTemp = latTemp - 180;
    }
    if (lonTemp > 180) {
      lonTemp = lonTemp - 360;
    }
    if (latTemp < 0) {
      latFormat = "南緯 ${latTemp.abs()} 度";
    } else {
      latFormat = "北緯 $latTemp 度";
    }
    if (lonTemp < 0) {
      lonFormat = "西經 ${lonTemp.abs()} 度";
    } else {
      lonFormat = "東經 $lonTemp 度";
    }
    return "$latFormat　$lonFormat";
  }
}
