// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typhoon_cyclone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TyphoonCyclone _$TyphoonCycloneFromJson(Map<String, dynamic> json) =>
    _TyphoonCyclone(
      name: json['name'] as String,
      cwaName: json['cwaName'] as String?,
      year: (json['year'] as num).toInt(),
      tdNo: json['tdNo'] as String?,
      tyNo: json['tyNo'] as String?,
      time: (json['t'] as num).toInt(),
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      wind: (json['wind'] as num?)?.toDouble(),
      gust: (json['gust'] as num?)?.toDouble(),
      pressure: (json['pres'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      direction: json['dir'] as String?,
    );

Map<String, dynamic> _$TyphoonCycloneToJson(_TyphoonCyclone instance) =>
    <String, dynamic>{
      'name': instance.name,
      'cwaName': instance.cwaName,
      'year': instance.year,
      'tdNo': instance.tdNo,
      'tyNo': instance.tyNo,
      't': instance.time,
      'lat': instance.latitude,
      'lon': instance.longitude,
      'wind': instance.wind,
      'gust': instance.gust,
      'pres': instance.pressure,
      'speed': instance.speed,
      'dir': instance.direction,
    };

_CycloneIndex _$CycloneIndexFromJson(Map<String, dynamic> json) =>
    _CycloneIndex(
      updated: (json['updated'] as num).toInt(),
      cyclones: (json['cyclones'] as List<dynamic>)
          .map((e) => TyphoonCyclone.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CycloneIndexToJson(_CycloneIndex instance) =>
    <String, dynamic>{
      'updated': instance.updated,
      'cyclones': instance.cyclones.map((e) => e.toJson()).toList(),
    };
