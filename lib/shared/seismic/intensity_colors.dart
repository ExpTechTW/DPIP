/// The two Central Weather Administration seismic-intensity colour scales, as a
/// single source of truth so the map's station dots and the legend can never
/// drift apart. Ported verbatim (same hex values) from the legacy palette.
///
///  - [InstrumentalIntensityColors] — the **continuous** instrumental intensity
///    `i` (−3 → 7) shown by the real-time monitor's station dots: a blue → cyan
///    → green → yellow → orange → red → purple ramp. Fractional values
///    interpolate between the integer stops on the map.
///  - [IntensityColors] — the **discrete** felt-intensity scale (震度 0 → 7, with
///    5 and 6 split into 弱/強, indexed 0 → 9) used by 震度 reports and EEW.
library;

import 'package:dpip/shared/color_hex.dart';
import 'package:flutter/material.dart';

/// Continuous instrumental-intensity colours, one stop per integer `i` in
/// −3 → 7 (ascending).
abstract final class InstrumentalIntensityColors {
  /// The colour stops, ascending from `i = -3` to `i = 7`.
  static const List<(int level, Color color)> stops = [
    (-3, Color(0xFF0005D0)),
    (-2, Color(0xFF004BF8)),
    (-1, Color(0xFF009EF8)),
    (0, Color(0xFF79E5FD)),
    (1, Color(0xFF49E9AD)),
    (2, Color(0xFF44FA34)),
    (3, Color(0xFFBEFF0C)),
    (4, Color(0xFFFFF000)),
    (5, Color(0xFFFF9300)),
    (6, Color(0xFFFC5235)),
    (7, Color(0xFFB720E9)),
  ];

  /// The stop colours only, ascending `i = -3 → 7` — e.g. a legend gradient.
  static List<Color> get ramp => [for (final (_, color) in stops) color];

  /// A MapLibre `interpolate` expression colouring a feature by its numeric `i`
  /// property across [stops], so the dots draw from the same definition as the
  /// legend. Linear between stops; clamps to the end colours outside −3 → 7.
  static List<Object> get mapLibreInterpolate => [
    'interpolate',
    const ['linear'],
    const ['get', 'i'],
    for (final (level, color) in stops) ...[level, color.toHexRgb()],
  ];
}

/// Discrete felt-intensity colours, keyed by the scale index 0 → 9 (0 grey, then
/// 1, 2, 3, 4, 5⁻, 5⁺, 6⁻, 6⁺, 7).
///
/// For **pre-2020 舊制** report intensities (wire 5/6/9 = 5級/6級/7級; no 7/8),
/// resolve label + colour index via `Intensity.displayForReport` first — do not
/// pass the raw wire value here or 5/6 will be coloured as 5⁻/5⁺.
abstract final class IntensityColors {
  /// The colour for scale index [level] (0 → 9); out-of-range clamps to the ends.
  static Color discrete(int level) => _colors[level.clamp(0, 9)];

  static const List<Color> _colors = [
    Colors.grey, // 0
    Color(0xFF003264), // 1
    Color(0xFF0064C8), // 2
    Color(0xFF1E9632), // 3
    Color(0xFFFFC800), // 4
    Color(0xFFFF9600), // 5⁻
    Color(0xFFFF6400), // 5⁺
    Color(0xFFFF0000), // 6⁻
    Color(0xFFC00000), // 6⁺
    Color(0xFF9600C8), // 7
  ];
}
