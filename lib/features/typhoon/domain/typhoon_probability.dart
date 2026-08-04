/// Storm-wind-circle strike probability — v5
/// `GET /api/v5/meteor/typhoon/probability` (dataset 003).
/// Multi-storm: `{ updated, cyclones: [{ tdNo, levels }] }`.
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

/// One cyclone's strike-probability contours.
@freezed
abstract class CycloneProbability with _$CycloneProbability {
  const factory CycloneProbability({
    /// CWA tropical-depression number; may be blank when upstream can't match.
    String? tdNo,
    required List<ProbabilityLevel> levels,
  }) = _CycloneProbability;

  factory CycloneProbability.decode(Map<String, dynamic> json) =>
      CycloneProbability(
        tdNo: _blankToNull(json['tdNo'] as String?),
        levels: [
          for (final level in (json['levels'] as List? ?? const []))
            ProbabilityLevel.decode(level as Map<String, dynamic>),
        ],
      );
}

/// The `GET /probability` payload: update time + per-cyclone contours.
@freezed
abstract class TyphoonProbability with _$TyphoonProbability {
  const factory TyphoonProbability({
    required int updated,
    required List<CycloneProbability> cyclones,
  }) = _TyphoonProbability;

  /// Decodes `{ updated, cyclones: [{ tdNo, levels }] }`.
  factory TyphoonProbability.decode(Map<String, dynamic> json) {
    final updated = (json['updated'] as num?)?.toInt() ?? 0;
    final raw = json['cyclones'];
    if (raw is! List) {
      return TyphoonProbability(updated: updated, cyclones: const []);
    }
    return TyphoonProbability(
      updated: updated,
      cyclones: [
        for (final c in raw)
          if (c is Map<String, dynamic>) CycloneProbability.decode(c),
      ],
    );
  }
}

String? _blankToNull(String? value) {
  final t = value?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// Maps a list of `[lng, lat]` pairs to [LatLng]s (mind the GeoJSON axis order);
/// empty/absent in → empty out.
List<LatLng> _coords(Object? raw) => [
  for (final p in (raw as List? ?? const []))
    LatLng(((p as List)[1] as num).toDouble(), (p[0] as num).toDouble()),
];
