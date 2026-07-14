// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typhoon_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrackFix _$TrackFixFromJson(Map<String, dynamic> json) => _TrackFix(
  time: (json['t'] as num).toInt(),
  latitude: (json['lat'] as num).toDouble(),
  longitude: (json['lon'] as num).toDouble(),
  wind: (json['wind'] as num?)?.toDouble(),
  gust: (json['gust'] as num?)?.toDouble(),
  pressure: (json['pres'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TrackFixToJson(_TrackFix instance) => <String, dynamic>{
  't': instance.time,
  'lat': instance.latitude,
  'lon': instance.longitude,
  'wind': instance.wind,
  'gust': instance.gust,
  'pres': instance.pressure,
};

_TrackNow _$TrackNowFromJson(Map<String, dynamic> json) => _TrackNow(
  speed: (json['speed'] as num?)?.toDouble(),
  direction: json['dir'] as String?,
  move: (json['move'] as List<dynamic>?)?.map((e) => e as String).toList(),
  c15: json['c15'] == null
      ? null
      : StormCircle.fromJson(json['c15'] as Map<String, dynamic>),
  c25: json['c25'] == null
      ? null
      : StormCircle.fromJson(json['c25'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrackNowToJson(_TrackNow instance) => <String, dynamic>{
  'speed': instance.speed,
  'dir': instance.direction,
  'move': instance.move,
  'c15': instance.c15?.toJson(),
  'c25': instance.c25?.toJson(),
};

_TrackForecast _$TrackForecastFromJson(Map<String, dynamic> json) =>
    _TrackForecast(
      tau: (json['tau'] as num).toInt(),
      time: (json['t'] as num).toInt(),
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      wind: (json['wind'] as num?)?.toDouble(),
      gust: (json['gust'] as num?)?.toDouble(),
      pressure: (json['pres'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      direction: json['dir'] as String?,
      r15: (json['r15'] as num?)?.toDouble(),
      r70: (json['r70'] as num?)?.toDouble(),
      state: (json['state'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TrackForecastToJson(_TrackForecast instance) =>
    <String, dynamic>{
      'tau': instance.tau,
      't': instance.time,
      'lat': instance.latitude,
      'lon': instance.longitude,
      'wind': instance.wind,
      'gust': instance.gust,
      'pres': instance.pressure,
      'speed': instance.speed,
      'dir': instance.direction,
      'r15': instance.r15,
      'r70': instance.r70,
      'state': instance.state,
    };

_TyphoonTrack _$TyphoonTrackFromJson(Map<String, dynamic> json) =>
    _TyphoonTrack(
      name: json['name'] as String,
      cwaName: json['cwaName'] as String?,
      year: (json['year'] as num).toInt(),
      tdNo: json['tdNo'] as String?,
      tyNo: json['tyNo'] as String?,
      analysis: (json['analysis'] as List<dynamic>)
          .map((e) => TrackFix.fromJson(e as Map<String, dynamic>))
          .toList(),
      now: json['now'] == null
          ? null
          : TrackNow.fromJson(json['now'] as Map<String, dynamic>),
      forecast: (json['forecast'] as List<dynamic>)
          .map((e) => TrackForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TyphoonTrackToJson(_TyphoonTrack instance) =>
    <String, dynamic>{
      'name': instance.name,
      'cwaName': instance.cwaName,
      'year': instance.year,
      'tdNo': instance.tdNo,
      'tyNo': instance.tyNo,
      'analysis': instance.analysis.map((e) => e.toJson()).toList(),
      'now': instance.now?.toJson(),
      'forecast': instance.forecast.map((e) => e.toJson()).toList(),
    };

_TrackPayload _$TrackPayloadFromJson(Map<String, dynamic> json) =>
    _TrackPayload(
      updated: (json['updated'] as num).toInt(),
      cyclones: (json['cyclones'] as List<dynamic>)
          .map((e) => TyphoonTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrackPayloadToJson(_TrackPayload instance) =>
    <String, dynamic>{
      'updated': instance.updated,
      'cyclones': instance.cyclones.map((e) => e.toJson()).toList(),
    };
