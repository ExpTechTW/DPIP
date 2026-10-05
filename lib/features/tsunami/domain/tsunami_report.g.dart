// GENERATED CODE - DO NOT MODIFY BY HAND

// coverage:ignore-file

part of 'tsunami_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TsunamiEarthquake _$TsunamiEarthquakeFromJson(Map<String, dynamic> json) =>
    _TsunamiEarthquake(
      time: (json['t'] as num).toInt(),
      longitude: (json['lon'] as num).toDouble(),
      latitude: (json['lat'] as num).toDouble(),
      location: json['loc'] as String,
      depth: (json['dep'] as num).toDouble(),
      magnitude: (json['mag'] as num).toDouble(),
    );

Map<String, dynamic> _$TsunamiEarthquakeToJson(_TsunamiEarthquake instance) =>
    <String, dynamic>{
      't': instance.time,
      'lon': instance.longitude,
      'lat': instance.latitude,
      'loc': instance.location,
      'dep': instance.depth,
      'mag': instance.magnitude,
    };

_TsunamiBulletin _$TsunamiBulletinFromJson(Map<String, dynamic> json) =>
    _TsunamiBulletin(
      id: json['id'] as String,
      number: (json['no'] as num).toInt(),
      report: json['rep'] as String,
      type: json['type'] as String,
      sent: (json['sent'] as num).toInt(),
    );

Map<String, dynamic> _$TsunamiBulletinToJson(_TsunamiBulletin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'no': instance.number,
      'rep': instance.report,
      'type': instance.type,
      'sent': instance.sent,
    };
