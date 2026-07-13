// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Rts _$RtsFromJson(Map<String, dynamic> json) => _Rts(
  station:
      (json['station'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, RtsStation.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, RtsStation>{},
  box: json['box'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  intensities: json['int'] as List<dynamic>? ?? const <dynamic>[],
  time: (json['time'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RtsToJson(_Rts instance) => <String, dynamic>{
  'station': instance.station.map((k, e) => MapEntry(k, e.toJson())),
  'box': instance.box,
  'int': instance.intensities,
  'time': instance.time,
};

_RtsStation _$RtsStationFromJson(Map<String, dynamic> json) => _RtsStation(
  pga: (json['pga'] as num?)?.toDouble() ?? 0.0,
  pgv: (json['pgv'] as num?)?.toDouble() ?? 0.0,
  intensityRaw: (json['i'] as num?)?.toDouble() ?? 0.0,
  intensity: (json['I'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RtsStationToJson(_RtsStation instance) =>
    <String, dynamic>{
      'pga': instance.pga,
      'pgv': instance.pgv,
      'i': instance.intensityRaw,
      'I': instance.intensity,
    };
