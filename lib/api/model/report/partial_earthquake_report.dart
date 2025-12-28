import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/serialization.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:timezone/timezone.dart';

part 'partial_earthquake_report.g.dart';

@JsonSerializable()
class PartialEarthquakeReport {
  final String id;

  @JsonKey(name: 'lon')
  final double longitude;

  @JsonKey(name: 'lat')
  final double latitude;

  @JsonKey(name: 'loc')
  final String location;

  final double depth;

  @JsonKey(name: 'mag')
  final double magnitude;

  @JsonKey(name: 'int')
  final int intensity;

  @JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)
  final TZDateTime time;

  final int trem;
  final String md5;

  PartialEarthquakeReport({
    required this.id,
    required this.longitude,
    required this.latitude,
    required this.location,
    required this.depth,
    required this.magnitude,
    required this.intensity,
    required this.time,
    required this.trem,
    required this.md5,
  });

  factory PartialEarthquakeReport.fromJson(Map<String, dynamic> json) =>
      _$PartialEarthquakeReportFromJson(json);

  Map<String, dynamic> toJson() => _$PartialEarthquakeReportToJson(this);

  String? get number {
    final n = id.split('-').first;

    if (!n.endsWith('000')) {
      return n;
    }

    return null;
  }

  LatLng get latlng => LatLng(latitude, longitude);

  bool get hasNumber => number != null;

  Uri get reportUrl {
    final arr = id.split('-');
    arr.removeAt(0);
    final mag = '${(magnitude * 10).floor()}';

    if (hasNumber) {
      final id = number!.substring(3);
      return Uri.parse(
        'https://scweb.cwa.gov.tw/zh-tw/earthquake/details/${arr.join()}$mag$id',
      );
    }

    return Uri.parse(
      'https://scweb.cwa.gov.tw/zh-tw/earthquake/details/${arr.join()}$mag',
    );
  }

  String get reportImageName {
    final year = time.year.toString();
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final mag = '${(magnitude * 10).floor()}';

    if (hasNumber) {
      final id = number!.substring(3);
      return '$year$month$day$hour$minute$second$mag${id}_H.png';
    }

    return '$year$month$day$hour$minute$second${mag}_H.png';
  }

  String get reportImageUrl {
    final name = reportImageName;
    final time = name.substring(0, 6);
    return 'https://scweb.cwa.gov.tw/webdata/OLDEQ/$time/$reportImageName';
  }

  String? get mapImageBaseName {
    if (!hasNumber) return null;

    final year = time.year.toString();
    final id = number!.substring(3);

    return '$year$id';
  }

  String get traceBaseUrl {
    final year = time.year.toString();
    return 'https://scweb.cwa.gov.tw/webdata/drawTrace/plotContour/$year';
  }

  String? get intensityMapImageName {
    if (!hasNumber) return null;

    return '${mapImageBaseName}i.png';
  }

  String? get intensityMapImageUrl => intensityMapImageName == null
      ? null
      : '$traceBaseUrl/$intensityMapImageName';

  String? get pgaMapImageName {
    if (!hasNumber) return null;

    return '${mapImageBaseName}a.png';
  }

  String? get pgaMapImageUrl =>
      pgaMapImageName == null ? null : '$traceBaseUrl/$pgaMapImageName';

  String? get pgvMapImageName {
    if (!hasNumber) return null;

    return '${mapImageBaseName}v.png';
  }

  String? get pgvMapImageUrl =>
      pgvMapImageName == null ? null : '$traceBaseUrl/$pgvMapImageName';

  String extractLocation() {
    if (location.contains('(')) {
      return location.substring(
        location.indexOf('(') + 3,
        location.indexOf(')'),
      );
    } else {
      return location.substring(0, location.indexOf('方') + 1);
    }
  }

  Color getReportColor() {
    if (magnitude > 6.5 && intensity >= 7) {
      return Colors.red;
    }
    if (magnitude > 6.0 && intensity >= 5) {
      return Colors.orange;
    }
    if (magnitude > 5.5 && intensity >= 4) {
      return Colors.yellow;
    }
    return Colors.green;
  }

  GeoJsonFeatureBuilder toGeoJsonFeature() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
        .setId(time.millisecondsSinceEpoch)
        .setGeometry(latlng.asGeoJsonCooridnate)
        .setProperty('icon', 'cross-$intensity')
        .setProperty('magnitude', magnitude)
        .setProperty('intensity', intensity)
        .setProperty('time', time.millisecondsSinceEpoch)
        .setProperty('depth', depth);
  }
}
