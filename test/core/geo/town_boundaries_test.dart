import 'package:dpip/core/geo/town_boundaries.dart';
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
  });
}
