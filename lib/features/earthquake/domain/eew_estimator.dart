import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/features/earthquake/domain/wave_time.dart';

/// Earthquake Early Warning (EEW) shaking and wave-timing estimates.
///
/// Pure functions ported from the original `core/eew.dart`, decoupled from the
/// map package (via [LatLng]) and from global state.
///
/// The arithmetic is algebraically identical to the original but faster:
/// `pow(x, 2)` is replaced by `x * x` (bit-identical for finite values, no
/// `pow` call), repeated sub-expressions are hoisted, and the magnitude-only
/// factors are lifted out of the per-region loop. Two further identities are
/// applied at their own call sites — see [_pgvIntensity] and [waveTime].
/// `test/features/earthquake/eew_estimator_test.dart` pins every output.
abstract final class EewEstimator {
  /// `log10(1.31)`. See [_pgvIntensity].
  static const double _log10Pgv600ToPgv = 0.11727129565576426;

  /// `10^-1.85`, the magnitude-independent half of the near-field `long` term.
  static const double _tenPowMinus1p85 = 0.01412537544622754;

  /// `sqrt(3)`, the S-wave slowness ratio. See [waveTime].
  static const double _sqrt3 = 1.7320508075688772;

  /// Estimated continuous intensity at [point] for an event of moment
  /// magnitude [magW] at [epicenter] and focal [depth] (km), via the PGV
  /// attenuation model.
  static double areaPgv(
    LatLng epicenter,
    LatLng point,
    double depth,
    double magW,
  ) => _pgvIntensity(
    epicentralKm: epicenter.distanceTo(point) / 1000,
    depth: depth,
    magW: magW,
    tenPowHalfMag: math.pow(10, 0.5 * magW).toDouble(),
  );

  /// [areaPgv]'s body, with the two values a caller already holds passed in:
  /// the epicentral distance (the callers below have just paid for that
  /// haversine) and `10^(0.5·magW)` (constant across an event's regions).
  ///
  /// The published model computes `pgv600 = 10^e`, scales it by 1.31, and
  /// returns `2.68 + 1.72·log10(pgv)`. Since `log10(1.31·10^e)` is
  /// `e + log10(1.31)`, the exponentiation and the logarithm cancel exactly:
  /// one `pow` and one `log` disappear, and the result stops making a round
  /// trip through a number that can span 10 orders of magnitude.
  static double _pgvIntensity({
    required double epicentralKm,
    required double depth,
    required double magW,
    required double tenPowHalfMag,
  }) {
    final long = tenPowHalfMag * _tenPowMinus1p85 / 2;
    final hypocentralDistance =
        math.sqrt(depth * depth + epicentralKm * epicentralKm) - long;
    final x = math.max(hypocentralDistance, 3.0);
    final log10Pgv600 =
        0.58 * magW +
        0.0038 * depth -
        1.29 -
        math.log(x + 0.0028 * tenPowHalfMag) / math.ln10 -
        0.002 * x;
    return 2.68 + 1.72 * (log10Pgv600 + _log10Pgv600ToPgv);
  }

  /// Hypocentral distance (km) and estimated intensity at the user's location.
  static ({double dist, double i}) locationInfo({
    required double mag,
    required double depth,
    required LatLng epicenter,
    required LatLng user,
  }) {
    final surfaceDistance = epicenter.distanceTo(user) / 1000;
    final dist = math.sqrt(surfaceDistance * surfaceDistance + depth * depth);
    final pga = 1.657 * math.exp(1.533 * mag) * math.pow(dist, -1.607);
    var intensity = Intensity.fromPga(pga);
    if (intensity >= 4.5) {
      intensity = _pgvIntensity(
        epicentralKm: surfaceDistance,
        depth: depth,
        magW: mag,
        tenPowHalfMag: math.pow(10, 0.5 * mag).toDouble(),
      );
    }
    return (dist: dist, i: intensity);
  }

  /// Per-region estimated intensity for a map of region code → centroid.
  ///
  /// Returns each region's `{dist, i}` and the overall `maxIntensity`. Takes
  /// plain [LatLng] centroids so it stays free of any data-model coupling.
  static ({Map<String, ({double dist, double i})> regions, double maxIntensity})
  areaPga({
    required LatLng epicenter,
    required double depth,
    required double mag,
    required Map<String, LatLng> regionCentroids,
  }) {
    // Depth- and magnitude-dependent factors are constant across regions.
    final pgaFactor = 1.657 * math.exp(1.533 * mag);
    final depthSquared = depth * depth;
    final tenPowHalfMag = math.pow(10, 0.5 * mag).toDouble();

    final regions = <String, ({double dist, double i})>{};
    var maxIntensity = 0.0;
    regionCentroids.forEach((code, centroid) {
      final surfaceDistance = epicenter.distanceTo(centroid) / 1000;
      final dist = math.sqrt(surfaceDistance * surfaceDistance + depthSquared);
      final pga = pgaFactor * math.pow(dist, -1.607);
      var i = Intensity.fromPga(pga);
      if (i >= 4.5) {
        // The strong-shaking branch reuses this region's haversine rather than
        // repeating it: over Taiwan's ~368 townships that is 368 avoided
        // trig evaluations on the frame an alert upgrades.
        i = _pgvIntensity(
          epicentralKm: surfaceDistance,
          depth: depth,
          magW: mag,
          tenPowHalfMag: tenPowHalfMag,
        );
      }
      if (i > maxIntensity) maxIntensity = i;
      regions[code] = (dist: dist, i: i);
    });
    return (regions: regions, maxIntensity: maxIntensity);
  }

  /// Analytic P/S travel-time estimate (seconds) for epicentral [distance] (km)
  /// and focal [depth] (km), using the layered-velocity ray approximation.
  ///
  /// The S ray is not traced. The model's S-wave gradient is the P gradient
  /// divided by `sqrt(3)` in **both** terms — `g0/sqrt(3)` over
  /// `G/sqrt(3)` — so the ratio that fixes the ray's geometry is the same
  /// number, the circle centre and both ray angles come out identical, and the
  /// S time is the P time times `sqrt(3)`. Tracing it separately cost two
  /// `atan`, two `tan` and a `log` to arrive at that multiplication.
  static WaveTime waveTime(double depth, double distance) {
    final za = depth;
    final xb = distance;
    final zaSquared = za * za;
    final xbSquared = xb * xb;
    final twoXb = 2 * xb;

    final double g0;
    final double bigG;
    if (depth <= 40) {
      g0 = 5.10298;
      bigG = 0.06659;
    } else {
      g0 = 7.804799;
      bigG = 0.004573;
    }

    final gRatio = g0 / bigG;
    final zc = -gRatio;
    final xc = (xbSquared - 2 * gRatio * za - zaSquared) / twoXb;
    var thetaA = math.atan((za - zc) / xc);
    if (thetaA < 0) thetaA += math.pi;
    thetaA = math.pi - thetaA;
    final thetaB = math.atan(-zc / (xb - xc));
    var ptime =
        (1 / bigG) * math.log(math.tan(thetaA / 2) / math.tan(thetaB / 2));
    // Both caps read the *untraced* times, so the S time is derived before the
    // P time is capped.
    var stime = ptime * _sqrt3;

    if (distance / ptime > 7) ptime = distance / 7;
    if (distance / stime > 4) stime = distance / 4;
    return WaveTime(p: ptime, s: stime);
  }
}
