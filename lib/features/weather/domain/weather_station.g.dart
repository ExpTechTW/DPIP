// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_station.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeatherStation _$WeatherStationFromJson(Map<String, dynamic> json) =>
    _WeatherStation(
      name: json['n'] as String,
      county: json['c'] as String,
      town: json['t'] as String,
      altitude: (json['alt'] as num).toDouble(),
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
    );

Map<String, dynamic> _$WeatherStationToJson(_WeatherStation instance) =>
    <String, dynamic>{
      'n': instance.name,
      'c': instance.county,
      't': instance.town,
      'alt': instance.altitude,
      'lat': instance.latitude,
      'lon': instance.longitude,
    };
