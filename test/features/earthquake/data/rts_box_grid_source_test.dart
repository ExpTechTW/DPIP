/// The bundled box grid is what the monitor paints station boxes from. A
/// decode that swapped the ring axes, or dropped a polygon, would draw the
/// shaking in the wrong township.
library;

import 'package:dpip/features/earthquake/data/rts_box_grid_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled asset decodes into one ring per box id', () async {
    final grid = await const RtsBoxGridSource().load();
    expect(grid.rings, isNotEmpty);
    final ring = grid.rings.values.first;
    expect(ring, isNotEmpty);
    expect(ring.first, hasLength(2));
  });
}
