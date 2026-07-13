import 'package:freezed_annotation/freezed_annotation.dart';

part 'rts.freezed.dart';
part 'rts.g.dart';

/// A real-time station (RTS / TREM) shaking snapshot — the live intensity of
/// every reporting seismic station, plus any triggered area intensities.
///
/// This is the payload the RTS feed streams (`/api/v2/trem/rts?sse=1`, the same
/// JSON the plain GET returns). It is a continuous ~1 Hz feed, so the realtime
/// source keys freshness off event recency (not [time], to stay clock-skew
/// immune); [time] is the snapshot's server instant, kept for display. `box` /
/// `intensities` stay flexibly typed (empty while calm) until the RTS map
/// consumes them.
@freezed
abstract class Rts with _$Rts {
  const factory Rts({
    @Default(<String, RtsStation>{}) Map<String, RtsStation> station,
    @Default(<String, dynamic>{}) Map<String, dynamic> box,
    @JsonKey(name: 'int') @Default(<dynamic>[]) List<dynamic> intensities,
    @Default(0) int time,
  }) = _Rts;

  factory Rts.fromJson(Map<String, dynamic> json) => _$RtsFromJson(json);
}

/// One station's live shaking: peak ground acceleration / velocity and its
/// intensity as both the raw float ([intensityRaw], wire `i`) and the rounded
/// level ([intensity], wire `I`).
@freezed
abstract class RtsStation with _$RtsStation {
  const factory RtsStation({
    @Default(0.0) double pga,
    @Default(0.0) double pgv,
    @JsonKey(name: 'i') @Default(0.0) double intensityRaw,
    @JsonKey(name: 'I') @Default(0) int intensity,
  }) = _RtsStation;

  factory RtsStation.fromJson(Map<String, dynamic> json) =>
      _$RtsStationFromJson(json);
}
