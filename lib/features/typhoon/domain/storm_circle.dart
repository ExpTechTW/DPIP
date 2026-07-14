/// A typhoon's asymmetric storm-wind circle — v5 track `now.c15` / `now.c25`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'storm_circle.freezed.dart';
part 'storm_circle.g.dart';

/// Per-quadrant storm-wind radii (km) — the one field that captures the storm
/// field's asymmetry (SE largest, NW smallest). Test whether a point lies inside
/// the wind field with the four quadrants, **not** the symmetric [avg] circle.
///
/// `now.c15` is the level-7 (gale) circle and `now.c25` the level-10 circle;
/// either is `null` when the system is too weak to define one.
@freezed
abstract class StormCircle with _$StormCircle {
  const factory StormCircle({
    /// Mean radius (km).
    required double avg,

    /// North-east quadrant radius (km).
    required double ne,

    /// South-east quadrant radius (km).
    required double se,

    /// South-west quadrant radius (km).
    required double sw,

    /// North-west quadrant radius (km).
    required double nw,
  }) = _StormCircle;

  factory StormCircle.fromJson(Map<String, dynamic> json) =>
      _$StormCircleFromJson(json);
}
