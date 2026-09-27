// GENERATED CODE - DO NOT MODIFY BY HAND

// coverage:ignore-file

part of 'rts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Rts _$RtsFromJson(Map<String, dynamic> json) => _Rts(
  stations:
      (json['stations'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, RtsStation.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, RtsStation>{},
  time: (json['ts'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RtsToJson(_Rts instance) => <String, dynamic>{
  'stations': instance.stations.map((k, e) => MapEntry(k, e.toJson())),
  'ts': instance.time,
};

_RtsStation _$RtsStationFromJson(Map<String, dynamic> json) => _RtsStation(
  intensity: (json['i'] as num?)?.toDouble() ?? 0.0,
  pga: (json['pga'] as num?)?.toDouble() ?? 0.0,
  alert: json['alert'] == null ? false : boolishInt(json['alert']),
);

Map<String, dynamic> _$RtsStationToJson(_RtsStation instance) =>
    <String, dynamic>{
      'i': instance.intensity,
      'pga': instance.pga,
      'alert': intFromBool(instance.alert),
    };
