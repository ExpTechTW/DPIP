/// Pure GeoJSON builders for typhoon map overlays — typed datasets → Feature
/// Collection with stable `properties.kind` tags the map layer filters on.
library;

import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';

/// Empty FeatureCollection used when nothing is active.
const Map<String, dynamic> emptyTyphoonFeatureCollection = {
  'type': 'FeatureCollection',
  'features': <dynamic>[],
};

/// Builds the map overlay FC from [potential] + [probability] + optional
/// asymmetric storm circles from [track] (latest cyclone's `now`).
///
/// Kind tags match the v5 `/geojson` contract so the layer can use either
/// source interchangeably: `past`, `forecast`, `cone`, `circle15`, `circle25`,
/// `current`, `forecastPoint`, `probability`.
Map<String, dynamic> typhoonFeatureCollection({
  required TyphoonPotential potential,
  required TyphoonProbability probability,
  TrackPayload? track,
}) {
  final features = <Map<String, dynamic>>[];

  if (potential.past.length >= 2) {
    features.add(_line('past', potential.past));
  }
  if (potential.forecast.length >= 2) {
    features.add(_line('forecast', potential.forecast));
  }
  if (potential.cone.length >= 3) {
    features.add(_polygon('cone', potential.cone));
  }
  if (potential.circle != null && potential.circle!.length >= 3) {
    features.add(_polygon('circle15', potential.circle!));
  }
  if (potential.current != null) {
    features.add(_point('current', potential.current!));
  }
  for (final p in potential.points) {
    features.add(
      _point(
        'forecastPoint',
        LatLng(p.latitude, p.longitude),
        properties: {'kind': 'forecastPoint', 'label': p.label},
      ),
    );
  }
  for (final level in probability.levels) {
    if (level.coords.length < 3) continue;
    features.add(
      _polygon(
        'probability',
        level.coords,
        properties: {'kind': 'probability', 'p': level.p},
      ),
    );
  }

  final storm = track?.cyclones.isNotEmpty == true
      ? track!.cyclones.first
      : null;
  final now = storm?.now;
  final centre = potential.current;
  if (storm != null && now != null && centre != null) {
    // Prefer track asymmetric circles when present (richer than potential's
    // symmetric L7 ring). Replace any prior circle15 from potential.
    if (now.c15 != null) {
      features.removeWhere((f) => f['properties']?['kind'] == 'circle15');
      features.add(
        _polygon('circle15', asymmetricStormRing(centre, now.c15!)),
      );
    }
    if (now.c25 != null) {
      features.add(
        _polygon('circle25', asymmetricStormRing(centre, now.c25!)),
      );
    }
  }

  return {'type': 'FeatureCollection', 'features': features};
}

/// Augments a server `/geojson` FC with a `circle25` from [track] when missing.
Map<String, dynamic> augmentTyphoonGeojson(
  Map<String, dynamic> geo, {
  TrackPayload? track,
}) {
  final features = [
    for (final f in (geo['features'] as List? ?? const []))
      if (f is Map<String, dynamic>) Map<String, dynamic>.from(f),
  ];
  final hasC25 = features.any((f) => f['properties']?['kind'] == 'circle25');
  if (hasC25 || track == null || track.cyclones.isEmpty) {
    return {'type': 'FeatureCollection', 'features': features};
  }
  final storm = track.cyclones.first;
  final c25 = storm.now?.c25;
  if (c25 == null) {
    return {'type': 'FeatureCollection', 'features': features};
  }
  // Current centre from FC, else last analysis fix.
  LatLng? centre;
  for (final f in features) {
    if (f['properties']?['kind'] != 'current') continue;
    final c = f['geometry']?['coordinates'];
    if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
      centre = LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
    }
  }
  centre ??= storm.analysis.isNotEmpty
      ? LatLng(storm.analysis.last.latitude, storm.analysis.last.longitude)
      : null;
  if (centre == null) {
    return {'type': 'FeatureCollection', 'features': features};
  }
  features.add(_polygon('circle25', asymmetricStormRing(centre, c25)));
  return {'type': 'FeatureCollection', 'features': features};
}

/// Closed ring for an asymmetric [StormCircle] around [centre] (km radii).
///
/// Quadrant radii (NE/SE/SW/NW) are interpolated by bearing so the outline
/// matches CWA's four-quadrant wind field (not the symmetric [StormCircle.avg]).
List<LatLng> asymmetricStormRing(
  LatLng centre,
  StormCircle circle, {
  int steps = 64,
}) {
  final ring = <LatLng>[];
  for (var i = 0; i < steps; i++) {
    final bearing = i * 360.0 / steps;
    final r = _radiusAtBearing(circle, bearing);
    ring.add(_destination(centre, bearing, r));
  }
  if (ring.isNotEmpty) ring.add(ring.first);
  return ring;
}

double _radiusAtBearing(StormCircle c, double bearingDeg) {
  // Map bearing (0=N, 90=E) onto the four CWA quadrants.
  final b = bearingDeg % 360;
  if (b < 90) return _lerp(c.ne, c.se, b / 90);
  if (b < 180) return _lerp(c.se, c.sw, (b - 90) / 90);
  if (b < 270) return _lerp(c.sw, c.nw, (b - 180) / 90);
  return _lerp(c.nw, c.ne, (b - 270) / 90);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Destination point [distanceKm] along [bearingDeg] from [from] (WGS84).
LatLng _destination(LatLng from, double bearingDeg, double distanceKm) {
  const earthKm = 6371.0;
  final angular = distanceKm / earthKm;
  final bearing = bearingDeg * math.pi / 180;
  final lat1 = from.latitude * math.pi / 180;
  final lon1 = from.longitude * math.pi / 180;
  final sinLat1 = math.sin(lat1);
  final cosLat1 = math.cos(lat1);
  final sinAng = math.sin(angular);
  final cosAng = math.cos(angular);
  final sinLat2 = sinLat1 * cosAng + cosLat1 * sinAng * math.cos(bearing);
  final lat2 = math.asin(sinLat2);
  final lon2 =
      lon1 +
      math.atan2(
        math.sin(bearing) * sinAng * cosLat1,
        cosAng - sinLat1 * sinLat2,
      );
  return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
}

Map<String, dynamic> _line(String kind, List<LatLng> path) => {
  'type': 'Feature',
  'properties': {'kind': kind},
  'geometry': {
    'type': 'LineString',
    'coordinates': [
      for (final p in path) [p.longitude, p.latitude],
    ],
  },
};

Map<String, dynamic> _polygon(
  String kind,
  List<LatLng> ring, {
  Map<String, dynamic>? properties,
}) => {
  'type': 'Feature',
  'properties': properties ?? {'kind': kind},
  'geometry': {
    'type': 'Polygon',
    'coordinates': [
      [
        for (final p in ring) [p.longitude, p.latitude],
      ],
    ],
  },
};

Map<String, dynamic> _point(
  String kind,
  LatLng p, {
  Map<String, dynamic>? properties,
}) => {
  'type': 'Feature',
  'properties': properties ?? {'kind': kind},
  'geometry': {
    'type': 'Point',
    'coordinates': [p.longitude, p.latitude],
  },
};
