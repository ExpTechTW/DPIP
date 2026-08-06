// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aed_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AedDetail _$AedDetailFromJson(Map<String, dynamic> json) => _AedDetail(
  id: (json['id'] as num).toInt(),
  aedId: json['aed_id'] as String,
  name: json['name'] as String,
  city: json['city'] as String? ?? '',
  district: json['district'] as String? ?? '',
  category: json['category'] as String? ?? '',
  type: json['type'] as String? ?? '',
  place: json['place'] as String? ?? '',
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  address: json['address'] as String? ?? '',
  description: json['description'] as String? ?? '',
  placeDesc: json['place_desc'] as String? ?? '',
  weekdayStart: json['weekday_start'] as String? ?? '',
  weekdayEnd: json['weekday_end'] as String? ?? '',
  saturdayStart: json['saturday_start'] as String? ?? '',
  saturdayEnd: json['saturday_end'] as String? ?? '',
  sundayStart: json['sunday_start'] as String? ?? '',
  sundayEnd: json['sunday_end'] as String? ?? '',
  openRemark: json['open_remark'] as String? ?? '',
  emergencyPhone: json['emergency_phone'] as String? ?? '',
  placeId: json['place_id'] as String? ?? '',
);

Map<String, dynamic> _$AedDetailToJson(_AedDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'aed_id': instance.aedId,
      'name': instance.name,
      'city': instance.city,
      'district': instance.district,
      'category': instance.category,
      'type': instance.type,
      'place': instance.place,
      'lat': instance.lat,
      'lng': instance.lng,
      'address': instance.address,
      'description': instance.description,
      'place_desc': instance.placeDesc,
      'weekday_start': instance.weekdayStart,
      'weekday_end': instance.weekdayEnd,
      'saturday_start': instance.saturdayStart,
      'saturday_end': instance.saturdayEnd,
      'sunday_start': instance.sundayStart,
      'sunday_end': instance.sundayEnd,
      'open_remark': instance.openRemark,
      'emergency_phone': instance.emergencyPhone,
      'place_id': instance.placeId,
    };
