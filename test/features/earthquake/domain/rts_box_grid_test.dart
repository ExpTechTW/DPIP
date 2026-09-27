/// The bundled RTS intensity-box polygons, keyed by the integer box id that
/// the live RTS feed also uses (`Rts.box`'s keys) — two independently sourced
/// ids that must agree for a box's shaking colour to land on the right
/// polygon. [RtsBoxGrid] itself has no decode step to get wrong; the risk is
/// entirely in the lookup. Both call sites (`rts_layer.dart`,
/// `report_replay_page.dart`) do `grid.rings[id]` and treat a miss as "draw
/// nothing" — so a `Map` lookup miss degrading to `null` rather than throwing
/// is exactly the behaviour the rest of the app is built on.
library;

import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rings exposes exactly the polygons it was constructed with', () {
    final ring = [
      [121.5, 25.0],
      [121.6, 25.0],
      [121.6, 25.1],
    ];
    final grid = RtsBoxGrid({1001: ring});

    expect(grid.rings[1001], ring);
  });

  test('a box id with no polygon reads as null, not an empty ring', () {
    final grid = RtsBoxGrid({
      1001: [
        [121.5, 25.0],
      ],
    });

    expect(grid.rings[9999], isNull);
  });
}
