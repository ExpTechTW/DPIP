/// The sheet, the region bar, and the bottom nav all read these same
/// thresholds. A ramp that starts early, or a nav that is still on screen
/// after the sheet has committed, puts chrome on top of the weather.
library;

import 'package:dpip/features/home/presentation/home_chrome.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weather stays hidden until the sheet is nearly full', () {
    expect(HomeChrome.weatherReveal(0.85), 0);
    expect(HomeChrome.weatherActive(0.85), isFalse);
    expect(HomeChrome.weatherReveal(0.925), closeTo(0.5, 0.001));
    expect(HomeChrome.weatherReveal(1), 1);
    expect(HomeChrome.weatherActive(0.86), isTrue);
    expect(HomeChrome.regionBlend(1), 1);
  });

  test(
    'the nav clears before the region bar, and the map dims only up to the sky',
    () {
      expect(HomeChrome.navDismiss(0.7), 0);
      expect(HomeChrome.navDismiss(0.8), closeTo(0.5, 0.001));
      expect(HomeChrome.navDismiss(1), 1);
      expect(HomeChrome.navDismiss(0), 0);
      expect(HomeChrome.mapDim(HomeSheetExtent.rest), 0);
      expect(HomeChrome.mapDim(0.85), 1);
      expect(HomeChrome.mapDim(1), 1);
      expect(HomeChrome.regionDismiss(0.93), 0);
      expect(HomeChrome.regionDismiss(0.965), closeTo(0.5, 0.001));
      expect(HomeChrome.regionDismiss(1), 1);
    },
  );
}
