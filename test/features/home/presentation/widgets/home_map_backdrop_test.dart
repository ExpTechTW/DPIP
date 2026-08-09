import 'package:dpip/features/home/presentation/widgets/home_map_backdrop.dart';
import 'package:dpip/shared/map/admin_outline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the nationwide view draws the county frame only', () {
    // Framed on the whole island, 368 township outlines collapse into a grey
    // wash over the echo — the coarse frame is the only boundary that still
    // says anything at that zoom.
    expect(backdropBoundaries(null), [AdminBoundary.county]);
  });

  test('a township draws both, county last so it stacks on top', () {
    final boundaries = backdropBoundaries('100');
    expect(boundaries, [AdminBoundary.town, AdminBoundary.county]);
    // Order is the stacking order: the coarse frame should win where the two
    // run together along a coastline.
    expect(boundaries.last, AdminBoundary.county);
  });

  test('the county frame is never dropped', () {
    for (final code in [null, '100', '200']) {
      expect(
        backdropBoundaries(code),
        contains(AdminBoundary.county),
        reason: 'code $code',
      );
    }
  });
}
