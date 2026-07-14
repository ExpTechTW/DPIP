/// The latest lightning-strike snapshot, decoded from v5's parallel arrays.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'lightning_snapshot.freezed.dart';

/// One lightning strike. Built from the parallel field-arrays (not from a
/// per-strike JSON object), so it has no `fromJson`; [type] is `0`
/// cloud-to-cloud or `1` cloud-to-ground, [time] the strike's own Unix second.
@freezed
abstract class LightningStrike with _$LightningStrike {
  const factory LightningStrike({
    /// Discharge type: `0` = cloud-to-cloud, `1` = cloud-to-ground.
    required int type,

    /// The strike's own timestamp (Unix seconds).
    required int time,
    required double latitude,
    required double longitude,
  }) = _LightningStrike;
}

/// A lightning snapshot: the snapshot [time] and every [LightningStrike] it
/// carries. Lightning has no station directory — strikes are events aligned only
/// across the parallel `type` / `t` / `lat` / `lon` arrays by index.
@freezed
abstract class LightningSnapshot with _$LightningSnapshot {
  const factory LightningSnapshot({
    required int time,
    required List<LightningStrike> strikes,
  }) = _LightningSnapshot;

  /// Decodes the raw `{ time, type[], t[], lat[], lon[] }` field-array payload,
  /// aligning each parallel array by index into one [LightningStrike] per entry.
  factory LightningSnapshot.decode(Map<String, dynamic> json) {
    List<dynamic> column(String key) => (json[key] as List?) ?? const [];
    final type = column('type');
    final t = column('t');
    final lat = column('lat');
    final lon = column('lon');
    return LightningSnapshot(
      time: (json['time'] as num).toInt(),
      strikes: [
        for (var i = 0; i < type.length; i++)
          LightningStrike(
            type: (type[i] as num).toInt(),
            time: (t[i] as num).toInt(),
            latitude: (lat[i] as num).toDouble(),
            longitude: (lon[i] as num).toDouble(),
          ),
      ],
    );
  }
}
