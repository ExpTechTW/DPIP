/// Track-potential forecast — v5 `GET /api/v5/meteor/typhoon/potential`
/// (dataset 002). Multi-storm: `{ updated, cyclones: [...] }`.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/typhoon_decode.dart';
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
        tdNo: trimToNull(json['tdNo'] as String?),
        name: trimToNull(json['name'] as String?),
        past: latLngsFromPairs(json['past']),
        forecast: latLngsFromPairs(json['forecast']),
        cone: latLngsFromPairs(json['cone']),
        circle: json['circle'] == null
            ? null
            : latLngsFromPairs(json['circle']),
        current: json['current'] == null
            ? null
            : latLngFromPair(json['current'] as List),
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
  factory PotentialPayload.decode(Map<String, dynamic> json) =>
      decodeCyclonesPayload(
        json,
        (updated, raw) => PotentialPayload(
          updated: updated,
          cyclones: [
            for (final c in raw)
              if (c is Map<String, dynamic>) TyphoonPotential.decode(c),
          ],
        ),
      );
}
