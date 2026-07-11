import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/wave_time.dart';

/// Earthquake Early Warning (EEW) shaking and wave-timing estimates.
///
/// Pure functions ported from the original `core/eew.dart`, decoupled from the
/// map package (via [LatLng]) and from global state.
///
/// The arithmetic is algebraically identical to the original but faster:
/// `pow(x, 2)` is replaced by `x * x` (bit-identical for finite values, no
/// `pow` call), repeated sub-expressions are hoisted, and the constant
/// `1.657 * exp(1.533 * mag)` factor is lifted out of the per-region loop.
abstract final class EewEstimator {
  /// Estimated continuous intensity at [point] for an event of moment
  /// magnitude [magW] at [epicenter] and focal [depth] (km), via the PGV
  /// attenuation model.
  static double areaPgv(
    LatLng epicenter,
    LatLng point,
    double depth,
    double magW,
  ) {
    final long = math.pow(10, 0.5 * magW - 1.85).toDouble() / 2;
    final epicentralDistance = epicenter.distanceTo(point) / 1000;
    final hypocentralDistance =
        math.sqrt(depth * depth + epicentralDistance * epicentralDistance) -
        long;
    final x = math.max(hypocentralDistance, 3.0);
    final gpv600 = math
        .pow(
          10,
          0.58 * magW +
              0.0038 * depth -
              1.29 -
              math.log(x + 0.0028 * math.pow(10, 0.5 * magW)) / math.ln10 -
              0.002 * x,
        )
        .toDouble();
    final pgv = gpv600 * 1.31;
    return 2.68 + 1.72 * math.log(pgv) / math.ln10;
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
      intensity = areaPgv(epicenter, user, depth, mag);
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

    final regions = <String, ({double dist, double i})>{};
    var maxIntensity = 0.0;
    regionCentroids.forEach((code, centroid) {
      final surfaceDistance = epicenter.distanceTo(centroid) / 1000;
      final dist = math.sqrt(surfaceDistance * surfaceDistance + depthSquared);
      final pga = pgaFactor * math.pow(dist, -1.607);
      var i = Intensity.fromPga(pga);
      if (i >= 4.5) {
        i = areaPgv(epicenter, centroid, depth, mag);
      }
      if (i > maxIntensity) maxIntensity = i;
      regions[code] = (dist: dist, i: i);
    });
    return (regions: regions, maxIntensity: maxIntensity);
  }

  /// Analytic P/S travel-time estimate (seconds) for epicentral [distance] (km)
  /// and focal [depth] (km), using the layered-velocity ray approximation.
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

    final sqrt3 = math.sqrt(3);
    final g0s = g0 / sqrt3;
    final gs = bigG / sqrt3;
    final gsRatio = g0s / gs;
    final zcs = -gsRatio;
    final xcs = (xbSquared - 2 * gsRatio * za - zaSquared) / twoXb;
    var thetaAs = math.atan((za - zcs) / xcs);
    if (thetaAs < 0) thetaAs += math.pi;
    thetaAs = math.pi - thetaAs;
    final thetaBs = math.atan(-zcs / (xb - xcs));
    var stime =
        (1 / gs) * math.log(math.tan(thetaAs / 2) / math.tan(thetaBs / 2));

    if (distance / ptime > 7) ptime = distance / 7;
    if (distance / stime > 4) stime = distance / 4;
    return WaveTime(p: ptime, s: stime);
  }
}
