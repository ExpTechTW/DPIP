import 'package:dpip/core/settings/home_sheet_extent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeds to the rest detent so the panel is styled from frame one', () {
    // A DraggableScrollableSheet emits no notification until its size changes,
    // so the notifier must already read `rest` (not 0) at construction.
    expect(HomeSheetExtent().value, HomeSheetExtent.rest);
  });

  test('detents are ordered min < rest < max', () {
    expect(HomeSheetExtent.min, lessThan(HomeSheetExtent.rest));
    expect(HomeSheetExtent.rest, lessThan(HomeSheetExtent.max));
  });
}
