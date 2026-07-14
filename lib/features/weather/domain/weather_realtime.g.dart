// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_realtime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeatherRealtime _$WeatherRealtimeFromJson(Map<String, dynamic> json) =>
    _WeatherRealtime(
      id: json['id'] as String,
      station: WeatherRealtimeStation.fromJson(
        json['station'] as Map<String, dynamic>,
      ),
      time: (json['time'] as num).toInt(),
      data: WeatherRealtimeData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WeatherRealtimeToJson(_WeatherRealtime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'station': instance.station.toJson(),
      'time': instance.time,
      'data': instance.data.toJson(),
    };

_WeatherRealtimeStation _$WeatherRealtimeStationFromJson(
  Map<String, dynamic> json,
) => _WeatherRealtimeStation(
  name: json['name'] as String,
  latitude: (json['lat'] as num).toDouble(),
  longitude: (json['lon'] as num).toDouble(),
  altitude: (json['altitude'] as num).toDouble(),
  distance: (json['distance'] as num).toDouble(),
);

Map<String, dynamic> _$WeatherRealtimeStationToJson(
  _WeatherRealtimeStation instance,
) => <String, dynamic>{
  'name': instance.name,
  'lat': instance.latitude,
  'lon': instance.longitude,
  'altitude': instance.altitude,
  'distance': instance.distance,
};

_WeatherRealtimeData _$WeatherRealtimeDataFromJson(Map<String, dynamic> json) =>
    _WeatherRealtimeData(
      weather: json['weather'] as String,
      weatherCode: (json['weatherCode'] as num).toInt(),
      temperature: MeteorDecode.real(json['temperature']),
      humidity: MeteorDecode.integer(json['humidity']),
      rain: MeteorDecode.real(json['rain']),
      wind: WeatherWind.fromJson(json['wind'] as Map<String, dynamic>),
      gust: WeatherWind.fromJson(json['gust'] as Map<String, dynamic>),
      visibility: MeteorDecode.real(json['visibility']),
      visibilityText: json['visibility_text'] as String?,
      pressure: MeteorDecode.real(json['pressure']),
      sunshine: MeteorDecode.real(json['sunshine']),
    );

Map<String, dynamic> _$WeatherRealtimeDataToJson(
  _WeatherRealtimeData instance,
) => <String, dynamic>{
  'weather': instance.weather,
  'weatherCode': instance.weatherCode,
  'temperature': instance.temperature,
  'humidity': instance.humidity,
  'rain': instance.rain,
  'wind': instance.wind.toJson(),
  'gust': instance.gust.toJson(),
  'visibility': instance.visibility,
  'visibility_text': instance.visibilityText,
  'pressure': instance.pressure,
  'sunshine': instance.sunshine,
};

_WeatherWind _$WeatherWindFromJson(Map<String, dynamic> json) => _WeatherWind(
  direction: json['direction'] as String?,
  speed: MeteorDecode.real(json['speed']),
  beaufort: MeteorDecode.integer(json['beaufort']),
);

Map<String, dynamic> _$WeatherWindToJson(_WeatherWind instance) =>
    <String, dynamic>{
      'direction': instance.direction,
      'speed': instance.speed,
      'beaufort': instance.beaufort,
    };
