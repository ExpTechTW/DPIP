// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eew.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Eew _$EewFromJson(Map<String, dynamic> json) => _Eew(
  agency: json['author'] as String,
  id: json['id'] as String,
  serial: (json['serial'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  isFinal: boolishInt(json['final']),
  info: EewInfo.fromJson(json['eq'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EewToJson(_Eew instance) => <String, dynamic>{
  'author': instance.agency,
  'id': instance.id,
  'serial': instance.serial,
  'status': instance.status,
  'final': intFromBool(instance.isFinal),
  'eq': instance.info.toJson(),
};

_EewInfo _$EewInfoFromJson(Map<String, dynamic> json) => _EewInfo(
  time: (json['time'] as num).toInt(),
  longitude: (json['lon'] as num).toDouble(),
  latitude: (json['lat'] as num).toDouble(),
  depth: (json['depth'] as num).toDouble(),
  magnitude: (json['mag'] as num).toDouble(),
  location: json['loc'] as String,
  max: (json['max'] as num).toInt(),
);

Map<String, dynamic> _$EewInfoToJson(_EewInfo instance) => <String, dynamic>{
  'time': instance.time,
  'lon': instance.longitude,
  'lat': instance.latitude,
  'depth': instance.depth,
  'mag': instance.magnitude,
  'loc': instance.location,
  'max': instance.max,
};
