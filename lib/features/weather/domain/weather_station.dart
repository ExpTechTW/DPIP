/// A weather observing station from the v5 `/weather/station` directory.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_station.freezed.dart';
part 'weather_station.g.dart';

/// One entry of the static station directory (`{ code: {n,c,t,alt,lat,lon} }`),
/// keyed by the 6-char station code. The catalogue is fetched once (ETag-cached)
/// and joined by index to the latest field-array snapshot.
@freezed
abstract class WeatherStation with _$WeatherStation {
  const factory WeatherStation({
    @JsonKey(name: 'n') required String name,
    @JsonKey(name: 'c') required String county,
    @JsonKey(name: 't') required String town,
    @JsonKey(name: 'alt') required double altitude,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,
  }) = _WeatherStation;

  factory WeatherStation.fromJson(Map<String, dynamic> json) =>
      _$WeatherStationFromJson(json);
}
