import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

/// One of the radars whose coverage makes up the composite.
class RadarSite {
  const RadarSite(this.lon, this.lat, this.radiusKm);

  final double lon;
  final double lat;

  /// Usable range, in kilometres.
  final double radiusKm;
}

/// The area CWA's radar composite (`O-A0059-001`) actually observes.
///
/// Not the declared grid — that is a plain 115–126.5 × 18–29 box, and most of
/// it is never sampled. The real coverage is the **union of four radar range
/// circles, clipped to the grid**, and the difference matters on a
/// disaster-prevention map: blank outside the circles means *not observed*, not
/// *no rain*.
///
/// The point test comes from the haversine distance condition
///
/// ```text
/// 2·Rₑ·asin(√(sin²(Δφ/2) + cosφ·cosφᵢ·sin²(Δλ/2))) ≤ Rᵢ
/// ```
///
/// with `sin²(·/2Rₑ)` applied to both sides. `sin` is monotonic on `[0, π/2]`,
/// so that is order-preserving and the condition becomes
///
/// ```text
/// sin²(Δφ/2) + cosφ·cosφᵢ·sin²(Δλ/2) ≤ kᵢ,   kᵢ = sin²(Rᵢ/2Rₑ)
/// ```
///
/// `kᵢ` is a constant, so the test carries no `asin`, no `√` and no division.
/// The boundary is the same identity solved for Δλ at a fixed latitude, which
/// is likewise closed-form — no marching, no polygon clipping.
///
/// Across 17.9–29.1° sampled at 0.005°, the four circles' longitude intervals
/// always merge into a **single** interval, so the union's outline is one ring
/// built from the left edge going up and the right edge coming back down. No
/// boolean polygon operations are needed.
abstract final class RadarScanRange {
  RadarScanRange._();

  /// Earth radius used to fit the ranges, in kilometres.
  static const double earthRadiusKm = 6371.0;

  /// The contributing radars. The fourth is inferred: the composite covers
  /// ground no Taiwanese site can reach, and Ishigaki is the only radar in
  /// range of it.
  /// The three domestic sites come first, so [sites] can be sliced by origin.
  static const List<RadarSite> sites = [
    RadarSite(120.8543, 21.9046, 457.72), // RCKT 墾丁
    RadarSite(120.0808, 23.1472, 460.29), // RCCG 七股
    RadarSite(121.7644, 25.0735, 459.76), // RCWF 五分山
    RadarSite(124.1885, 24.4235, 398.69), // 石垣島
  ];

  /// How many of [sites] are CWA's own — the rest is inferred coverage.
  static const int domesticSiteCount = 3;

  /// The declared grid (cell centres): 921 × 881 at 0.0125°.
  static const double gridResolution = 0.0125;
  static const double west = 115.0;
  static const double south = 18.0;
  static const double east = west + (921 - 1) * gridResolution; // 126.5
  static const double north = south + (881 - 1) * gridResolution; // 29.0

  /// Source and layer ids, kept distinct from the radar raster's own.
  static const String sourceId = 'radar-scan-range';
  static const String outlineLayerId = 'radar-scan-range-outline';

  static const double _deg = math.pi / 180.0;

  /// `kᵢ = sin²(Rᵢ / 2Rₑ)` per site, precomputed.
  static final List<double> _k = [
    for (final s in sites)
      math.pow(math.sin(s.radiusKm / (2 * earthRadiusKm)), 2) as double,
  ];

  /// `cos φᵢ` per site, precomputed.
  static final List<double> _cosLat = [
    for (final s in sites) math.cos(s.lat * _deg),
  ];

  /// Whether a point is observed. Pure comparison — no `asin`, no `√`.
  static bool covered(double lon, double lat) {
    if (lon < west || lon > east || lat < south || lat > north) return false;
    final cosP = math.cos(lat * _deg);
    for (var i = 0; i < sites.length; i++) {
      final site = sites[i];
      final a = math.pow(math.sin((lat - site.lat) * _deg / 2), 2) as double;
      final b = math.pow(math.sin((lon - site.lon) * _deg / 2), 2) as double;
      if (a + cosP * _cosLat[i] * b <= _k[i]) return true;
    }
    return false;
  }

  /// The longitude interval one circle spans at [lat], or null if it does not
  /// reach that latitude. Closed-form inverse of the condition above.
  static (double, double)? _lonSpan(int i, double lat, double cosP) {
    final site = sites[i];
    final s =
        _k[i] - (math.pow(math.sin((lat - site.lat) * _deg / 2), 2) as double);
    if (s <= 0) return null;
    final t = s / (cosP * _cosLat[i]);
    if (t <= 0) return null;
    final dlon = 2.0 * math.asin(math.sqrt(math.min(t, 1.0))) / _deg;
    return (site.lon - dlon, site.lon + dlon);
  }

  /// The coverage outline as `[lon, lat]` pairs, closed and wound
  /// counter-clockwise (right edge up, left edge back down).
  ///
  /// [step] is the latitude sampling interval; it defaults to the grid's own
  /// resolution, which puts a vertex on every row the data actually has.
  static List<List<double>> ring({double step = gridResolution}) {
    final n = ((north - south) / step).round();
    final left = <List<double>>[];
    final right = <List<double>>[];

    for (var i = 0; i <= n; i++) {
      final lat = math.min(south + i * step, north);
      final cosP = math.cos(lat * _deg);

      double? lo;
      double? hi;
      for (var j = 0; j < sites.length; j++) {
        final span = _lonSpan(j, lat, cosP);
        if (span == null) continue;
        // The merged interval is always single — see the class doc — so the
        // union is just the outermost pair.
        lo = lo == null ? span.$1 : math.min(lo, span.$1);
        hi = hi == null ? span.$2 : math.max(hi, span.$2);
      }
      if (lo == null || hi == null) continue;

      final clampedLo = math.max(lo, west);
      final clampedHi = math.min(hi, east);
      if (clampedHi <= clampedLo) continue;

      left.add([_round6(clampedLo), _round6(lat)]);
      right.add([_round6(clampedHi), _round6(lat)]);
    }

    final ring = [...right, ...left.reversed];
    if (ring.isNotEmpty) ring.add(ring.first);
    return ring;
  }

  static double _round6(double v) => (v * 1e6).roundToDouble() / 1e6;

  /// The coverage outline as a GeoJSON polygon.
  ///
  /// A **map**, never an encoded string: `addSource` hands this straight to
  /// `NSJSONSerialization.dataWithJSONObject` on iOS, which throws — crashing
  /// the app, not returning an error — on a top-level string.
  static Map<String, dynamic> geoJson() => {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': <String, Object?>{
          'name': 'effective_extent',
          'note': '4 radar range circles union, clipped to grid',
        },
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring()],
        },
      },
    ],
  };

  /// Adds the source and outline if they are not already present.
  ///
  /// Outline only — no fill. The covered area is where the echo itself is, and
  /// a wash over it would tint every dBZ colour on the map.
  static Future<void> add(
    MapLibreMapController controller, {
    required String outlineColor,
    String? belowLayerId,
  }) async {
    await controller.addSource(
      sourceId,
      GeojsonSourceProperties(data: geoJson()),
    );
    await controller.addLineLayer(
      sourceId,
      outlineLayerId,
      LineLayerProperties(
        lineColor: outlineColor,
        lineWidth: 1.5,
        lineOpacity: 0.7,
        // Dashed, so it never reads as a coastline or an administrative border.
        lineDasharray: const [3.0, 2.0],
      ),
      belowLayerId: belowLayerId,
      enableInteraction: false,
    );
  }

  /// Removes the layer and source, tolerating a partially-added state.
  static Future<void> remove(MapLibreMapController controller) async {
    try {
      await controller.removeLayer(outlineLayerId);
    } catch (_) {
      // Not present — nothing to undo.
    }
    try {
      await controller.removeSource(sourceId);
    } catch (_) {
      // Not present — nothing to undo.
    }
  }
}
