// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storm_circle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StormCircle _$StormCircleFromJson(Map<String, dynamic> json) => _StormCircle(
  avg: (json['avg'] as num).toDouble(),
  ne: (json['ne'] as num).toDouble(),
  se: (json['se'] as num).toDouble(),
  sw: (json['sw'] as num).toDouble(),
  nw: (json['nw'] as num).toDouble(),
);

Map<String, dynamic> _$StormCircleToJson(_StormCircle instance) =>
    <String, dynamic>{
      'avg': instance.avg,
      'ne': instance.ne,
      'se': instance.se,
      'sw': instance.sw,
      'nw': instance.nw,
    };
