import 'package:dpip/core/models/serialization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rts.freezed.dart';
part 'rts.g.dart';

/// One frame of the TREM real-time station network — `rts.v1`, the payload of
/// the live `trem.rts.v1` topic and of the `/api/v3/trem/rts/{seconds}`
/// archive alike, so live and replay decode through the one model.
///
/// It carries only what each station measured. The detection boxes and the
/// per-township levels the old v2 feed computed server-side (`box`, `int`) are
/// not on the wire any more: they are derived from the alerting stations on
/// the client (see `rts_alert_areas.dart`), which is also where the station
/// directory that places them lives.
///
/// [time] is the frame's server instant in milliseconds (`ts`), kept for
/// display; the live source keys freshness off event recency instead, so a
/// clock skew between server and device cannot reclassify a live feed. The
/// wire's `eq` list (quakes the network itself picked) is not read yet.
@freezed
abstract class Rts with _$Rts {
  const factory Rts({
    @Default(<String, RtsStation>{}) Map<String, RtsStation> stations,
    @JsonKey(name: 'ts') @Default(0) int time,
  }) = _Rts;

  factory Rts.fromJson(Map<String, dynamic> json) => _$RtsFromJson(json);
}

/// Whether two frames are the same — what a feed's `sameData` asks once a
/// second. `==` alone compares every station before the timestamp, a pass
/// over the whole map that allocates an entry per station, for frames that
/// almost always differ in `ts` anyway. The timestamp goes first: same answer,
/// and the deep comparison runs only for two frames stamped the same instant.
bool sameRtsFrame(Rts? a, Rts? b) =>
    identical(a, b) || (a != null && b != null && a.time == b.time && a == b);

/// One station's reading in a frame, keyed in [Rts.stations] by its hex
/// device id: the continuous JMA [intensity] (wire `i`; negative while calm,
/// `-3` with no signal), the peak ground acceleration [pga] in gal, and
/// whether the network has it [alert]ing.
@freezed
abstract class RtsStation with _$RtsStation {
  const factory RtsStation({
    @JsonKey(name: 'i') @Default(0.0) double intensity,
    // Left off the wire until the station has measured anything at all — a
    // required field would reject the whole frame over one new station.
    @Default(0.0) double pga,
    // Sent only as `1`, and only while alerting.
    @JsonKey(fromJson: boolishInt, toJson: intFromBool)
    @Default(false)
    bool alert,
  }) = _RtsStation;

  factory RtsStation.fromJson(Map<String, dynamic> json) =>
      _$RtsStationFromJson(json);
}
