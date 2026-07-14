/// Track-potential forecast — v5 `GET /api/v5/meteor/typhoon/potential`
/// (dataset 002).
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
    /// Human label (e.g. `07月14日14時`).
    required String label,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lng') required double longitude,
  }) = _ForecastPoint;

  factory ForecastPoint.fromJson(Map<String, dynamic> json) =>
      _$ForecastPointFromJson(json);
}

/// The `GET /potential` payload. Its geometry arrays are `[lng, lat]` (GeoJSON
/// axis order) and are custom-decoded to [LatLng]; each is empty and
/// [circle]/[current] null when no cyclone is active. [cone] — the uncertainty
/// cone — is unique to dataset 002.
@freezed
abstract class TyphoonPotential with _$TyphoonPotential {
  const factory TyphoonPotential({
    required int updated,

    /// Cyclone code (e.g. `TD11`); null when none active.
    String? name,

    /// Observed past track.
    required List<LatLng> past,

    /// Predicted track.
    required List<LatLng> forecast,

    /// Track-potential (uncertainty) cone outline.
    required List<LatLng> cone,

    /// Symmetric level-7 wind circle (illustrative); null when too weak.
    List<LatLng>? circle,

    /// Current centre; null when none active.
    LatLng? current,

    /// Labelled forecast waypoints.
    required List<ForecastPoint> points,
  }) = _TyphoonPotential;

  /// Decodes the raw payload, mapping every `[lng, lat]` pair to a [LatLng].
  factory TyphoonPotential.decode(Map<String, dynamic> json) =>
      TyphoonPotential(
        updated: (json['updated'] as num).toInt(),
        name: json['name'] as String?,
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

/// Maps a single `[lng, lat]` pair to a [LatLng] (mind the GeoJSON axis order).
LatLng _coord(List<dynamic> pair) =>
    LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());

/// Maps a list of `[lng, lat]` pairs to [LatLng]s; empty/absent in → empty out.
List<LatLng> _coords(Object? raw) => [
  for (final p in (raw as List? ?? const [])) _coord(p as List),
];
