// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typhoon_potential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ForecastPoint _$ForecastPointFromJson(Map<String, dynamic> json) =>
    _ForecastPoint(
      label: json['label'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$ForecastPointToJson(_ForecastPoint instance) =>
    <String, dynamic>{
      'label': instance.label,
      'lat': instance.latitude,
      'lng': instance.longitude,
    };
