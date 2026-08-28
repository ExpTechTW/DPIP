/// The baked label points must actually be in the township they name.
///
/// A label placed outside its own polygon is worse than an off-centre one: it
/// names a different place. That was true of two of the directory points the
/// map used before this table existed (新竹市香山區 drew inside 北區,
/// 屏東縣瑪家鄉 inside 內埔鄉), which is easy to reintroduce by regenerating
/// against changed boundary data without looking.
library;

import 'dart:math' as math;

import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/town_label_points.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flat-earth metres — exact enough at a township's scale.
double _distance(double aLat, double aLng, double bLat, double bLng) {
  final k = 111320.0 * math.cos(aLat * math.pi / 180);
  final dx = (aLng - bLng) * k;
  final dy = (aLat - bLat) * 111320.0;
  return math.sqrt(dx * dx + dy * dy);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every baked label point lies inside the township it names', () async {
    final boundaries = await TownBoundaries.load();
    final wrong = <String>[];
    townLabelPoints.forEach((code, point) {
      final at = boundaries.codeAt(point.$1, point.$2);
      if (at != code) wrong.add('$code -> ${at ?? "outside every township"}');
    });
    expect(wrong, isEmpty, reason: 'labels naming the wrong place');
  });

  /// A township can only get a baked point if it has a polygon to place it in,
  /// so the table is allowed to be short by exactly the townships the boundary
  /// data does not carry — and by nothing else. A wider gap means someone
  /// regenerated against stale boundaries.
  ///
  /// Today the boundary data carries all 368, so the gap is empty.
  ///
  /// It was not always: 新竹市香山區 used to have no polygon at all, because the
  /// upstream township source gave it 北區's code (300) instead of its own (309)
  /// and the by-code keying merged the two. `TownBoundaries.codeAt` therefore
  /// answered 北區 for a GPS fix anywhere in 香山, misrouting township-level
  /// alert targeting for everyone there. The boundaries were split back apart
  /// against the high-resolution source; if this gap ever reopens, suspect the
  /// same class of collision rather than the label table.
  test(
    'the table covers every township that has a boundary to place in',
    () async {
      final directory = await TownDirectory.load();
      final boundaries = await TownBoundaries.load();
      final missing = [
        for (final town in directory.all)
          if (!townLabelPoints.containsKey(town.code))
            '${town.cityName}${town.townName} (${town.code})',
      ];
      final withoutBoundary = [
        for (final town in directory.all)
          if (boundaries.boundsFor(town.code) == null)
            '${town.cityName}${town.townName} (${town.code})',
      ];
      expect(missing, equals(withoutBoundary));
      expect(
        withoutBoundary,
        isEmpty,
        reason: 'a new gap here is a boundary-data regression, not a label one',
      );
    },
  );

  /// The townships where "which polygon is the real one" actually bites.
  ///
  /// 23 townships are made of more than one polygon, and several of the extra
  /// ones are crude marine administrative areas rather than land — 雲林縣口湖鄉
  /// carries a 9-vertex box over ~270 km² of the Taiwan Strait, roomier than
  /// its actual land. Placing the label in the polygon with the most room put
  /// it out at sea, and the inside-its-own-township test above still passed,
  /// because the sea box genuinely belongs to 口湖. The generator now prefers
  /// the polygon holding the administrative seat.
  ///
  /// The rule lives in the tool and the boundary source it reads is not
  /// bundled, so it cannot be re-derived here. These three pin the outcome
  /// instead: each is a small coastal township whose label can only be a few km
  /// from its seat, and each has an outlying polygon far enough away (the
  /// strait, 南沙群島, 龜山島) that a regression could not stay under the bound.
  test('a multi-polygon township labels on its main body', () async {
    final directory = await TownDirectory.load();
    for (final code in ['653', '805', '261']) {
      final town = directory.byCode(code)!;
      final point = townLabelPoints[code]!;
      final metres = _distance(town.lat, town.lng, point.$1, point.$2);
      expect(
        metres,
        lessThan(6000),
        reason:
            '${town.cityName}${town.townName} labels ${metres.round()} m '
            'from its seat — it has left the main body',
      );
    }
  });

  test('the label GeoJSON places one point per township, and caches', () async {
    final directory = await TownDirectory.load();
    final first = townLabelGeoJson(directory);
    expect(
      RegExp('"type":"Feature"').allMatches(first).length,
      directory.all.length,
    );
    expect(
      identical(townLabelGeoJson(directory), first),
      isTrue,
      reason: 'rebuilding 41 KB per BaseMap build is what the cache prevents',
    );
  });
}
