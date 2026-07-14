/// Storm-wind-circle strike probability — v5
/// `GET /api/v5/meteor/typhoon/probability` (dataset 003).
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'typhoon_probability.freezed.dart';

/// One nested strike-probability contour: the probability [p] (%) and its closed
/// `[lng, lat]` polygon. Levels descend 100 → 20 (100 innermost, 20 outermost);
/// each ring is suitable for overlay or point-in-polygon.
@freezed
abstract class ProbabilityLevel with _$ProbabilityLevel {
  const factory ProbabilityLevel({
    /// Strike probability (%).
    required int p,

    /// Closed contour ring, custom-decoded from `[lng, lat]` pairs.
    required List<LatLng> coords,
  }) = _ProbabilityLevel;

  /// Decodes `{ p, coords: [[lng, lat], …] }`, mapping each pair to a [LatLng].
  factory ProbabilityLevel.decode(Map<String, dynamic> json) =>
      ProbabilityLevel(
        p: (json['p'] as num).toInt(),
        coords: _coords(json['coords']),
      );
}

/// The `GET /probability` payload: the update time and the probability contours.
/// `levels` is empty when no strike probability is active.
@freezed
abstract class TyphoonProbability with _$TyphoonProbability {
  const factory TyphoonProbability({
    required int updated,
    required List<ProbabilityLevel> levels,
  }) = _TyphoonProbability;

  /// Decodes `{ updated, levels: [{ p, coords }, …] }`.
  factory TyphoonProbability.decode(Map<String, dynamic> json) =>
      TyphoonProbability(
        updated: (json['updated'] as num).toInt(),
        levels: [
          for (final level in (json['levels'] as List? ?? const []))
            ProbabilityLevel.decode(level as Map<String, dynamic>),
        ],
      );
}

/// Maps a list of `[lng, lat]` pairs to [LatLng]s (mind the GeoJSON axis order);
/// empty/absent in → empty out.
List<LatLng> _coords(Object? raw) => [
  for (final p in (raw as List? ?? const []))
    LatLng(((p as List)[1] as num).toDouble(), (p[0] as num).toDouble()),
];
