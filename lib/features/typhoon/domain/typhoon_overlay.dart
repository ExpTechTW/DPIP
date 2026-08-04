/// Pure GeoJSON builders for typhoon map overlays — typed datasets → Feature
/// Collection with stable `properties.kind` tags the map layer filters on.
///
/// Multi-storm rule: every active cyclone in `/track` is drawn in full
/// (past, forecast, r70 cone, storm circles). Server `/geojson` only keeps
/// strike-probability fills — it is a single-storm mash-up and must not be
/// the source of past/forecast/cone.
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

/// Kinds owned by `/track` — stripped from server `/geojson` before rebuild.
const _trackOwnedKinds = <String>{
  'past',
  'forecast',
  'cone',
  'circle15',
  'circleAvg15',
  'circle25',
  'circleAvg25',
  'forecastPoint',
  'current',
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

String? _keyOfTrack(TyphoonTrack t) =>
    cycloneKeyOf(name: t.name, cwaName: t.cwaName, tdNo: t.tdNo);

/// Builds the map overlay FC from [potential] + [probability] + every
/// cyclone in [tracks] (past / forecast / r70 cone / circles).
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
  List<TyphoonTrack> tracks = const [],
  List<TyphoonCyclone> cyclones = const [],
}) {
  final features = <Map<String, dynamic>>[];
  final selectedKey = selected == null ? null : _keyOfTrack(selected);

  if (tracks.isNotEmpty) {
    // Full multi-storm rebuild from `/track`.
    _appendAllTrackOverlays(features, tracks);
  } else {
    // Legacy single-storm fallback when `/track` is empty.
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
      _appendTrackForecastFeatures(
        features,
        selected,
        cycloneKey: selectedKey ?? '',
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
      _appendStormCircles(features, centre, now);
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
          // Empty for an unnamed depression — the Flutter panel names it.
          'label': cycloneDisplayName(cwaName: c.cwaName, name: c.name) ?? '',
          'cyclone': cycloneKey(c),
          'selected': selected ? 1 : 0,
        },
      ),
    );
  }
}

/// Appends both storm-band combos from [now]: each is fill (four quarters) +
/// dashed avg ring. Map chrome shows only one band at a time.
void _appendStormCircles(
  List<Map<String, dynamic>> features,
  LatLng centre,
  TrackNow now,
) {
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

/// Past + forecast + r70 cone + storm circles for every cyclone in [tracks].
void _appendAllTrackOverlays(
  List<Map<String, dynamic>> features,
  List<TyphoonTrack> tracks,
) {
  for (final t in tracks) {
    final key = _keyOfTrack(t) ?? '';
    if (t.analysis.length >= 2) {
      features.addAll(pastTrackSegments(t.analysis));
    }
    _appendTrackForecastFeatures(features, t, cycloneKey: key);
    final cone = forecastConeRing(t);
    if (cone.length >= 3) {
      features.add(
        _polygon('cone', cone, properties: {'kind': 'cone', 'cyclone': key}),
      );
    }
    final now = t.now;
    if (now != null &&
        t.analysis.isNotEmpty &&
        (now.c15 != null || now.c25 != null)) {
      _appendStormCircles(
        features,
        LatLng(t.analysis.last.latitude, t.analysis.last.longitude),
        now,
      );
    }
  }
}

/// Appends forecast line and points from one cyclone [track].
void _appendTrackForecastFeatures(
  List<Map<String, dynamic>> features,
  TyphoonTrack track, {
  required String cycloneKey,
}) {
  if (track.forecast.isEmpty) return;
  // Path starts at the current centre so the dashed forecast connects.
  final path = <LatLng>[
    if (track.analysis.isNotEmpty)
      LatLng(track.analysis.last.latitude, track.analysis.last.longitude),
    for (final f in track.forecast) LatLng(f.latitude, f.longitude),
  ];
  if (path.length >= 2) {
    features.add(
      _line(
        'forecast',
        path,
        properties: {'kind': 'forecast', 'cyclone': cycloneKey},
      ),
    );
  }
  for (final f in track.forecast) {
    features.add(
      _point(
        'forecastPoint',
        LatLng(f.latitude, f.longitude),
        properties: {
          'kind': 'forecastPoint',
          'label': '+${f.tau}h',
          'cyclone': cycloneKey,
        },
      ),
    );
  }
}

/// Uncertainty cone outline from forecast `r70` radii (km).
///
/// Centres = last analysis fix + every forecast fix with a non-null `r70`.
/// The current centre reuses the first forecast's `r70`. Returns an empty
/// list when fewer than two centres carry a radius (nothing to envelope).
List<LatLng> forecastConeRing(TyphoonTrack track) {
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
  if (centres.length < 2) return const [];

  final left = <LatLng>[];
  final right = <LatLng>[];
  for (var i = 0; i < centres.length; i++) {
    final bearing = i == 0
        ? _bearingDeg(centres[0], centres[1])
        : i == centres.length - 1
        ? _bearingDeg(centres[i - 1], centres[i])
        : _bearingDeg(centres[i - 1], centres[i + 1]);
    left.add(_destination(centres[i], bearing - 90, radii[i]));
    right.add(_destination(centres[i], bearing + 90, radii[i]));
  }

  // Caps: half-circles around the first / last centres so the envelope
  // doesn't collapse to a flat sausage at the ends.
  final startCap = _arc(
    centres.first,
    _bearingDeg(centres.first, right.first),
    _bearingDeg(centres.first, left.first),
    radii.first,
  );
  final endCap = _arc(
    centres.last,
    _bearingDeg(centres.last, left.last),
    _bearingDeg(centres.last, right.last),
    radii.last,
  );

  final ring = <LatLng>[...startCap, ...left, ...endCap, ...right.reversed];
  if (ring.isNotEmpty) ring.add(ring.first);
  return ring;
}

/// Shortest-turn arc from [startBearing] to [endBearing] around [centre].
List<LatLng> _arc(
  LatLng centre,
  double startBearing,
  double endBearing,
  double radiusKm, {
  int steps = 8,
}) {
  var delta = (endBearing - startBearing) % 360;
  if (delta < 0) delta += 360;
  if (delta > 180) delta -= 360; // shortest turn
  if (delta.abs() < 1) return const [];
  return [
    for (var i = 1; i < steps; i++)
      _destination(centre, startBearing + delta * i / steps, radiusKm),
  ];
}

double _bearingDeg(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
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

/// Augments a server `/geojson` FC: keeps strike-probability fills, then
/// rebuilds past / forecast / cone / circles / centres from every cyclone in
/// [tracks] so multi-storm seasons are not clipped to the nearest system.
Map<String, dynamic> augmentTyphoonGeojson(
  Map<String, dynamic> geo, {
  TyphoonTrack? selected,
  List<TyphoonTrack> tracks = const [],
  List<TyphoonCyclone> cyclones = const [],
}) {
  final features = [
    for (final f in (geo['features'] as List? ?? const []))
      if (f is Map<String, dynamic> &&
          !_trackOwnedKinds.contains(f['properties']?['kind']))
        Map<String, dynamic>.from(f),
  ];
  final selectedKey = selected == null ? null : _keyOfTrack(selected);
  final overlayTracks = tracks.isNotEmpty
      ? tracks
      : (selected == null ? const <TyphoonTrack>[] : <TyphoonTrack>[selected]);

  if (overlayTracks.isNotEmpty) {
    _appendAllTrackOverlays(features, overlayTracks);
  }

  injectCycloneCentres(features, cyclones: cyclones, selectedKey: selectedKey);
  return {'type': 'FeatureCollection', 'features': features};
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
