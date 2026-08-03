// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partial_earthquake_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PartialEarthquakeReport _$PartialEarthquakeReportFromJson(
  Map<String, dynamic> json,
) => _PartialEarthquakeReport(
  id: json['id'] as String,
  longitude: (json['lon'] as num).toDouble(),
  latitude: (json['lat'] as num).toDouble(),
  location: json['loc'] as String,
  depth: (json['depth'] as num).toDouble(),
  magnitude: (json['mag'] as num).toDouble(),
  intensity: (json['int'] as num).toInt(),
  time: (json['time'] as num).toInt(),
  trem: (json['trem'] as num).toInt(),
  md5: json['md5'] as String,
);

Map<String, dynamic> _$PartialEarthquakeReportToJson(
  _PartialEarthquakeReport instance,
) => <String, dynamic>{
  'id': instance.id,
  'lon': instance.longitude,
  'lat': instance.latitude,
  'loc': instance.location,
  'depth': instance.depth,
  'mag': instance.magnitude,
  'int': instance.intensity,
  'time': instance.time,
  'trem': instance.trem,
  'md5': instance.md5,
};
