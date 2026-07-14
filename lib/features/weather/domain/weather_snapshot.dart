/// The latest weather observation snapshot, decoded from v5's field-arrays.
library;

import 'package:dpip/core/network/meteor_decode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_snapshot.freezed.dart';

/// One station's latest observation. Built from the parallel field-arrays (not
/// from a per-station JSON object), so it has no `fromJson`; nullable fields are
/// the API's `-99` missing sentinel decoded to null.
@freezed
abstract class WeatherObservation with _$WeatherObservation {
  const factory WeatherObservation({
    /// 6-char station code (the `/station` directory key).
    required String id,

    /// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300;
    /// 0 = no data).
    required int weatherCode,
    double? temperature,
    int? humidity,
    double? pressure,
    int? windDirection,
    double? windSpeed,
    double? gustSpeed,
    int? gustDirection,
    double? high,
    double? low,
  }) = _WeatherObservation;
}

/// A weather snapshot: the observation [time] and one [WeatherObservation] per
/// station, aligned by index to the station directory.
@freezed
abstract class WeatherSnapshot with _$WeatherSnapshot {
  const factory WeatherSnapshot({
    required int time,
    required List<WeatherObservation> stations,
  }) = _WeatherSnapshot;

  /// Decodes the raw `{ time, ids, wx[], temp[], rh[], … }` field-array payload,
  /// aligning each parallel array by index and mapping `-99` → null.
  factory WeatherSnapshot.decode(Map<String, dynamic> json) {
    final ids = (json['ids'] as List).cast<String>();
    List<dynamic> column(String key) => (json[key] as List?) ?? const [];
    final wx = column('wx');
    final temp = column('temp');
    final rh = column('rh');
    final pres = column('pres');
    final wdir = column('wdir');
    final wspd = column('wspd');
    final gspd = column('gspd');
    final gdir = column('gdir');
    final hi = column('hi');
    final lo = column('lo');
    return WeatherSnapshot(
      time: (json['time'] as num).toInt(),
      stations: [
        for (var i = 0; i < ids.length; i++)
          WeatherObservation(
            id: ids[i],
            weatherCode: (wx.elementAtOrNull(i) as num?)?.toInt() ?? 0,
            temperature: MeteorDecode.real(temp.elementAtOrNull(i)),
            humidity: MeteorDecode.integer(rh.elementAtOrNull(i)),
            pressure: MeteorDecode.real(pres.elementAtOrNull(i)),
            windDirection: MeteorDecode.integer(wdir.elementAtOrNull(i)),
            windSpeed: MeteorDecode.real(wspd.elementAtOrNull(i)),
            gustSpeed: MeteorDecode.real(gspd.elementAtOrNull(i)),
            gustDirection: MeteorDecode.integer(gdir.elementAtOrNull(i)),
            high: MeteorDecode.real(hi.elementAtOrNull(i)),
            low: MeteorDecode.real(lo.elementAtOrNull(i)),
          ),
      ],
    );
  }
}
