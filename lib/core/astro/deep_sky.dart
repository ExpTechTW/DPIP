/// The Messier catalogue — the 110 objects a small telescope can actually
/// reach, and the standard target list for a night out.
///
/// Positions are J2000, precessed to the equinox of date on use. That matters
/// less here than for the planets (a quarter of a degree over 25 years, on
/// objects tens of arcminutes across), but it is free, and it keeps every
/// coordinate in this package in one frame.
///
/// Common names are kept in English. Translating 110 proper nouns into eleven
/// languages would be eleven sets of guesses that nobody could check, and the
/// catalogue designation — M31, M42 — is what observers actually use and is
/// language-neutral. The *type* is localised, because that is a description
/// rather than a name.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/sky_position.dart';

/// What kind of object — the part of a catalogue entry worth translating.
enum DeepSkyType {
  /// Open cluster.
  oc,

  /// Globular cluster.
  gc,

  /// Spiral galaxy.
  s,

  /// Elliptical galaxy.
  e,

  /// Irregular galaxy.
  i,

  /// Planetary nebula.
  pn,

  /// Supernova remnant.
  snr,

  /// Star-forming region — a diffuse emission nebula.
  sfr,

  /// Reflection nebula.
  rn,

  /// A position only: an asterism or a patch of Milky Way, catalogued by
  /// Messier but not a single object.
  pos,
}

/// One catalogue entry.
class DeepSkyObject {
  const DeepSkyObject({
    required this.messier,
    required this.designation,
    required this.commonName,
    required this.type,
    required this.magnitude,
    required this.rightAscensionJ2000,
    required this.declinationJ2000,
  });

  /// The Messier number, 1-110.
  final int messier;

  /// The NGC/IC designation.
  final String designation;

  /// The English common name, or empty where there is none.
  final String commonName;

  final DeepSkyType type;

  /// Integrated visual magnitude. Deceptive for extended objects — M31 is
  /// magnitude 3.4 and still invisible from a city — so it ranks targets
  /// rather than promising them.
  final double magnitude;

  /// J2000 position, degrees.
  final double rightAscensionJ2000;
  final double declinationJ2000;

  /// `M31`.
  String get label => 'M$messier';

  /// The position at [utc], precessed from J2000 to the equinox of date.
  Equatorial positionAt(DateTime utc) {
    final t = julianCenturies(utc);
    // Rigorous precession would rotate through three angles; over the decades
    // this app spans, the first-order form is within an arcsecond and is what
    // keeps this a table rather than a matrix library.
    final ra = rightAscensionJ2000 * degrees;
    final dec = declinationJ2000 * degrees;
    const mSeconds = 3.07496;
    const nSeconds = 1.33621;
    const nArcsec = 20.0431;
    final years = t * 100;
    return Equatorial(
      rightAscension: turn(
        ra +
            (mSeconds + nSeconds * math.sin(ra) * math.tan(dec)) *
                years *
                15 /
                3600 *
                degrees,
      ),
      declination:
          dec + nArcsec * math.cos(ra) * years / 3600 * degrees,
    );
  }
}

/// The catalogue, indexed by Messier number.
///
/// Packed as `(number, designation, common name, type, magnitude, RA, Dec)`.
/// Source: the Messier list distributed with `d3-celestial`, itself derived
/// from the NGC/IC catalogues.
const List<(int, String, String, DeepSkyType, double, double, double)>
_messier = [
  (1, 'NGC 1952', 'Crab Nebula', DeepSkyType.snr, 8.4, 83.625, 22.0167),
  (2, 'NGC 7089', '', DeepSkyType.gc, 6.5, 323.375, -0.8167),
  (3, 'NGC 5272', '', DeepSkyType.gc, 6.4, 205.55, 28.3833),
  (4, 'NGC 6121', '', DeepSkyType.gc, 5.9, 245.9, -26.5333),
  (5, 'NGC 5904', '', DeepSkyType.gc, 5.8, 229.65, 2.0833),
  (6, 'NGC 6405', 'Butterfly Cluster', DeepSkyType.oc, 4.2, 265.0249, -32.2167),
  (7, 'NGC 6475', 'Ptolemy´s Cluster', DeepSkyType.oc, 3.3, 268.475, -34.8167),
  (8, 'NGC 6523', 'Lagoon Nebula', DeepSkyType.sfr, 5.8, 270.95, -24.3833),
  (9, 'NGC 6333', '', DeepSkyType.gc, 7.9, 259.8, -18.5167),
  (10, 'NGC 6254', '', DeepSkyType.gc, 6.6, 254.2751, -4.1),
  (11, 'NGC 6705', 'Wild Duck Cluster', DeepSkyType.oc, 5.8, 282.775, -6.2667),
  (12, 'NGC 6218', '', DeepSkyType.gc, 6.6, 251.8001, -1.95),
  (13, 'NGC 6205', 'Great Hercules Cluster', DeepSkyType.gc, 5.9, 250.425, 36.4667),
  (14, 'NGC 6402', '', DeepSkyType.gc, 7.6, 264.4001, -3.25),
  (15, 'NGC 7078', '', DeepSkyType.gc, 6.4, 322.5, 12.1667),
  (16, 'NGC 6611', 'Eagle Nebula', DeepSkyType.sfr, 6, 274.7, -13.7833),
  (17, 'NGC 6618', 'Omega Nebula', DeepSkyType.sfr, 7, 275.2, -16.1833),
  (18, 'NGC 6613', '', DeepSkyType.oc, 6.9, 274.9751, -17.1333),
  (19, 'NGC 6273', '', DeepSkyType.gc, 7.2, 255.65, -26.2667),
  (20, 'NGC 6514', 'Trifid Nebula', DeepSkyType.sfr, 8.5, 270.6499, -23.0333),
  (21, 'NGC 6531', '', DeepSkyType.oc, 5.9, 271.1501, -22.5),
  (22, 'NGC 6656', '', DeepSkyType.gc, 5.1, 279.1001, -23.9),
  (23, 'NGC 6494', '', DeepSkyType.oc, 5.5, 269.2001, -19.0167),
  (24, '', 'Milky Way patch', DeepSkyType.pos, 4.5, 274.225, -18.4833),
  (25, 'IC 4725', '', DeepSkyType.oc, 4.6, 277.9, -19.25),
  (26, 'NGC 6694', '', DeepSkyType.oc, 8, 281.2999, -9.4),
  (27, 'NGC 6853', 'Dumbbell Nebula', DeepSkyType.pn, 8.1, 299.8999, 22.7167),
  (28, 'NGC 6626', '', DeepSkyType.gc, 6.9, 276.125, -24.8667),
  (29, 'NGC 6913', '', DeepSkyType.oc, 6.6, 305.975, 38.5333),
  (30, 'NGC 7099', '', DeepSkyType.gc, 7.5, 325.0999, -23.1833),
  (31, 'NGC 224', 'Andromeda', DeepSkyType.s, 3.4, 10.6751, 41.2667),
  (32, 'NGC 221', '', DeepSkyType.e, 8.2, 10.6751, 40.8667),
  (33, 'NGC 598', 'Triangulum', DeepSkyType.s, 5.7, 23.475, 30.65),
  (34, 'NGC 1039', '', DeepSkyType.oc, 5.2, 40.5, 42.7833),
  (35, 'NGC 2168', '', DeepSkyType.oc, 5.1, 92.2249, 24.3333),
  (36, 'NGC 1960', '', DeepSkyType.oc, 6, 84.0251, 34.1333),
  (37, 'NGC 2099', '', DeepSkyType.oc, 5.6, 88.1, 32.55),
  (38, 'NGC 1912', '', DeepSkyType.oc, 6.4, 82.175, 35.8333),
  (39, 'NGC 7092', '', DeepSkyType.oc, 4.6, 323.0501, 48.4333),
  (40, 'WN 4', '', DeepSkyType.pos, 8, 185.5999, 58.0833),
  (41, 'NGC 2287', '', DeepSkyType.oc, 4.5, 101.75, -20.7333),
  (42, 'NGC 1976', 'Orion Nebula', DeepSkyType.sfr, 4, 83.85, -5.45),
  (43, 'NGC 1982', '', DeepSkyType.sfr, 9, 83.9, -5.2667),
  (44, 'NGC 2632', 'Praesepe', DeepSkyType.oc, 3.1, 130.025, 19.9833),
  (45, '', 'Pleiades', DeepSkyType.oc, 1.2, 56.75, 24.1167),
  (46, 'NGC 2437', '', DeepSkyType.oc, 6.1, 115.4501, -14.8167),
  (47, 'NGC 2422', '', DeepSkyType.oc, 4.4, 114.15, -14.5),
  (48, 'NGC 2548', '', DeepSkyType.oc, 5.8, 123.45, -5.8),
  (49, 'NGC 4472', '', DeepSkyType.e, 8.4, 187.4501, 8),
  (50, 'NGC 2323', '', DeepSkyType.oc, 5.9, 105.8, -8.3333),
  (51, 'NGC 5194/5', 'Whirlpool', DeepSkyType.s, 8.1, 202.4749, 47.2),
  (52, 'NGC 7654', '', DeepSkyType.oc, 6.9, 351.05, 61.5833),
  (53, 'NGC 5024', '', DeepSkyType.gc, 7.7, 198.225, 18.1667),
  (54, 'NGC 6715', '', DeepSkyType.gc, 7.7, 283.7749, -30.4833),
  (55, 'NGC 6809', '', DeepSkyType.gc, 7, 295, -30.9667),
  (56, 'NGC 6779', '', DeepSkyType.gc, 8.2, 289.15, 30.1833),
  (57, 'NGC 6720', 'Ring Nebula', DeepSkyType.pn, 9, 283.3999, 33.0333),
  (58, 'NGC 4579', '', DeepSkyType.s, 9.8, 189.425, 11.8167),
  (59, 'NGC 4621', '', DeepSkyType.e, 9.8, 190.5, 11.65),
  (60, 'NGC 4649', '', DeepSkyType.e, 8.8, 190.925, 11.55),
  (61, 'NGC 4303', '', DeepSkyType.s, 9.7, 185.475, 4.4667),
  (62, 'NGC 6266', '', DeepSkyType.gc, 6.6, 255.3, -30.1167),
  (63, 'NGC 5055', 'Sunflower Galaxy', DeepSkyType.s, 8.6, 198.95, 42.0333),
  (64, 'NGC 4826', 'Blackeye Galaxy', DeepSkyType.s, 8.5, 194.175, 21.6833),
  (65, 'NGC 3623', '', DeepSkyType.s, 9.3, 169.725, 13.0833),
  (66, 'NGC 3627', '', DeepSkyType.s, 9, 170.0501, 12.9833),
  (67, 'NGC 2682', '', DeepSkyType.oc, 6.9, 132.6, 11.8167),
  (68, 'NGC 4590', '', DeepSkyType.gc, 8.2, 189.8749, -26.75),
  (69, 'NGC 6637', '', DeepSkyType.gc, 7.7, 277.85, -32.35),
  (70, 'NGC 6681', '', DeepSkyType.gc, 8.1, 280.8, -32.3),
  (71, 'NGC 6838', '', DeepSkyType.gc, 8.3, 298.4501, 18.7833),
  (72, 'NGC 6981', '', DeepSkyType.gc, 9.4, 313.3751, -12.5333),
  (73, 'NGC 6994', '4 Star asterism', DeepSkyType.pos, 10, 314.7251, -12.6333),
  (74, 'NGC 628', '', DeepSkyType.s, 9.2, 24.1751, 15.7833),
  (75, 'NGC 6864', '', DeepSkyType.gc, 8.6, 301.525, -21.9167),
  (76, 'NGC 650/1', 'Little Dumbbell Nebula', DeepSkyType.pn, 11.5, 25.6001, 51.5667),
  (77, 'NGC 1068', 'Cetus A', DeepSkyType.s, 8.8, 40.6751, -0.0167),
  (78, 'NGC 2068', '', DeepSkyType.rn, 8, 86.675, 0.05),
  (79, 'NGC 1904', '', DeepSkyType.gc, 8, 81.125, -24.55),
  (80, 'NGC 6093', '', DeepSkyType.gc, 7.2, 244.2499, -22.9833),
  (81, 'NGC 3031', 'Bode´s Galaxy', DeepSkyType.s, 6.8, 148.8996, 69.0667),
  (82, 'NGC 3034', 'Cigar Galaxy', DeepSkyType.i, 8.4, 148.9496, 69.6833),
  (83, 'NGC 5236', 'Southern Pinwheel', DeepSkyType.s, 7.6, 204.25, -29.8667),
  (84, 'NGC 4374', '', DeepSkyType.e, 9.3, 186.275, 12.8833),
  (85, 'NGC 4382', '', DeepSkyType.e, 9.2, 186.35, 18.1833),
  (86, 'NGC 4406', '', DeepSkyType.e, 9.2, 186.5501, 12.95),
  (87, 'NGC 4486', 'Virgo A', DeepSkyType.e, 8.6, 187.7, 12.4),
  (88, 'NGC 4501', '', DeepSkyType.s, 9.5, 187.9999, 14.4167),
  (89, 'NGC 4552', '', DeepSkyType.e, 9.8, 188.925, 12.55),
  (90, 'NGC 4569', '', DeepSkyType.s, 9.5, 189.2, 13.1667),
  (91, 'NGC 4548', '', DeepSkyType.s, 10.2, 188.85, 14.5),
  (92, 'NGC 6341', '', DeepSkyType.gc, 6.5, 259.275, 43.1333),
  (93, 'NGC 2447', '', DeepSkyType.oc, 6.2, 116.15, -23.8667),
  (94, 'NGC 4736', 'Cat’s Eye Galaxy', DeepSkyType.s, 8.1, 192.725, 41.1167),
  (95, 'NGC 3351', '', DeepSkyType.s, 9.7, 161, 11.7),
  (96, 'NGC 3368', '', DeepSkyType.s, 9.2, 161.7, 11.8167),
  (97, 'NGC 3587', 'Owl Nebula', DeepSkyType.pn, 11.2, 168.7001, 55.0167),
  (98, 'NGC 4192', '', DeepSkyType.s, 10.1, 183.45, 14.9),
  (99, 'NGC 4254', '', DeepSkyType.s, 9.8, 184.7, 14.4167),
  (100, 'NGC 4321', '', DeepSkyType.s, 9.4, 185.7251, 15.8167),
  (101, 'NGC 5457', 'Pinwheel', DeepSkyType.s, 7.7, 210.8, 54.35),
  (102, 'NGC 5866', 'Spindle', DeepSkyType.s, 9.9, 226.6226, 55.76),
  (103, 'NGC 581', '', DeepSkyType.oc, 7.4, 23.3, 60.7),
  (104, 'NGC 4594', 'Sombrero', DeepSkyType.s, 8.3, 190, -11.6167),
  (105, 'NGC 3379', '', DeepSkyType.e, 9.3, 161.9501, 12.5833),
  (106, 'NGC 4258', '', DeepSkyType.s, 8.3, 184.7501, 47.3),
  (107, 'NGC 6171', '', DeepSkyType.gc, 8.1, 248.125, -13.05),
  (108, 'NGC 3556', '', DeepSkyType.s, 10, 167.8751, 55.6667),
  (109, 'NGC 3992', '', DeepSkyType.s, 9.8, 179.4, 53.3833),
  (110, 'NGC 205', '', DeepSkyType.e, 8, 10.1, 41.6833),
];

/// The catalogue as objects.
final List<DeepSkyObject> messierCatalogue = [
  for (final (number, designation, name, type, magnitude, ra, dec) in _messier)
    DeepSkyObject(
      messier: number,
      designation: designation,
      commonName: name,
      type: type,
      magnitude: magnitude,
      rightAscensionJ2000: ra,
      declinationJ2000: dec,
    ),
];
