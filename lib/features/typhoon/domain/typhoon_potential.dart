/// Track-potential forecast — v5 `GET /api/v5/meteor/typhoon/potential`
/// (dataset 002). Multi-storm: `{ updated, cyclones: [...] }`.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'typhoon_potential.freezed.dart';
part 'typhoon_potential.g.dart';

/// One labelled forecast waypoint on the potential track (a JSON object, so it
/// keeps a `fromJson`, unlike the bare `[lng, lat]` geometry arrays).
@freezed
abstract class ForecastPoint with _$ForecastPoint {
  const factory ForecastPoint({
    /// Human label from the wire (e.g. `07月14日14時`); display shortens via
    /// [shortenTyphoonTimeLabel] to `14日14時`.
    required String label,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lng') required double longitude,
  }) = _ForecastPoint;

  factory ForecastPoint.fromJson(Map<String, dynamic> json) =>
      _$ForecastPointFromJson(json);
}

/// One cyclone's track-potential geometry from dataset 002.
///
/// Geometry arrays are `[lng, lat]` (GeoJSON axis order). [cone] is unique to
/// 002. [circle] is a symmetric L7 ring (illustrative); null when too weak.
@freezed
abstract class TyphoonPotential with _$TyphoonPotential {
  const factory TyphoonPotential({
    /// CWA tropical-depression number — unique within a snapshot.
    String? tdNo,

    /// KML folder name (CWA Chinese name, or `TD15` for unnamed).
    String? name,

    /// Observed past track.
    required List<LatLng> past,

    /// Predicted track.
    required List<LatLng> forecast,

    /// Track-potential (uncertainty) cone outline.
    required List<LatLng> cone,

    /// Symmetric level-7 wind circle (illustrative); null when too weak.
    List<LatLng>? circle,

    /// Current centre; null when none.
    LatLng? current,

    /// Labelled forecast waypoints.
    required List<ForecastPoint> points,
  }) = _TyphoonPotential;

  /// Decodes one cyclone object, mapping every `[lng, lat]` pair to a [LatLng].
  factory TyphoonPotential.decode(Map<String, dynamic> json) =>
      TyphoonPotential(
        tdNo: _blankToNull(json['tdNo'] as String?),
        name: _blankToNull(json['name'] as String?),
        past: _coords(json['past']),
        forecast: _coords(json['forecast']),
        cone: _coords(json['cone']),
        circle: json['circle'] == null ? null : _coords(json['circle']),
        current: json['current'] == null
            ? null
            : _coord(json['current'] as List),
        points: [
          for (final p in (json['points'] as List? ?? const []))
            ForecastPoint.fromJson(p as Map<String, dynamic>),
        ],
      );
}

/// The `GET /potential` payload: update time + one entry per active cyclone.
@freezed
abstract class PotentialPayload with _$PotentialPayload {
  const factory PotentialPayload({
    required int updated,
    required List<TyphoonPotential> cyclones,
  }) = _PotentialPayload;

  /// Decodes `{ updated, cyclones: [...] }`. Missing/empty `cyclones` → [].
  factory PotentialPayload.decode(Map<String, dynamic> json) {
    final updated = (json['updated'] as num?)?.toInt() ?? 0;
    final raw = json['cyclones'];
    if (raw is! List) {
      return PotentialPayload(updated: updated, cyclones: const []);
    }
    return PotentialPayload(
      updated: updated,
      cyclones: [
        for (final c in raw)
          if (c is Map<String, dynamic>) TyphoonPotential.decode(c),
      ],
    );
  }
}

String? _blankToNull(String? value) {
  final t = value?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// Maps a single `[lng, lat]` pair to a [LatLng] (mind the GeoJSON axis order).
LatLng _coord(List<dynamic> pair) =>
    LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());

/// Maps a list of `[lng, lat]` pairs to [LatLng]s; empty/absent in → empty out.
List<LatLng> _coords(Object? raw) => [
  for (final p in (raw as List? ?? const [])) _coord(p as List),
];
