// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'town.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Town _$TownFromJson(Map<String, dynamic> json) => _Town(
  code: json['code'] as String,
  city: json['city'] as String,
  town: json['town'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  cityLevel: json['cityLevel'] as String,
  townLevel: json['townLevel'] as String,
);

Map<String, dynamic> _$TownToJson(_Town instance) => <String, dynamic>{
  'code': instance.code,
  'city': instance.city,
  'town': instance.town,
  'lat': instance.lat,
  'lng': instance.lng,
  'cityLevel': instance.cityLevel,
  'townLevel': instance.townLevel,
};
