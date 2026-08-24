/// Rainfall accumulation colour scales (CWA banded ramp).
library;

import 'package:dpip/features/weather/domain/rain_interval.dart';

/// Which set of thresholds the rainfall ramp is read against.
///
/// The colours are identical in both; only the mm boundaries move. One hour of
/// rain and three days of rain differ by two orders of magnitude, so a single
/// table either flattens every short window to grey or saturates every long one
/// to pink. Two tables keep the same 17 bands legible at both ends.
enum RainColorScale {
  /// 1–300 mm. Short windows: a typhoon hour tops out near 100 mm.
  fine,

  /// 10–1500 mm. Multi-day totals: Morakot's 2009 maximum was ~2900 mm/3 d.
  coarse;

  /// The scale that suits [interval] when the user has not chosen one.
  ///
  /// The split is at 6 h: 3 h of rain reaching 300 mm is already a records-level
  /// event, while 6 h routinely passes it in a typhoon.
  static RainColorScale defaultFor(RainInterval interval) => switch (interval) {
    RainInterval.now ||
    RainInterval.min10 ||
    RainInterval.hour1 ||
    RainInterval.hour3 => RainColorScale.fine,
    RainInterval.hour6 ||
    RainInterval.hour12 ||
    RainInterval.hour24 ||
    RainInterval.day2 ||
    RainInterval.day3 => RainColorScale.coarse,
  };

  /// Ascending `(mm, hex)` band floors, lowest first.
  ///
  /// Read as **steps, not a gradient**: a value takes the colour of the last
  /// floor it is at or above, so 99 mm is the same red as 90 mm. That is what
  /// the CWA scale means — a band is a category, and interpolating across it
  /// invents readings the observation never made.
  ///
  /// The first entry is the below-threshold band (dry / trace), which is why
  /// there are 17 entries for 16 printed boundaries.
  List<(double, String)> get stops => switch (this) {
    RainColorScale.fine => const [
      (0, '#c2c2c2'),
      (1, '#a0fffa'),
      (2, '#00cdff'),
      (6, '#0096ff'),
      (10, '#0069ff'),
      (15, '#329600'),
      (20, '#32ff00'),
      (30, '#ffff00'),
      (40, '#ffc800'),
      (50, '#ff9600'),
      (70, '#ff0000'),
      (90, '#c80000'),
      (110, '#a00000'),
      (130, '#96009b'),
      (150, '#c800d2'),
      (200, '#ff00f0'),
      (300, '#ffc8ff'),
    ],
    RainColorScale.coarse => const [
      (0, '#c2c2c2'),
      (10, '#a0fffa'),
      (20, '#00cdff'),
      (60, '#0096ff'),
      (100, '#0069ff'),
      (150, '#329600'),
      (200, '#32ff00'),
      (300, '#ffff00'),
      (400, '#ffc800'),
      (500, '#ff9600'),
      (600, '#ff0000'),
      (700, '#c80000'),
      (800, '#a00000'),
      (900, '#96009b'),
      (1000, '#c800d2'),
      (1200, '#ff00f0'),
      (1500, '#ffc8ff'),
    ],
  };
}
