/// Where the planets are, and how bright.
///
/// Elements, not series. JPL's *Keplerian Elements for Approximate Positions
/// of the Major Planets* gives six orbital elements and six per-century rates
/// per planet, valid 1800–2050 — one table of ninety-six numbers against the
/// thousands a VSOP87 truncation would need, with published error bounds
/// (15″ for Mercury, 40″ for Mars, 600″ for Saturn in heliocentric longitude).
/// For "is Jupiter up tonight, and where do I point", that is far finer than
/// the question.
///
/// Three things have to be right or the answer is quietly wrong by a
/// noticeable amount, and each is easy to skip:
///
///   1. **Geocentric, not heliocentric.** The Earth's own orbital position is
///      subtracted, so this solves for both bodies and takes the difference.
///   2. **Light time.** Saturn is over an hour away; using its position *now*
///      rather than where it was when the light left puts it up to an
///      arcminute off. One iteration closes it.
///   3. **Precession to the equinox of date.** The elements are referred to
///      J2000, but sidereal time is of date. Mixing them is a 0.36° error
///      today — larger than every other error here combined.
///
/// **Measured** against JPL Horizons over 2024–2027 in `test/core/astro/`.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';

/// Speed of light in astronomical units per day — the light-time correction.
const double _auPerDay = 173.144632674;

/// The naked-eye and small-telescope planets, in orbital order. The Earth is
/// not a target but is solved alongside every one of them.
enum Planet { mercury, venus, mars, jupiter, saturn, uranus, neptune }

/// A planet's geocentric place and appearance at one instant.
class PlanetEphemeris {
  const PlanetEphemeris({
    required this.planet,
    required this.longitude,
    required this.latitude,
    required this.distanceAu,
    required this.heliocentricDistanceAu,
    required this.elongation,
    required this.signedElongation,
    required this.phaseAngle,
    required this.magnitude,
    required this.centuries,
  });

  final Planet planet;

  /// Geocentric ecliptic longitude and latitude **of date**, radians.
  final double longitude;
  final double latitude;

  /// Distance from the Earth, astronomical units.
  final double distanceAu;

  /// Distance from the Sun, astronomical units.
  final double heliocentricDistanceAu;

  /// Angular distance from the Sun as seen from the Earth, radians. Under
  /// about 15° the planet is lost in twilight whatever its magnitude; the
  /// greatest elongations of Mercury and Venus are the maxima of this.
  final double elongation;

  /// Sun–planet–Earth angle, radians. Zero is fully lit; it only gets large
  /// for the inner planets, which is why only they show phases.
  final double phaseAngle;

  /// Apparent visual magnitude (Astronomical Almanac / Meeus ch. 41).
  final double magnitude;

  final double centuries;

  /// Illuminated fraction of the disc, 0…1.
  double get illuminated => (1 + math.cos(phaseAngle)) / 2;

  /// Elongation with a sign: positive east of the Sun (sets after it, so an
  /// evening object), negative west (rises before it — a morning object).
  /// The unsigned [elongation] cannot tell those apart, and which one it is
  /// decides whether you look after dusk or before dawn.
  final double signedElongation;

  /// Sets after the Sun, so it is visible in the evening sky.
  bool get isEvening => signedElongation > 0;

  /// Equatorial coordinates of date.
  Equatorial get equatorial => Equatorial.fromEcliptic(
    longitude: longitude,
    latitude: latitude,
    obliquity: meanObliquity(centuries),
    distanceKm: distanceAu * astronomicalUnitKm,
  );

  /// The planet's position at [utc].
  factory PlanetEphemeris.at(Planet planet, DateTime utc) {
    final t = julianCenturies(utc);
    final earth = _heliocentric(_earth, t);

    // Light time: solve where the planet was when the light now arriving left
    // it. One pass is enough — the correction to the correction is under a
    // milliarcsecond even for Neptune.
    var body = _heliocentric(_elements[planet]!, t);
    var offset = _difference(body, earth);
    final firstDistance = _length(offset);
    body = _heliocentric(
      _elements[planet]!,
      t - firstDistance / _auPerDay / 36525.0,
    );
    offset = _difference(body, earth);

    final distance = _length(offset);
    final heliocentric = _length(body);
    final sunDistance = _length(earth);

    // Precession of the ecliptic frame from J2000 to the equinox of date.
    final precession = (1.396971 * t + 0.0003086 * t * t) * degrees;
    final longitude = turn(math.atan2(offset.y, offset.x) + precession);
    final latitude = math.asin((offset.z / distance).clamp(-1.0, 1.0));

    // The Sun–planet–Earth triangle gives both the elongation seen from here
    // and the phase angle seen from there.
    final elongation = math.acos(
      ((distance * distance +
                  sunDistance * sunDistance -
                  heliocentric * heliocentric) /
              (2 * distance * sunDistance))
          .clamp(-1.0, 1.0),
    );
    final phaseAngle = math.acos(
      ((heliocentric * heliocentric +
                  distance * distance -
                  sunDistance * sunDistance) /
              (2 * heliocentric * distance))
          .clamp(-1.0, 1.0),
    );

    return PlanetEphemeris(
      planet: planet,
      longitude: longitude,
      latitude: latitude,
      distanceAu: distance,
      heliocentricDistanceAu: heliocentric,
      elongation: elongation,
      signedElongation: signedTurn(
        longitude - SunEphemeris.atCenturies(t).longitude,
      ),
      phaseAngle: phaseAngle,
      magnitude: _magnitude(
        planet,
        heliocentric,
        distance,
        phaseAngle / degrees,
        longitude,
        latitude,
        t,
      ),
      centuries: t,
    );
  }

  /// The planet's track, for the shared rise/set solver.
  static SkyTrack trackOf(Planet planet) =>
      (utc) => PlanetEphemeris.at(planet, utc).equatorial;

  /// Heliocentric rectangular ecliptic coordinates (J2000), astronomical
  /// units, from the Keplerian elements at [t] Julian centuries.
  static _Vector _heliocentric(_Elements e, double t) {
    final a = e.semiMajorAxis + e.semiMajorAxisRate * t;
    final eccentricity = e.eccentricity + e.eccentricityRate * t;
    final inclination = (e.inclination + e.inclinationRate * t) * degrees;
    final meanLongitude = e.meanLongitude + e.meanLongitudeRate * t;
    final perihelion = e.perihelion + e.perihelionRate * t;
    final node = (e.node + e.nodeRate * t) * degrees;

    final meanAnomaly = signedTurn((meanLongitude - perihelion) * degrees);
    final anomaly = eccentricAnomaly(meanAnomaly, eccentricity);
    final argument = (perihelion) * degrees - node;

    // In the orbital plane, then rotated by the argument of perihelion, the
    // inclination and the node — the standard three-rotation chain.
    final x = a * (math.cos(anomaly) - eccentricity);
    final y =
        a * math.sqrt(1 - eccentricity * eccentricity) * math.sin(anomaly);

    final cosArgument = math.cos(argument);
    final sinArgument = math.sin(argument);
    final cosNode = math.cos(node);
    final sinNode = math.sin(node);
    final cosInclination = math.cos(inclination);
    final sinInclination = math.sin(inclination);

    final xOrbit = cosArgument * x - sinArgument * y;
    final yOrbit = sinArgument * x + cosArgument * y;

    return _Vector(
      cosNode * xOrbit - sinNode * yOrbit * cosInclination,
      sinNode * xOrbit + cosNode * yOrbit * cosInclination,
      yOrbit * sinInclination,
    );
  }

  static _Vector _difference(_Vector a, _Vector b) =>
      _Vector(a.x - b.x, a.y - b.y, a.z - b.z);

  static double _length(_Vector v) =>
      math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);

  /// Apparent magnitude (Meeus ch. 41, the Astronomical Almanac forms).
  ///
  /// Saturn carries a ring term because its rings swing its brightness by well
  /// over a magnitude between edge-on and wide open — leaving it out would
  /// make the single most conspicuous planet the least accurate entry.
  static double _magnitude(
    Planet planet,
    double r,
    double delta,
    double phaseDegrees,
    double longitude,
    double latitude,
    double t,
  ) {
    final base = 5 * (math.log(r * delta) / math.ln10);
    final i = phaseDegrees;
    return switch (planet) {
      Planet.mercury =>
        -0.42 + base + 0.0380 * i - 0.000273 * i * i + 0.000002 * i * i * i,
      Planet.venus =>
        -4.40 + base + 0.0009 * i + 0.000239 * i * i - 0.00000065 * i * i * i,
      Planet.mars => -1.52 + base + 0.016 * i,
      Planet.jupiter => -9.40 + base + 0.005 * i,
      Planet.saturn => _saturn(base, longitude, latitude, t),
      Planet.uranus => -7.19 + base,
      Planet.neptune => -6.87 + base,
    };
  }

  /// Saturn, with the ring tilt. `B` is the Saturnicentric latitude of the
  /// Earth — how far the rings are opened toward us (Meeus 45.1). At B = 0 the
  /// rings are edge-on and vanish; near ±27° they are at their brightest.
  static double _saturn(
    double base,
    double longitude,
    double latitude,
    double t,
  ) {
    const ringInclination = 28.075 * degrees;
    final ringNode = (169.508 + 1.394 * t) * degrees;
    final sinB =
        math.sin(ringInclination) *
            math.cos(latitude) *
            math.sin(longitude - ringNode) -
        math.cos(ringInclination) * math.sin(latitude);
    return -8.88 + base + 0.044 * 0 - 2.60 * sinB.abs() + 1.25 * sinB * sinB;
  }
}

class _Vector {
  const _Vector(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

/// Keplerian elements and their per-century rates.
class _Elements {
  const _Elements({
    required this.semiMajorAxis,
    required this.semiMajorAxisRate,
    required this.eccentricity,
    required this.eccentricityRate,
    required this.inclination,
    required this.inclinationRate,
    required this.meanLongitude,
    required this.meanLongitudeRate,
    required this.perihelion,
    required this.perihelionRate,
    required this.node,
    required this.nodeRate,
  });

  /// Astronomical units, and au per century.
  final double semiMajorAxis;
  final double semiMajorAxisRate;

  /// Dimensionless, and per century.
  final double eccentricity;
  final double eccentricityRate;

  /// Degrees, and degrees per century, for the remaining four.
  final double inclination;
  final double inclinationRate;
  final double meanLongitude;
  final double meanLongitudeRate;

  /// Longitude of perihelion ϖ, not the argument ω.
  final double perihelion;
  final double perihelionRate;
  final double node;
  final double nodeRate;
}

/// The Earth–Moon barycentre. Its offset from the Earth's centre is at most
/// 4700 km, which at Mars' distance is under two arcseconds — a twentieth of
/// this table's own error for Mars.
const _earth = _Elements(
  semiMajorAxis: 1.00000261,
  semiMajorAxisRate: 0.00000562,
  eccentricity: 0.01671123,
  eccentricityRate: -0.00004392,
  inclination: -0.00001531,
  inclinationRate: -0.01294668,
  meanLongitude: 100.46457166,
  meanLongitudeRate: 35999.37244981,
  perihelion: 102.93768193,
  perihelionRate: 0.32327364,
  node: 0.0,
  nodeRate: 0.0,
);

/// JPL's table 1, valid 1800–2050. Transcribed from
/// `ssd.jpl.nasa.gov/planets/approx_pos.html`; the tests pin it against
/// Horizons, which is what catches a mistyped digit.
const Map<Planet, _Elements> _elements = {
  Planet.mercury: _Elements(
    semiMajorAxis: 0.38709927,
    semiMajorAxisRate: 0.00000037,
    eccentricity: 0.20563593,
    eccentricityRate: 0.00001906,
    inclination: 7.00497902,
    inclinationRate: -0.00594749,
    meanLongitude: 252.25032350,
    meanLongitudeRate: 149472.67411175,
    perihelion: 77.45779628,
    perihelionRate: 0.16047689,
    node: 48.33076593,
    nodeRate: -0.12534081,
  ),
  Planet.venus: _Elements(
    semiMajorAxis: 0.72333566,
    semiMajorAxisRate: 0.00000390,
    eccentricity: 0.00677672,
    eccentricityRate: -0.00004107,
    inclination: 3.39467605,
    inclinationRate: -0.00078890,
    meanLongitude: 181.97909950,
    meanLongitudeRate: 58517.81538729,
    perihelion: 131.60246718,
    perihelionRate: 0.00268329,
    node: 76.67984255,
    nodeRate: -0.27769418,
  ),
  Planet.mars: _Elements(
    semiMajorAxis: 1.52371034,
    semiMajorAxisRate: 0.00001847,
    eccentricity: 0.09339410,
    eccentricityRate: 0.00007882,
    inclination: 1.84969142,
    inclinationRate: -0.00813131,
    meanLongitude: -4.55343205,
    meanLongitudeRate: 19140.30268499,
    perihelion: -23.94362959,
    perihelionRate: 0.44441088,
    node: 49.55953891,
    nodeRate: -0.29257343,
  ),
  Planet.jupiter: _Elements(
    semiMajorAxis: 5.20288700,
    semiMajorAxisRate: -0.00011607,
    eccentricity: 0.04838624,
    eccentricityRate: -0.00013253,
    inclination: 1.30439695,
    inclinationRate: -0.00183714,
    meanLongitude: 34.39644051,
    meanLongitudeRate: 3034.74612775,
    perihelion: 14.72847983,
    perihelionRate: 0.21252668,
    node: 100.47390909,
    nodeRate: 0.20469106,
  ),
  Planet.saturn: _Elements(
    semiMajorAxis: 9.53667594,
    semiMajorAxisRate: -0.00125060,
    eccentricity: 0.05386179,
    eccentricityRate: -0.00050991,
    inclination: 2.48599187,
    inclinationRate: 0.00193609,
    meanLongitude: 49.95424423,
    meanLongitudeRate: 1222.49362201,
    perihelion: 92.59887831,
    perihelionRate: -0.41897216,
    node: 113.66242448,
    nodeRate: -0.28867794,
  ),
  Planet.uranus: _Elements(
    semiMajorAxis: 19.18916464,
    semiMajorAxisRate: -0.00196176,
    eccentricity: 0.04725744,
    eccentricityRate: -0.00004397,
    inclination: 0.77263783,
    inclinationRate: -0.00242939,
    meanLongitude: 313.23810451,
    meanLongitudeRate: 428.48202785,
    perihelion: 170.95427630,
    perihelionRate: 0.40805281,
    node: 74.01692503,
    nodeRate: 0.04240589,
  ),
  Planet.neptune: _Elements(
    semiMajorAxis: 30.06992276,
    semiMajorAxisRate: 0.00026291,
    eccentricity: 0.00859048,
    eccentricityRate: 0.00005105,
    inclination: 1.77004347,
    inclinationRate: 0.00035372,
    meanLongitude: -55.12002969,
    meanLongitudeRate: 218.45945325,
    perihelion: 44.96476227,
    perihelionRate: -0.32241464,
    node: 131.78422574,
    nodeRate: -0.00508664,
  ),
};
