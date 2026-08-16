/// Satellite passes — SGP4, the model the elements are actually defined by.
///
/// A two-line element set is not a state vector. It is a set of *mean*
/// elements fitted so that one specific propagator reproduces the orbit, and
/// that propagator is SGP4. Feeding TLE numbers to a plain Keplerian
/// integrator gives an answer that looks reasonable and is kilometres wrong
/// within hours, so the model is implemented here in full rather than
/// approximated (Spacetrack Report #3, near-Earth case; the deep-space terms
/// are omitted, which excludes orbits with periods over 225 minutes — every
/// satellite anyone watches by eye is well inside that).
///
/// **The honest caveat, and it is a real one.** TLEs go stale. Atmospheric
/// drag is not predictable, so the ISS's elements are good for days, not
/// months, and a pass computed from a month-old element set can be minutes
/// out. Everything else in this package is closed-form and correct for
/// centuries; this one is not, and the age of the elements is carried on the
/// result ([TleSet.ageAt]) so a caller can show it rather than imply a
/// precision it does not have. The bundled snapshot is a starting point, not a
/// promise — a fresher set can be handed in without touching the propagator.
///
/// **Measured** against the SGP4 verification vectors from Spacetrack Report
/// #3 in `test/core/astro/`.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';

/// Earth's equatorial radius in the WGS-72 system SGP4 is defined on, km.
const double _earthRadiusKm = 6378.135;

/// √(GM) in earth-radii^1.5 per minute — SGP4's gravitational constant.
const double _ke = 0.0743669161;

/// J2, J3 and J4 folded into the forms the model uses.
///
/// `_a30` is A(3,0) = −J3·aE³. J3 is itself negative (−0.253881e-5), so the
/// constant here is **positive** — dropping that negation is a sign error that
/// leaves the in-plane velocity components right and the out-of-plane one
/// nearly three times too large.
const double _k2 = 5.413080e-4;
const double _k4 = 0.62098875e-6;
const double _a30 = 0.253881e-5;

/// A parsed two-line element set.
class TleSet {
  const TleSet({
    required this.name,
    required this.catalogNumber,
    required this.epoch,
    required this.meanMotion,
    required this.eccentricity,
    required this.inclination,
    required this.rightAscensionOfNode,
    required this.argumentOfPerigee,
    required this.meanAnomaly,
    required this.bstar,
  });

  final String name;
  final int catalogNumber;

  /// The instant the elements describe.
  final DateTime epoch;

  /// Radians per minute.
  final double meanMotion;

  final double eccentricity;

  /// Radians.
  final double inclination;
  final double rightAscensionOfNode;
  final double argumentOfPerigee;
  final double meanAnomaly;

  /// The drag term, in inverse earth radii.
  final double bstar;

  /// How old the elements are at [utc] — the number that decides whether to
  /// trust the answer.
  Duration ageAt(DateTime utc) => utc.difference(epoch);

  /// Parses the standard three-line form (name, line 1, line 2).
  ///
  /// The columns are fixed-width by specification, so they are read by
  /// position rather than by splitting: several fields can be blank or
  /// signed-with-a-space and would vanish under a whitespace split.
  factory TleSet.parse(String name, String line1, String line2) {
    double implied(String field) {
      // "89427-4" means 0.89427e-4; the exponent sign is the last character.
      final mantissa = field.substring(0, 6).trim();
      final exponent = field.substring(6).trim();
      if (mantissa.isEmpty || mantissa == '00000') return 0;
      final sign = mantissa.startsWith('-') ? -1 : 1;
      final digits = mantissa.replaceAll(RegExp('[+-]'), '');
      return sign *
          double.parse('0.$digits') *
          math.pow(10, int.parse(exponent)).toDouble();
    }

    final epochField = double.parse(line1.substring(18, 32));
    final twoDigitYear = epochField ~/ 1000;
    final year = twoDigitYear < 57 ? 2000 + twoDigitYear : 1900 + twoDigitYear;
    final dayOfYear = epochField - twoDigitYear * 1000;
    final epoch = DateTime.utc(year).add(
      Duration(
        microseconds: ((dayOfYear - 1) * Duration.microsecondsPerDay).round(),
      ),
    );

    return TleSet(
      name: name.trim(),
      catalogNumber: int.parse(line1.substring(2, 7).trim()),
      epoch: epoch,
      // Revolutions per day → radians per minute.
      meanMotion:
          double.parse(line2.substring(52, 63).trim()) * 2 * math.pi / 1440,
      eccentricity: double.parse('0.${line2.substring(26, 33).trim()}'),
      inclination: double.parse(line2.substring(8, 16).trim()) * degrees,
      rightAscensionOfNode:
          double.parse(line2.substring(17, 25).trim()) * degrees,
      argumentOfPerigee: double.parse(line2.substring(34, 42).trim()) * degrees,
      meanAnomaly: double.parse(line2.substring(43, 51).trim()) * degrees,
      bstar: implied(line1.substring(53, 61)),
    );
  }

  /// Every element set in a standard TLE file.
  static List<TleSet> parseAll(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();
    final sets = <TleSet>[];
    for (var i = 0; i + 2 < lines.length; i += 3) {
      if (!lines[i + 1].startsWith('1 ') || !lines[i + 2].startsWith('2 ')) {
        continue;
      }
      sets.add(TleSet.parse(lines[i], lines[i + 1], lines[i + 2]));
    }
    return sets;
  }
}

/// A satellite's position and velocity in the TEME frame SGP4 works in.
class SatelliteState {
  const SatelliteState({required this.position, required this.velocity});

  /// Kilometres.
  final (double, double, double) position;

  /// Kilometres per second.
  final (double, double, double) velocity;
}

/// The SGP4 propagator, set up once per element set.
///
/// The expensive part is the initialisation — recovering the original mean
/// motion and the drag coefficients — so it is done in the constructor and a
/// propagation is then just arithmetic. A pass search evaluates this thousands
/// of times.
class Sgp4 {
  Sgp4(this.elements) {
    final cosInclination = math.cos(elements.inclination);
    final theta2 = cosInclination * cosInclination;
    final e0 = elements.eccentricity;
    final betaSquared = 1 - e0 * e0;
    final beta0 = math.sqrt(betaSquared);

    // Recover the original mean motion and semi-major axis from the Kozai
    // element in the TLE (Spacetrack #3, eqns 1-6).
    final a1 = math.pow(_ke / elements.meanMotion, 2 / 3).toDouble();
    final tempA = 1.5 * _k2 * (3 * theta2 - 1) / (betaSquared * beta0);
    final delta1 = tempA / (a1 * a1);
    final a0 =
        a1 *
        (1 -
            delta1 / 3 -
            delta1 * delta1 -
            134 / 81 * delta1 * delta1 * delta1);
    final delta0 = tempA / (a0 * a0);
    _meanMotion = elements.meanMotion / (1 + delta0);
    _semiMajorAxis = a0 / (1 - delta0);

    // The atmospheric model is lowered for satellites that dip low.
    final perigee = (_semiMajorAxis * (1 - e0) - 1) * _earthRadiusKm;
    var s = 1.01222928;
    var qoms24 = 1.88027916e-9;
    if (perigee < 156) {
      final sTemp = perigee < 98 ? 20.0 : perigee - 78.0;
      qoms24 = math.pow((120 - sTemp) / _earthRadiusKm, 4).toDouble();
      s = sTemp / _earthRadiusKm + 1;
    }

    final xi = 1 / (_semiMajorAxis - s);
    final eta = _semiMajorAxis * e0 * xi;
    final etaSquared = eta * eta;
    final eeta = e0 * eta;
    final psi = (1 - etaSquared).abs();
    final coef = qoms24 * math.pow(xi, 4).toDouble();
    final coef1 = coef / math.pow(psi, 3.5);

    final c2 =
        coef1 *
        _meanMotion *
        (_semiMajorAxis * (1 + 1.5 * etaSquared + eeta * (4 + etaSquared)) +
            1.5 *
                _k2 *
                xi /
                psi *
                (-0.5 + 1.5 * theta2) *
                (8 + 24 * etaSquared + 3 * etaSquared * etaSquared));
    _c1 = elements.bstar * c2;
    _c3 = e0 > 1e-4
        ? coef *
              xi *
              _a30 *
              _meanMotion *
              math.sin(elements.inclination) /
              (_k2 * e0)
        : 0.0;
    _c4 =
        2 *
        _meanMotion *
        coef1 *
        _semiMajorAxis *
        betaSquared *
        (eta * (2 + 0.5 * etaSquared) +
            e0 * (0.5 + 2 * etaSquared) -
            2 *
                _k2 *
                xi /
                (_semiMajorAxis * psi) *
                (-3 *
                        (3 * theta2 - 1) *
                        (1 +
                            1.5 * etaSquared -
                            2 * eeta -
                            0.5 * eeta * etaSquared) +
                    0.75 *
                        (1 - theta2) *
                        (2 * etaSquared - eeta - eeta * etaSquared) *
                        math.cos(2 * elements.argumentOfPerigee)));
    _c5 =
        2 *
        coef1 *
        _semiMajorAxis *
        betaSquared *
        (1 + 2.75 * (etaSquared + eeta) + eeta * etaSquared);

    final beta4 = betaSquared * betaSquared;
    final a2 = _semiMajorAxis * _semiMajorAxis;
    final a4 = a2 * a2;
    _meanAnomalyDot =
        _meanMotion *
        (1 +
            3 * _k2 * (-1 + 3 * theta2) / (2 * a2 * betaSquared * beta0) +
            3 *
                _k2 *
                _k2 *
                (13 - 78 * theta2 + 137 * theta2 * theta2) /
                (16 * a4 * beta4 * betaSquared * beta0));
    _perigeeDot =
        _meanMotion *
        (-3 * _k2 * (1 - 5 * theta2) / (2 * a2 * beta4) +
            3 *
                _k2 *
                _k2 *
                (7 - 114 * theta2 + 395 * theta2 * theta2) /
                (16 * a4 * beta4 * beta4) +
            5 *
                _k4 *
                (3 - 36 * theta2 + 49 * theta2 * theta2) /
                (4 * a4 * beta4 * beta4));
    _nodeDot =
        _meanMotion *
        (-3 * _k2 * cosInclination / (a2 * beta4) +
            3 *
                _k2 *
                _k2 *
                (4 * cosInclination - 19 * theta2 * cosInclination) /
                (2 * a4 * beta4 * beta4) +
            5 *
                _k4 *
                cosInclination *
                (3 - 7 * theta2) /
                (2 * a4 * beta4 * beta4));

    _d2 = 4 * _semiMajorAxis * xi * _c1 * _c1;
    final temp = _d2 * xi * _c1 / 3;
    _d3 = (17 * _semiMajorAxis + s) * temp;
    _d4 =
        0.5 *
        temp *
        _semiMajorAxis *
        xi *
        (221 * _semiMajorAxis + 31 * s) *
        _c1;

    _xi = xi;
    _eta = eta;
    _qoms24 = qoms24;
    _theta = cosInclination;
    _beta0 = beta0;
  }

  final TleSet elements;

  late final double _meanMotion;
  late final double _semiMajorAxis;
  late final double _c1;
  late final double _c3;
  late final double _c4;
  late final double _c5;
  late final double _d2;
  late final double _d3;
  late final double _d4;
  late final double _meanAnomalyDot;
  late final double _perigeeDot;
  late final double _nodeDot;
  late final double _xi;
  late final double _eta;
  late final double _qoms24;
  late final double _theta;
  late final double _beta0;

  /// The satellite's TEME state at [utc].
  SatelliteState at(DateTime utc) =>
      propagate(utc.difference(elements.epoch).inMicroseconds / 6e7);

  /// The state [minutes] after the element epoch.
  SatelliteState propagate(double minutes) {
    final t = minutes;
    final e0 = elements.eccentricity;

    // Secular effects of drag and gravity.
    final meanAnomalyDf = elements.meanAnomaly + _meanAnomalyDot * t;
    final perigeeDf = elements.argumentOfPerigee + _perigeeDot * t;
    final nodeDf = elements.rightAscensionOfNode + _nodeDot * t;

    final deltaPerigee =
        elements.bstar * _c3 * math.cos(elements.argumentOfPerigee) * t;
    final deltaMean = e0 > 1e-4
        ? -2 /
              3 *
              _qoms24 *
              elements.bstar *
              math.pow(_xi, 4) /
              (e0 * _eta) *
              (math.pow(1 + _eta * math.cos(meanAnomalyDf), 3) -
                  math.pow(1 + _eta * math.cos(elements.meanAnomaly), 3))
        : 0.0;

    final meanAnomaly = meanAnomalyDf + deltaPerigee + deltaMean;
    final perigee = perigeeDf - deltaPerigee - deltaMean;
    final node =
        nodeDf -
        10.5 *
            _meanMotion *
            _k2 *
            _theta /
            (_semiMajorAxis * _semiMajorAxis * _beta0 * _beta0) *
            _c1 *
            t *
            t;

    final eccentricity =
        e0 -
        elements.bstar * _c4 * t -
        elements.bstar *
            _c5 *
            (math.sin(meanAnomaly) - math.sin(elements.meanAnomaly));
    final a =
        _semiMajorAxis *
        math.pow(
          1 - _c1 * t - _d2 * t * t - _d3 * t * t * t - _d4 * t * t * t * t,
          2,
        );
    final l =
        meanAnomaly +
        perigee +
        node +
        _meanMotion *
            (1.5 * _c1 * t * t +
                (_d2 + 2 * _c1 * _c1) * t * t * t +
                0.25 *
                    (3 * _d3 + 12 * _c1 * _d2 + 10 * _c1 * _c1 * _c1) *
                    t *
                    t *
                    t *
                    t +
                0.2 *
                    (3 * _d4 +
                        12 * _c1 * _d3 +
                        6 * _d2 * _d2 +
                        30 * _c1 * _c1 * _d2 +
                        15 * _c1 * _c1 * _c1 * _c1) *
                    t *
                    t *
                    t *
                    t *
                    t);
    final beta = math.sqrt(1 - eccentricity * eccentricity);
    final n = _ke / math.pow(a, 1.5);

    // Long-period periodics.
    final axn = eccentricity * math.cos(perigee);
    final temp = 1 / (a * beta * beta);
    final xll =
        temp *
        _a30 *
        math.sin(elements.inclination) /
        (8 * _k2) *
        axn *
        (3 + 5 * _theta) /
        (1 + _theta);
    final aynl = temp * _a30 * math.sin(elements.inclination) / (4 * _k2);
    final ayn = eccentricity * math.sin(perigee) + aynl;

    // Kepler's equation for (E + ω).
    final u = turn(l + xll - node);
    var eccentricAnomaly = u;
    for (var i = 0; i < 10; i++) {
      final sinEw = math.sin(eccentricAnomaly);
      final cosEw = math.cos(eccentricAnomaly);
      var delta =
          (u - ayn * cosEw + axn * sinEw - eccentricAnomaly) /
          (1 - ayn * sinEw - axn * cosEw);
      if (delta.abs() > 0.95) delta = delta.sign * 0.95;
      eccentricAnomaly += delta;
      if (delta.abs() < 1e-12) break;
    }

    final sinEw = math.sin(eccentricAnomaly);
    final cosEw = math.cos(eccentricAnomaly);
    final ecosE = axn * cosEw + ayn * sinEw;
    final esinE = axn * sinEw - ayn * cosEw;
    final eSquared = axn * axn + ayn * ayn;
    final pl = a * (1 - eSquared);
    final r = a * (1 - ecosE);
    final rdot = _ke * math.sqrt(a) / r * esinE;
    final rfdot = _ke * math.sqrt(pl) / r;
    final betaL = math.sqrt(1 - eSquared);
    final temp3 = esinE / (1 + betaL);
    final cosu = a / r * (cosEw - axn + ayn * temp3);
    final sinu = a / r * (sinEw - ayn - axn * temp3);
    final uAngle = math.atan2(sinu, cosu);

    final sin2u = 2 * sinu * cosu;
    final cos2u = 1 - 2 * sinu * sinu;
    final theta2 = _theta * _theta;

    // Short-period periodics.
    final rk =
        r * (1 - 1.5 * _k2 * betaL / (pl * pl) * (3 * theta2 - 1)) +
        0.5 * _k2 / pl * (1 - theta2) * cos2u;
    final uk = uAngle - 0.25 * _k2 / (pl * pl) * (7 * theta2 - 1) * sin2u;
    final nodek = node + 1.5 * _k2 * _theta / (pl * pl) * sin2u;
    final inclinationk =
        elements.inclination +
        1.5 * _k2 * _theta * math.sin(elements.inclination) / (pl * pl) * cos2u;
    final rdotk = rdot - _k2 * n / pl * (1 - theta2) * sin2u;
    final rfdotk =
        rfdot + _k2 * n / pl * ((1 - theta2) * cos2u + 1.5 * (1 - 3 * theta2));

    // Orientation vectors.
    final sinuk = math.sin(uk);
    final cosuk = math.cos(uk);
    final sinik = math.sin(inclinationk);
    final cosik = math.cos(inclinationk);
    final sinnok = math.sin(nodek);
    final cosnok = math.cos(nodek);

    final ux = -sinnok * cosik * sinuk + cosnok * cosuk;
    final uy = cosnok * cosik * sinuk + sinnok * cosuk;
    final uz = sinik * sinuk;
    final vx = -sinnok * cosik * cosuk - cosnok * sinuk;
    final vy = cosnok * cosik * cosuk - sinnok * sinuk;
    final vz = sinik * cosuk;

    return SatelliteState(
      position: (
        rk * ux * _earthRadiusKm,
        rk * uy * _earthRadiusKm,
        rk * uz * _earthRadiusKm,
      ),
      velocity: (
        (rdotk * ux + rfdotk * vx) * _earthRadiusKm / 60,
        (rdotk * uy + rfdotk * vy) * _earthRadiusKm / 60,
        (rdotk * uz + rfdotk * vz) * _earthRadiusKm / 60,
      ),
    );
  }

  /// Where the satellite appears from the ground at [utc].
  ///
  /// TEME is an inertial frame, so the Earth is rotated under it by the
  /// sidereal angle before the observer's position is subtracted.
  Horizontal lookFrom(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) {
    final state = at(utc);
    final gmst = greenwichSiderealTime(utc);
    final localSidereal = gmst + longitude * degrees;

    // The observer, in the same rotating-into-inertial sense.
    final phi = latitude * degrees;
    const flattening = 1 / 298.26; // WGS-72, to match SGP4's Earth.
    final c =
        1 /
        math.sqrt(
          1 + flattening * (flattening - 2) * math.pow(math.sin(phi), 2),
        );
    final observerX =
        _earthRadiusKm * c * math.cos(phi) * math.cos(localSidereal);
    final observerY =
        _earthRadiusKm * c * math.cos(phi) * math.sin(localSidereal);
    final observerZ =
        _earthRadiusKm * c * math.pow(1 - flattening, 2) * math.sin(phi);

    final rx = state.position.$1 - observerX;
    final ry = state.position.$2 - observerY;
    final rz = state.position.$3 - observerZ.toDouble();

    // Rotate the range vector into the observer's south-east-zenith frame.
    final sinPhi = math.sin(phi);
    final cosPhi = math.cos(phi);
    final sinTheta = math.sin(localSidereal);
    final cosTheta = math.cos(localSidereal);
    final south = sinPhi * cosTheta * rx + sinPhi * sinTheta * ry - cosPhi * rz;
    final east = -sinTheta * rx + cosTheta * ry;
    final zenith =
        cosPhi * cosTheta * rx + cosPhi * sinTheta * ry + sinPhi * rz;

    final range = math.sqrt(south * south + east * east + zenith * zenith);
    return Horizontal(
      altitude: math.asin(zenith / range),
      azimuth: turn(math.atan2(-east, south) + math.pi),
    );
  }
}

/// One visible pass.
class SatellitePass {
  const SatellitePass({
    required this.rises,
    required this.peaks,
    required this.sets,
    required this.peakAltitude,
    required this.peakAzimuth,
  });

  final DateTime rises;
  final DateTime peaks;
  final DateTime sets;

  /// Radians.
  final double peakAltitude;
  final double peakAzimuth;

  Duration get length => sets.difference(rises);
}

/// Finding passes.
abstract final class SatellitePasses {
  /// Passes of [satellite] over [window] from [from] that reach at least
  /// [minimumAltitude] (10° by default — lower than that and buildings win).
  ///
  /// Only geometric visibility: whether the satellite is above the horizon.
  /// Whether it is *lit* — sunlit while the observer is in darkness — is the
  /// other half, and [sunlitOnly] applies it.
  static List<SatellitePass> find(
    Sgp4 satellite, {
    required DateTime from,
    required double latitude,
    required double longitude,
    Duration window = const Duration(hours: 24),
    double minimumAltitude = 10 * degrees,
    bool sunlitOnly = true,
  }) {
    final passes = <SatellitePass>[];
    const step = Duration(seconds: 30);
    DateTime? rose;
    var best = -math.pi;
    var bestAt = from;
    var bestAzimuth = 0.0;

    for (var at = from; at.isBefore(from.add(window)); at = at.add(step)) {
      final look = satellite.lookFrom(
        at,
        latitude: latitude,
        longitude: longitude,
      );
      final visible =
          look.altitude > 0 &&
          (!sunlitOnly || _isSunlit(satellite, at, latitude, longitude));
      if (visible) {
        rose ??= at;
        if (look.altitude > best) {
          best = look.altitude;
          bestAt = at;
          bestAzimuth = look.azimuth;
        }
      } else if (rose != null) {
        if (best >= minimumAltitude) {
          passes.add(
            SatellitePass(
              rises: rose,
              peaks: bestAt,
              sets: at,
              peakAltitude: best,
              peakAzimuth: bestAzimuth,
            ),
          );
        }
        rose = null;
        best = -math.pi;
      }
    }
    return passes;
  }

  /// Whether the satellite is in sunlight while the ground is dark — the
  /// condition that makes a pass actually visible to the eye.
  static bool _isSunlit(
    Sgp4 satellite,
    DateTime at,
    double latitude,
    double longitude,
  ) {
    // The ground must be at least in civil twilight, or the sky outshines it.
    final observer = Observer(latitude: latitude, longitude: longitude);
    final sunAltitude = observer
        .lookAt(SunEphemeris.at(at).equatorial, at)
        .altitude;
    if (sunAltitude > civilTwilight) return false;
    final sun = _sunTeme(at);

    // And the satellite must be outside the Earth's shadow cylinder.
    final position = satellite.at(at).position;
    final dot =
        position.$1 * sun.$1 + position.$2 * sun.$2 + position.$3 * sun.$3;
    if (dot > 0) return true;
    final distance = math.sqrt(
      position.$1 * position.$1 +
          position.$2 * position.$2 +
          position.$3 * position.$3,
    );
    final perpendicular = math.sqrt(distance * distance - dot * dot);
    return perpendicular > _earthRadiusKm;
  }

  /// A unit vector toward the Sun in the same frame the propagator uses.
  static (double, double, double) _sunTeme(DateTime at) {
    final t = julianCenturies(at);
    final meanLongitude = (280.46 + 36000.77 * t) * degrees;
    final meanAnomaly = (357.5277233 + 35999.05034 * t) * degrees;
    final longitude =
        meanLongitude +
        (1.914666471 * math.sin(meanAnomaly) +
                0.019994643 * math.sin(2 * meanAnomaly)) *
            degrees;
    final obliquity = meanObliquity(t);
    return (
      math.cos(longitude),
      math.cos(obliquity) * math.sin(longitude),
      math.sin(obliquity) * math.sin(longitude),
    );
  }
}
