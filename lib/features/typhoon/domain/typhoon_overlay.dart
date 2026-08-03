/// Pure GeoJSON builders for typhoon map overlays — typed datasets → Feature
/// Collection with stable `properties.kind` tags the map layer filters on.
library;

import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/cyclone_identity.dart';
import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_intensity.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';

/// Empty FeatureCollection used when nothing is active.
const Map<String, dynamic> emptyTyphoonFeatureCollection = {
  'type': 'FeatureCollection',
  'features': <dynamic>[],
};

/// CWA wire labels look like `07月14日08時` — drop the month and the day
/// leading zero so map / sheet show `14日08時` / `7日08時`.
String shortenTyphoonTimeLabel(String label) {
  final m = RegExp(r'^(?:\d{1,2}月)?(\d{1,2})日(\d{1,2})時$').firstMatch(label);
  if (m == null) return label;
  final day = int.parse(m[1]!);
  final hour = m[2]!.padLeft(2, '0');
  return '$day日$hour時';
}

/// Builds the map overlay FC from [potential] + [probability] + the
/// [selected] track (past / circles). Every [cyclones] centre is drawn so the
/// user can tap to switch storms.
///
/// Kind tags: `past` (optionally with `intensity`), `forecast`, `cone`,
/// `circle15` / `circleAvg15` (L7 fill + dashed avg), `circle25` /
/// `circleAvg25` (L10 fill + dashed avg), `current`, `forecastPoint`,
/// `probability`. L7 and L10 combos are toggled mutually exclusively on the
/// map (visibility), not omitted from the FC.
Map<String, dynamic> typhoonFeatureCollection({
  required TyphoonPotential potential,
  required TyphoonProbability probability,
  TyphoonTrack? selected,
  List<TyphoonCyclone> cyclones = const [],
}) {
  final features = <Map<String, dynamic>>[];

  final analysis = selected?.analysis ?? const <TrackFix>[];
  if (analysis.length >= 2) {
    features.addAll(pastTrackSegments(analysis));
  } else if (potential.past.length >= 2) {
    features.add(_line('past', potential.past));
  }
  if (potential.forecast.length >= 2) {
    features.add(_line('forecast', potential.forecast));
  } else if (selected != null && selected.forecast.length >= 2) {
    features.add(
      _line('forecast', [
        for (final f in selected.forecast) LatLng(f.latitude, f.longitude),
      ]),
    );
  }
  if (potential.cone.length >= 3) {
    features.add(_polygon('cone', potential.cone));
  }
  if (potential.circle != null && potential.circle!.length >= 3) {
    features.add(_polygon('circle15', potential.circle!));
  }
  for (final p in potential.points) {
    features.add(
      _point(
        'forecastPoint',
        LatLng(p.latitude, p.longitude),
        properties: {
          'kind': 'forecastPoint',
          'label': shortenTyphoonTimeLabel(p.label),
        },
      ),
    );
  }
  if (potential.points.isEmpty && selected != null) {
    for (final f in selected.forecast) {
      features.add(
        _point(
          'forecastPoint',
          LatLng(f.latitude, f.longitude),
          properties: {'kind': 'forecastPoint', 'label': '+${f.tau}h'},
        ),
      );
    }
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

  final now = selected?.now;
  final centre = selected != null && selected.analysis.isNotEmpty
      ? LatLng(
          selected.analysis.last.latitude,
          selected.analysis.last.longitude,
        )
      : potential.current;
  if (selected != null && now != null && centre != null) {
    _addStormCircles(features, centre, now);
  }

  injectCycloneCentres(
    features,
    cyclones: cyclones,
    selectedKey: selected?.name,
  );

  return {'type': 'FeatureCollection', 'features': features};
}

/// Replaces `current` features with one labelled centre per active cyclone.
void injectCycloneCentres(
  List<Map<String, dynamic>> features, {
  required List<TyphoonCyclone> cyclones,
  String? selectedKey,
}) {
  if (cyclones.isEmpty) return;
  features.removeWhere((f) => f['properties']?['kind'] == 'current');
  for (final c in cyclones) {
    final selected = sameCyclone(
      name: selectedKey,
      stormName: c.name,
      stormCwaName: c.cwaName,
    );
    features.add(
      _point(
        'current',
        LatLng(c.latitude, c.longitude),
        properties: {
          'kind': 'current',
          'label': c.cwaName ?? c.name,
          'cyclone': c.name,
          'selected': selected ? 1 : 0,
        },
      ),
    );
  }
}

/// Writes both storm-band combos from [now]: each is fill (four quarters) +
/// dashed avg ring. Map chrome shows only one band at a time.
void _addStormCircles(
  List<Map<String, dynamic>> features,
  LatLng centre,
  TrackNow now,
) {
  for (final kind in ['circle15', 'circleAvg15', 'circle25', 'circleAvg25']) {
    features.removeWhere((f) => f['properties']?['kind'] == kind);
  }
  if (now.c15 != null) {
    features.add(_polygon('circle15', asymmetricStormRing(centre, now.c15!)));
    features.add(
      _line('circleAvg15', symmetricStormRing(centre, now.c15!.avg)),
    );
  }
  if (now.c25 != null) {
    features.add(_polygon('circle25', asymmetricStormRing(centre, now.c25!)));
    features.add(
      _line('circleAvg25', symmetricStormRing(centre, now.c25!.avg)),
    );
  }
}

/// One past-track segment per consecutive [analysis] pair, coloured by the
/// destination fix's sustained wind (CWA intensity).
List<Map<String, dynamic>> pastTrackSegments(List<TrackFix> analysis) {
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < analysis.length - 1; i++) {
    final a = analysis[i];
    final b = analysis[i + 1];
    final intensity = typhoonIntensityFromWind(b.wind);
    out.add(
      _line(
        'past',
        [LatLng(a.latitude, a.longitude), LatLng(b.latitude, b.longitude)],
        properties: {
          'kind': 'past',
          if (intensity != null) 'intensity': intensity.wire,
        },
      ),
    );
  }
  return out;
}

/// Augments a server `/geojson` FC: shortens forecast labels, swaps the plain
/// `past` line for intensity-coloured segments from [selected].analysis,
/// **replaces** symmetric storm circles from `now`, and injects every active
/// cyclone centre for multi-storm selection.
Map<String, dynamic> augmentTyphoonGeojson(
  Map<String, dynamic> geo, {
  TyphoonTrack? selected,
  List<TyphoonCyclone> cyclones = const [],
}) {
  final features = [
    for (final f in (geo['features'] as List? ?? const []))
      if (f is Map<String, dynamic>) Map<String, dynamic>.from(f),
  ];
  // Server geojson keeps the full `MM月DD日HH時` label — shorten for display.
  for (final f in features) {
    final props = f['properties'];
    if (props is! Map || props['kind'] != 'forecastPoint') continue;
    final label = props['label'];
    if (label is! String) continue;
    f['properties'] = {...props, 'label': shortenTyphoonTimeLabel(label)};
  }
  if (selected != null && selected.analysis.length >= 2) {
    features.removeWhere((f) => f['properties']?['kind'] == 'past');
    features.insertAll(0, pastTrackSegments(selected.analysis));
  }
  final now = selected?.now;
  if (selected != null && now != null && (now.c15 != null || now.c25 != null)) {
    final centre = selected.analysis.isNotEmpty
        ? LatLng(
            selected.analysis.last.latitude,
            selected.analysis.last.longitude,
          )
        : _centreFromFeatures(features);
    if (centre != null) {
      _addStormCircles(features, centre, now);
    }
  }
  injectCycloneCentres(
    features,
    cyclones: cyclones,
    selectedKey: selected?.name,
  );
  return {'type': 'FeatureCollection', 'features': features};
}

LatLng? _centreFromFeatures(List<Map<String, dynamic>> features) {
  for (final f in features) {
    if (f['properties']?['kind'] != 'current') continue;
    final c = f['geometry']?['coordinates'];
    if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
      return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
    }
  }
  return null;
}

/// Closed ring = **four quarter-circles** (constant radius per CWA quadrant).
///
/// Bearing bands: NE `0–90°`, SE `90–180°`, SW `180–270°`, NW `270–360°`.
/// Adjacent radii meet with a kink on the cardinal axes — not a smooth lerp
/// between quadrants (that made an irregular blob).
List<LatLng> asymmetricStormRing(
  LatLng centre,
  StormCircle circle, {
  int steps = 64,
}) {
  final perQuad = (steps ~/ 4).clamp(2, 256);
  final radii = [circle.ne, circle.se, circle.sw, circle.nw];
  final ring = <LatLng>[];
  for (var q = 0; q < 4; q++) {
    final start = q * 90.0;
    final r = radii[q];
    for (var i = 0; i < perQuad; i++) {
      final bearing = start + i * 90.0 / perQuad;
      ring.add(_destination(centre, bearing, r));
    }
  }
  if (ring.isNotEmpty) ring.add(ring.first);
  return ring;
}

/// Closed symmetric ring at [radiusKm] — the CWA "平均圓" for a storm circle.
List<LatLng> symmetricStormRing(
  LatLng centre,
  double radiusKm, {
  int steps = 64,
}) {
  final ring = <LatLng>[
    for (var i = 0; i < steps; i++)
      _destination(centre, i * 360.0 / steps, radiusKm),
  ];
  if (ring.isNotEmpty) ring.add(ring.first);
  return ring;
}

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

Map<String, dynamic> _line(
  String kind,
  List<LatLng> path, {
  Map<String, dynamic>? properties,
}) => {
  'type': 'Feature',
  'properties': properties ?? {'kind': kind},
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
