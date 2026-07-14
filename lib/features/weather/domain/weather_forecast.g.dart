// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_forecast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeatherForecast _$WeatherForecastFromJson(Map<String, dynamic> json) =>
    _WeatherForecast(
      updateTime: (json['updateTime'] as num).toInt(),
      forecast: (json['forecast'] as List<dynamic>)
          .map((e) => WeatherForecastPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WeatherForecastToJson(_WeatherForecast instance) =>
    <String, dynamic>{
      'updateTime': instance.updateTime,
      'forecast': instance.forecast.map((e) => e.toJson()).toList(),
    };

_WeatherForecastPoint _$WeatherForecastPointFromJson(
  Map<String, dynamic> json,
) => _WeatherForecastPoint(
  time: json['time'] as String,
  temperature: (json['temperature'] as num).toDouble(),
  apparentTemp: (json['apparentTemp'] as num).toDouble(),
  humidity: (json['humidity'] as num).toInt(),
  weather: json['weather'] as String,
  weatherCode: (json['weatherCode'] as num).toInt(),
  pop: (json['pop'] as num).toInt(),
  wind: ForecastWind.fromJson(json['wind'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WeatherForecastPointToJson(
  _WeatherForecastPoint instance,
) => <String, dynamic>{
  'time': instance.time,
  'temperature': instance.temperature,
  'apparentTemp': instance.apparentTemp,
  'humidity': instance.humidity,
  'weather': instance.weather,
  'weatherCode': instance.weatherCode,
  'pop': instance.pop,
  'wind': instance.wind.toJson(),
};

_ForecastWind _$ForecastWindFromJson(Map<String, dynamic> json) =>
    _ForecastWind(
      direction: json['direction'] as String,
      speed: (json['speed'] as num).toDouble(),
      beaufort: (json['beaufort'] as num).toInt(),
    );

Map<String, dynamic> _$ForecastWindToJson(_ForecastWind instance) =>
    <String, dynamic>{
      'direction': instance.direction,
      'speed': instance.speed,
      'beaufort': instance.beaufort,
    };
