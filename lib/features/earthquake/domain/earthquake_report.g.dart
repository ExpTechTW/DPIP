// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earthquake_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarthquakeReport _$EarthquakeReportFromJson(Map<String, dynamic> json) =>
    _EarthquakeReport(
      id: json['id'] as String,
      longitude: (json['lon'] as num).toDouble(),
      latitude: (json['lat'] as num).toDouble(),
      location: json['loc'] as String,
      depth: (json['depth'] as num).toDouble(),
      magnitude: (json['mag'] as num).toDouble(),
      list: (json['list'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, AreaIntensity.fromJson(e as Map<String, dynamic>)),
      ),
      time: (json['time'] as num).toInt(),
      trem: (json['trem'] as num).toInt(),
    );

Map<String, dynamic> _$EarthquakeReportToJson(_EarthquakeReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lon': instance.longitude,
      'lat': instance.latitude,
      'loc': instance.location,
      'depth': instance.depth,
      'mag': instance.magnitude,
      'list': instance.list.map((k, e) => MapEntry(k, e.toJson())),
      'time': instance.time,
      'trem': instance.trem,
    };

_AreaIntensity _$AreaIntensityFromJson(Map<String, dynamic> json) =>
    _AreaIntensity(
      intensity: (json['int'] as num).toInt(),
      town: (json['town'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, StationIntensity.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$AreaIntensityToJson(_AreaIntensity instance) =>
    <String, dynamic>{
      'int': instance.intensity,
      'town': instance.town.map((k, e) => MapEntry(k, e.toJson())),
    };

_StationIntensity _$StationIntensityFromJson(Map<String, dynamic> json) =>
    _StationIntensity(
      longitude: (json['lon'] as num).toDouble(),
      latitude: (json['lat'] as num).toDouble(),
      intensity: (json['int'] as num).toInt(),
    );

Map<String, dynamic> _$StationIntensityToJson(_StationIntensity instance) =>
    <String, dynamic>{
      'lon': instance.longitude,
      'lat': instance.latitude,
      'int': instance.intensity,
    };
