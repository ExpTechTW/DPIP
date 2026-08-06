// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restroom_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RestroomDetail _$RestroomDetailFromJson(Map<String, dynamic> json) =>
    _RestroomDetail(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      type: (json['type'] as num?)?.toInt() ?? 0,
      type2: (json['type2'] as num?)?.toInt() ?? 0,
      typegrade: (json['typegrade'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RestroomDetailToJson(_RestroomDetail instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'type': instance.type,
      'type2': instance.type2,
      'typegrade': instance.typegrade,
    };
