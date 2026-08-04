/// Pure GeoJSON builders for the typhoon map overlay.
///
/// Single source of truth from typed v5 payloads (multi-storm, keyed by
/// `tdNo`):
///
/// | Kind | Owner |
/// |---|---|
/// | `past` | `/track` analysis → intensity-coloured segments |
/// | `forecast` | `/track` forecast line |
/// | `forecastPoint` | `/potential` points (CWA labels), else track `+Nh` |
/// | `cone` | `/potential` official cone, else `r70` convex-hull fallback |
/// | `circle15`/`25` + avg | `/track` `now.c15`/`c25` asymmetric rings |
/// | `probability` | `/probability` contours |
/// | `current` | cyclone index centres |
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

/// Builds the complete typhoon overlay from typed multi-storm payloads.
Map<String, dynamic> buildTyphoonOverlay({
  required List<TyphoonTrack> tracks,
  List<TyphoonPotential> potentials = const [],
  TyphoonProbability? probability,
  List<TyphoonCyclone> cyclones = const [],
  String? selectedKey,
}) {
  final features = <Map<String, dynamic>>[];
  final potentialByTd = <String, TyphoonPotential>{
    for (final p in potentials)
      if (presentText(p.tdNo) != null) presentText(p.tdNo)!: p,
  };

  for (final track in tracks) {
    final td = presentText(track.tdNo);
    final key = cycloneKeyOf(
      name: track.name,
      cwaName: track.cwaName,
      tdNo: track.tdNo,
    );
    final pot = td == null ? null : potentialByTd[td];

    if (track.analysis.length >= 2) {
      features.addAll(
        pastTrackSegments(track.analysis, tdNo: td, cycloneKey: key),
      );
    }

    _appendForecastLine(features, track, cycloneKey: key, tdNo: td);

    if (pot != null && pot.points.isNotEmpty) {
      for (final p in pot.points) {
        features.add(
          _point(
            'forecastPoint',
            LatLng(p.latitude, p.longitude),
            properties: {
              'kind': 'forecastPoint',
              'label': shortenTyphoonTimeLabel(p.label),
              'cyclone': key,
              'tdNo': td,
            },
          ),
        );
      }
    } else {
      _appendForecastPoints(features, track, cycloneKey: key, tdNo: td);
    }

    final officialCone = pot?.cone;
    if (officialCone != null && officialCone.length >= 3) {
      features.add(
        _polygon(
          'cone',
          officialCone,
          properties: {'kind': 'cone', 'tdNo': td, 'cyclone': key},
        ),
      );
    } else {
      final fallback = forecastConeRing(track);
      if (fallback.length >= 3) {
        features.add(
          _polygon(
            'cone',
            fallback,
            properties: {'kind': 'cone', 'tdNo': td, 'cyclone': key},
          ),
        );
      }
    }

    final now = track.now;
    if (now != null &&
        track.analysis.isNotEmpty &&
        (now.c15 != null || now.c25 != null)) {
      _appendStormCircles(
        features,
        LatLng(track.analysis.last.latitude, track.analysis.last.longitude),
        now,
        tdNo: td,
        cycloneKey: key,
      );
    }
  }

  if (probability != null) {
    for (final cyclone in probability.cyclones) {
      final td = presentText(cyclone.tdNo);
      for (final level in cyclone.levels) {
        if (level.coords.length < 3) continue;
        features.add(
          _polygon(
            'probability',
            level.coords,
            properties: {'kind': 'probability', 'p': level.p, 'tdNo': ?td},
          ),
        );
      }
    }
  }

  injectCycloneCentres(features, cyclones: cyclones, selectedKey: selectedKey);

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
    final selected = cycloneMatchesKey(
      key: selectedKey,
      stormName: c.name,
      stormCwaName: c.cwaName,
      stormTdNo: c.tdNo,
    );
    features.add(
      _point(
        'current',
        LatLng(c.latitude, c.longitude),
        properties: {
          'kind': 'current',
          'label': cycloneDisplayName(cwaName: c.cwaName, name: c.name) ?? '',
          'cyclone': cycloneKey(c),
          'tdNo': presentText(c.tdNo),
          'selected': selected ? 1 : 0,
        },
      ),
    );
  }
}

/// One past-track segment per consecutive [analysis] pair, coloured by the
/// destination fix's sustained wind (CWA intensity).
List<Map<String, dynamic>> pastTrackSegments(
  List<TrackFix> analysis, {
  String? tdNo,
  String? cycloneKey,
}) {
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
          'intensity': ?intensity?.wire,
          'tdNo': ?tdNo,
          'cyclone': ?cycloneKey,
        },
      ),
    );
  }
  return out;
}

/// Uncertainty cone from forecast `r70` — only when `/potential` has no cone.
///
/// Samples each `r70` circle and returns their convex hull (left/right offset
/// envelopes self-intersect on sharp track turns).
List<LatLng> forecastConeRing(TyphoonTrack track, {int samplesPerCircle = 24}) {
  final centres = <LatLng>[];
  final radii = <double>[];
  final withR70 = [
    for (final f in track.forecast)
      if (f.r70 != null && f.r70! > 0) f,
  ];
  if (withR70.isEmpty) return const [];

  if (track.analysis.isNotEmpty) {
    final last = track.analysis.last;
    centres.add(LatLng(last.latitude, last.longitude));
    radii.add(withR70.first.r70!);
  }
  for (final f in withR70) {
    centres.add(LatLng(f.latitude, f.longitude));
    radii.add(f.r70!);
  }
  if (centres.length == 1) {
    return symmetricStormRing(centres.first, radii.first);
  }

  final samples = <LatLng>[
    for (var i = 0; i < centres.length; i++)
      for (var s = 0; s < samplesPerCircle; s++)
        _destination(centres[i], s * 360.0 / samplesPerCircle, radii[i]),
  ];
  final hull = _convexHull(samples);
  if (hull.length < 3) return const [];
  if (hull.first != hull.last) hull.add(hull.first);
  return hull;
}

/// Closed ring = four constant-radius quarter-circles (CWA quadrants).
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

/// Closed symmetric ring at [radiusKm] — the CWA "平均圓".
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

void _appendForecastLine(
  List<Map<String, dynamic>> features,
  TyphoonTrack track, {
  required String cycloneKey,
  String? tdNo,
}) {
  if (track.forecast.isEmpty) return;
  final path = <LatLng>[
    if (track.analysis.isNotEmpty)
      LatLng(track.analysis.last.latitude, track.analysis.last.longitude),
    for (final f in track.forecast) LatLng(f.latitude, f.longitude),
  ];
  if (path.length < 2) return;
  features.add(
    _line(
      'forecast',
      path,
      properties: {'kind': 'forecast', 'cyclone': cycloneKey, 'tdNo': ?tdNo},
    ),
  );
}

void _appendForecastPoints(
  List<Map<String, dynamic>> features,
  TyphoonTrack track, {
  required String cycloneKey,
  String? tdNo,
}) {
  for (final f in track.forecast) {
    features.add(
      _point(
        'forecastPoint',
        LatLng(f.latitude, f.longitude),
        properties: {
          'kind': 'forecastPoint',
          'label': '+${f.tau}h',
          'cyclone': cycloneKey,
          'tdNo': ?tdNo,
        },
      ),
    );
  }
}

void _appendStormCircles(
  List<Map<String, dynamic>> features,
  LatLng centre,
  TrackNow now, {
  String? tdNo,
  String? cycloneKey,
}) {
  final extra = <String, dynamic>{'tdNo': ?tdNo, 'cyclone': ?cycloneKey};
  if (now.c15 != null) {
    features.add(
      _polygon(
        'circle15',
        asymmetricStormRing(centre, now.c15!),
        properties: {'kind': 'circle15', ...extra},
      ),
    );
    features.add(
      _line(
        'circleAvg15',
        symmetricStormRing(centre, now.c15!.avg),
        properties: {'kind': 'circleAvg15', ...extra},
      ),
    );
  }
  if (now.c25 != null) {
    features.add(
      _polygon(
        'circle25',
        asymmetricStormRing(centre, now.c25!),
        properties: {'kind': 'circle25', ...extra},
      ),
    );
    features.add(
      _line(
        'circleAvg25',
        symmetricStormRing(centre, now.c25!.avg),
        properties: {'kind': 'circleAvg25', ...extra},
      ),
    );
  }
}

List<LatLng> _convexHull(List<LatLng> points) {
  if (points.length < 3) return List<LatLng>.from(points);
  final sorted = [...points]
    ..sort((a, b) {
      final dx = a.longitude.compareTo(b.longitude);
      return dx != 0 ? dx : a.latitude.compareTo(b.latitude);
    });

  double cross(LatLng o, LatLng a, LatLng b) =>
      (a.longitude - o.longitude) * (b.latitude - o.latitude) -
      (a.latitude - o.latitude) * (b.longitude - o.longitude);

  final lower = <LatLng>[];
  for (final p in sorted) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }
  final upper = <LatLng>[];
  for (final p in sorted.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }
  lower.removeLast();
  upper.removeLast();
  return [...lower, ...upper];
}

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
