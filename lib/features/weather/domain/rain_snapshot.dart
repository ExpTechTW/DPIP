/// The latest rainfall accumulation snapshot, decoded from v5's field-arrays.
library;

import 'package:dpip/core/network/meteor_decode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rain_snapshot.freezed.dart';

/// One station's accumulated rainfall (mm) across the nine reporting windows.
/// Built from the parallel field-arrays (not from a per-station JSON object), so
/// it has no `fromJson`; nullable fields are the API's `-99` missing sentinel
/// decoded to null.
@freezed
abstract class RainObservation with _$RainObservation {
  const factory RainObservation({
    /// 6-char station code (the `/station` directory key).
    required String id,

    /// Accumulation since the top of the current period (`now`).
    double? now,

    /// Last 10 minutes (`10m`).
    double? min10,

    /// Last 1 hour (`1h`).
    double? hour1,

    /// Last 3 hours (`3h`).
    double? hour3,

    /// Last 6 hours (`6h`).
    double? hour6,

    /// Last 12 hours (`12h`).
    double? hour12,

    /// Last 24 hours (`24h`).
    double? hour24,

    /// Last 2 days (`2d`).
    double? day2,

    /// Last 3 days (`3d`).
    double? day3,
  }) = _RainObservation;
}

/// A rainfall snapshot: the observation [time] and one [RainObservation] per
/// station, aligned by index to the station directory.
@freezed
abstract class RainSnapshot with _$RainSnapshot {
  const factory RainSnapshot({
    required int time,
    required List<RainObservation> stations,
  }) = _RainSnapshot;

  /// Decodes the raw `{ time, ids, now[], 10m[], 1h[], … }` field-array payload,
  /// aligning each parallel array by index and mapping `-99` → null.
  factory RainSnapshot.decode(Map<String, dynamic> json) {
    final ids = (json['ids'] as List).cast<String>();
    List<dynamic> column(String key) => (json[key] as List?) ?? const [];
    final now = column('now');
    final min10 = column('10m');
    final hour1 = column('1h');
    final hour3 = column('3h');
    final hour6 = column('6h');
    final hour12 = column('12h');
    final hour24 = column('24h');
    final day2 = column('2d');
    final day3 = column('3d');
    return RainSnapshot(
      time: (json['time'] as num).toInt(),
      stations: [
        for (var i = 0; i < ids.length; i++)
          RainObservation(
            id: ids[i],
            now: MeteorDecode.real(now.elementAtOrNull(i)),
            min10: MeteorDecode.real(min10.elementAtOrNull(i)),
            hour1: MeteorDecode.real(hour1.elementAtOrNull(i)),
            hour3: MeteorDecode.real(hour3.elementAtOrNull(i)),
            hour6: MeteorDecode.real(hour6.elementAtOrNull(i)),
            hour12: MeteorDecode.real(hour12.elementAtOrNull(i)),
            hour24: MeteorDecode.real(hour24.elementAtOrNull(i)),
            day2: MeteorDecode.real(day2.elementAtOrNull(i)),
            day3: MeteorDecode.real(day3.elementAtOrNull(i)),
          ),
      ],
    );
  }
}
