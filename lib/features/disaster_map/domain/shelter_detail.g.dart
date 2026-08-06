// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelter_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShelterDetail _$ShelterDetailFromJson(Map<String, dynamic> json) =>
    _ShelterDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      category:
          (json['category'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      indoor: json['indoor'] as bool? ?? false,
      outdoor: json['outdoor'] as bool? ?? false,
      vulnerableOk: json['vulnerable_ok'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
    );

Map<String, dynamic> _$ShelterDetailToJson(_ShelterDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'capacity': instance.capacity,
      'category': instance.category,
      'indoor': instance.indoor,
      'outdoor': instance.outdoor,
      'vulnerable_ok': instance.vulnerableOk,
      'lat': instance.lat,
      'lng': instance.lng,
      'address': instance.address,
    };
