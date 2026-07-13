import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeds to the rest detent so the panel is styled from frame one', () {
    // A DraggableScrollableSheet emits no notification until its size changes,
    // so the notifier must already read `rest` (not 0) at construction.
    expect(HomeSheetExtent().value, HomeSheetExtent.rest);
  });

  test('rest is the floor, below the full detent', () {
    expect(HomeSheetExtent.rest, greaterThan(0));
    expect(HomeSheetExtent.rest, lessThan(HomeSheetExtent.max));
  });
}
