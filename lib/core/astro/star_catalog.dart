/// The naked-eye sky: 5,044 stars to magnitude 6, and the constellation
/// figures that join them.
///
/// Bundled, not fetched. A star chart that needs the network is useless on the
/// night you are out of range, which for this app is the whole point. Packed
/// binary rather than JSON: 25 KB and 3.6 KB gzipped, against 657 KB of JSON,
/// and it parses with no allocation per star.
///
/// The packing is chosen against what the eye can resolve, not against what a
/// double can hold. Right ascension gets 16 bits over 360° (20″), declination
/// 16 bits over ±90° (10″), magnitude 8 bits over −2…8 (0.04 mag). At any
/// zoom a phone screen offers, those quantisations are far below one pixel.
///
/// Positions are J2000 and are precessed on use, like the rest of `astro/`.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One catalogue star. J2000 degrees.
class CatalogStar {
  const CatalogStar({
    required this.rightAscension,
    required this.declination,
    required this.magnitude,
  });

  final double rightAscension;
  final double declination;
  final double magnitude;
}

/// A constellation figure — one stroke of the join-the-dots.
class ConstellationLine {
  const ConstellationLine(this.points);

  /// J2000 `(RA, Dec)` in degrees, in stroke order.
  final List<(double, double)> points;
}

/// The bundled sky.
class StarCatalog {
  const StarCatalog({required this.stars, required this.figures});

  final List<CatalogStar> stars;
  final List<ConstellationLine> figures;

  /// Decodes both assets off the UI isolate — 5,000 stars is fast, but it is
  /// still work that has no business on the frame thread.
  static Future<StarCatalog> load() async {
    final starBytes = await rootBundle.load('assets/astro/stars.bin.gz');
    final lineBytes = await rootBundle.load(
      'assets/astro/constellations.bin.gz',
    );
    final decoded = await Isolate.run(
      () => _decode(
        starBytes.buffer.asUint8List(),
        lineBytes.buffer.asUint8List(),
      ),
    );
    return decoded;
  }

  static StarCatalog _decode(Uint8List starGz, Uint8List lineGz) {
    final starData = ByteData.sublistView(
      Uint8List.fromList(gzip.decode(starGz)),
    );
    final count = starData.getUint32(0, Endian.little);
    final stars = <CatalogStar>[];
    for (var i = 0; i < count; i++) {
      final offset = 4 + i * 5;
      stars.add(
        CatalogStar(
          rightAscension:
              starData.getUint16(offset, Endian.little) / 65535 * 360,
          declination: starData.getInt16(offset + 2, Endian.little) / 32767 * 90,
          magnitude: starData.getUint8(offset + 4) / 25 - 2.0,
        ),
      );
    }

    final lineData = ByteData.sublistView(
      Uint8List.fromList(gzip.decode(lineGz)),
    );
    final segments = lineData.getUint32(0, Endian.little);
    final figures = <ConstellationLine>[];
    var cursor = 4;
    for (var i = 0; i < segments; i++) {
      final length = lineData.getUint16(cursor, Endian.little);
      cursor += 2;
      final points = <(double, double)>[];
      for (var j = 0; j < length; j++) {
        points.add((
          lineData.getUint16(cursor, Endian.little) / 65535 * 360,
          lineData.getInt16(cursor + 2, Endian.little) / 32767 * 90,
        ));
        cursor += 4;
      }
      figures.add(ConstellationLine(points));
    }
    return StarCatalog(stars: stars, figures: figures);
  }

  /// A J2000 position precessed to the equinox of date.
  static Equatorial precess(double ra, double dec, DateTime utc) {
    final years = julianCenturies(utc) * 100;
    final a = ra * degrees;
    final d = dec * degrees;
    return Equatorial(
      rightAscension: turn(
        a +
            (3.07496 + 1.33621 * math.sin(a) * math.tan(d)) *
                years *
                15 /
                3600 *
                degrees,
      ),
      declination: d + 20.0431 * math.cos(a) * years / 3600 * degrees,
    );
  }
}
