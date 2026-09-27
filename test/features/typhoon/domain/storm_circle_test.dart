/// A wind-radius circle, one value per quadrant plus the average. All five
/// fields are required doubles with no wire-key renames, but the four
/// quadrants (`ne`/`se`/`sw`/`nw`) are easy to transpose when hand-typing a
/// fixture or a decoder — asymmetric values in every quadrant catch a swap
/// that four equal corners never would.
library;

import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson reads each quadrant distinctly, toJson restores them', () {
    final json = <String, dynamic>{
      'avg': 180.0,
      'ne': 220.0,
      'se': 200.0,
      'sw': 150.0,
      'nw': 160.0,
    };

    final circle = StormCircle.fromJson(json);

    expect(circle.avg, 180.0);
    expect(circle.ne, 220.0);
    expect(circle.se, 200.0);
    expect(circle.sw, 150.0);
    expect(circle.nw, 160.0);
    expect(circle.toJson(), json);
  });
}
