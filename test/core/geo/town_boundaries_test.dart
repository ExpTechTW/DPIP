import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:flutter_test/flutter_test.dart';

/// A few adjacent synthetic townships (Taiwan-scale coords) exercising the
/// algorithm: two neighbours, one with a hole, one multi-part.
TownBoundaries _synthetic() => TownBoundaries.fromDecoded({
  // A: square 120.0–120.1 × 24.0–24.1
  'A': {
    'b': [120.0, 24.0, 120.1, 24.1],
    'p': [
      [
        [120.0, 24.0, 120.1, 24.0, 120.1, 24.1, 120.0, 24.1, 120.0, 24.0],
      ],
    ],
  },
  // B: square 120.1–120.2 × 24.0–24.1 (shares A's edge)
  'B': {
    'b': [120.1, 24.0, 120.2, 24.1],
    'p': [
      [
        [120.1, 24.0, 120.2, 24.0, 120.2, 24.1, 120.1, 24.1, 120.1, 24.0],
      ],
    ],
  },
  // H: square 120.0–120.1 × 24.2–24.3 with a hole 120.03–120.07 × 24.23–24.27
  'H': {
    'b': [120.0, 24.2, 120.1, 24.3],
    'p': [
      [
        [120.0, 24.2, 120.1, 24.2, 120.1, 24.3, 120.0, 24.3, 120.0, 24.2],
        [
          120.03, 24.23, 120.07, 24.23, 120.07, 24.27, 120.03, 24.27, //
          120.03, 24.23,
        ],
      ],
    ],
  },
  // M: two disjoint squares (one township, multi-part)
  'M': {
    'b': [120.2, 24.2, 120.27, 24.22],
    'p': [
      [
        [120.2, 24.2, 120.22, 24.2, 120.22, 24.22, 120.2, 24.22, 120.2, 24.2],
      ],
      [
        [
          120.25, 24.2, 120.27, 24.2, 120.27, 24.22, 120.25, 24.22, //
          120.25, 24.2,
        ],
      ],
    ],
  },
});

void main() {
  group('TownBoundaries.codeAt (synthetic)', () {
    final b = _synthetic();

    test('resolves a point to its containing township', () {
      expect(b.codeAt(24.05, 120.05), 'A');
      expect(b.codeAt(24.05, 120.15), 'B'); // asymmetric → catches lat/lng swap
    });

    test('a point inside a hole is not in the township', () {
      expect(b.codeAt(24.21, 120.01), 'H'); // inside H, outside the hole
      expect(b.codeAt(24.25, 120.05), isNull); // inside the hole
    });

    test('a multi-part township matches either part', () {
      expect(b.codeAt(24.21, 120.21), 'M');
      expect(b.codeAt(24.21, 120.26), 'M');
    });

    test('a point outside every township is null', () {
      expect(b.codeAt(24.5, 120.5), isNull);
      expect(b.codeAt(24.15, 120.05), isNull); // between A/B row and H row
    });
  });

  group('TownBoundaries.codeNearCoast (synthetic)', () {
    final b = _synthetic();

    test('a fix just off the coast belongs to the township it is beside', () {
      // ~1.1 km south of A's edge — the fix of a phone at the water's edge.
      expect(b.codeNearCoast(23.99, 120.05, 5), 'A');
      // The same for a point 1 km east of B's edge.
      expect(b.codeNearCoast(24.05, 120.21, 5), 'B');
    });

    test('a point farther than the limit from any coast is null', () {
      // ~6.7 km south of A: on the water, but not beside anything.
      expect(b.codeNearCoast(23.94, 120.05, 5), isNull);
      // Between the A/B row and the H row: 5.6 km from both.
      expect(b.codeNearCoast(24.15, 120.05, 5), isNull);
    });

    test('the nearest coast wins, not the first one scanned', () {
      // 1.0° west of A is 4° from everything else — but 1.0° is 111 km, so this
      // only proves the limit is applied to the winner.
      expect(b.codeNearCoast(24.05, 119.10, 5), isNull);
    });
  });

  group('TownBoundaries.load (real asset — golden)', () {
    late TownBoundaries boundaries;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      boundaries = await TownBoundaries.load();
    });

    test('resolves well-known coordinates to the correct township code', () {
      expect(boundaries.codeAt(25.0330, 121.5645), '110'); // 臺北101 → 信義區
      expect(boundaries.codeAt(24.1616, 120.6478), '407'); // 臺中市政府 → 西屯區
      expect(boundaries.codeAt(22.6210, 120.3120), '802'); // 高雄市政府 → 苓雅區
      expect(boundaries.codeAt(24.1000, 121.6000), '972'); // 花蓮 → 秀林鄉
    });

    test('a point at sea resolves to null (caller falls back)', () {
      expect(boundaries.codeAt(24.0, 120.0), isNull); // Taiwan Strait
    });

    test('a fix on the water keeps the coast it is beside', () {
      // Keelung's harbour mouth, ~0.5 km off the quay.
      expect(boundaries.codeNearCoast(25.1530, 121.7440, 5), '203');
      // Kaohsiung, 1.4 km offshore of the port.
      expect(boundaries.codeNearCoast(22.6000, 120.2500, 5), '805');
      // The same water 5.1 km out: past the limit, so no township at all.
      expect(boundaries.codeNearCoast(22.6000, 120.2100, 5), isNull);
    });

    test('every township resolves from a point inside it', () async {
      // The coast limit must not strand any township — the small islands are
      // the ones it could: 烏坵's islets, 彭佳嶼 (part of 基隆中正區), 小蘭嶼,
      // 東沙. One interior point per township through the real service path is
      // enough to catch a limit that has been widened or narrowed into them.
      final directory = await TownDirectory.load();
      final service = LocationService(
        directory,
        boundaries: Future.value(boundaries),
        isAvailable: () async => true,
      );
      final unreachable = <String>[];
      for (final town in directory.all) {
        final box = boundaries.boundsFor(town.code);
        if (box == null) {
          unreachable.add('${town.code} 沒有邊界資料');
          continue;
        }
        String? got;
        outer:
        for (var lat = box[1]; lat <= box[3]; lat += 0.004) {
          for (var lng = box[0]; lng <= box[2]; lng += 0.004) {
            if (boundaries.codeAt(lat, lng) != town.code) continue;
            got = (await service.townAt(lat, lng))?.code;
            break outer;
          }
        }
        if (got != town.code) unreachable.add('${town.code} → $got');
      }
      expect(unreachable, isEmpty);
    });

    test('the reported Xiamen coordinate is not near a Taiwanese coast', () {
      // 24.449350, 118.077110 — Siming, Xiamen. Before this rule it resolved to
      // 金門縣 烈嶼鄉 by nearest centroid, 17 km away, and its weather card named
      // Lieyu's station. By the boundary data it is 10 km from the nearest
      // Taiwanese coastline, so no township is named.
      expect(boundaries.codeAt(24.449350, 118.077110), isNull);
      expect(boundaries.codeNearCoast(24.449350, 118.077110, 5), isNull);
      // The rest of the Fujian coast across from Kinmen and Matsu, same answer.
      expect(boundaries.codeNearCoast(24.570, 118.330, 5), isNull); // Xiang'an
      expect(boundaries.codeNearCoast(26.0745, 119.2965, 5), isNull); // Fuzhou
    });
  });
}
