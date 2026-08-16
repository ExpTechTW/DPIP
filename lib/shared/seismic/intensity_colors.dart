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
///
/// The literals below are the *standard-vision* CWA palette; each one is routed
/// through `.vision` at its definition, so the whole scale is recoloured when a
/// colour-vision correction is on. The user has accepted that these then stop
/// matching CWA's published colours — a scale whose steps collapse into one
/// another is worse than one that is off-spec. The transform sits **here**, at
/// the single source of truth, and never in `colorFromHexRgb` / `toHexRgb`:
/// that is what keeps the map's station dots and the legend in agreement, since
/// both draw from these stops and a colour that crosses the hex boundary is
/// still transformed exactly once. Because the transform is not a compile-time
/// constant, the tables are getters rather than `static const`.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:flutter/material.dart';

/// Continuous instrumental-intensity colours, one stop per integer `i` in
/// −3 → 7 (ascending).
abstract final class InstrumentalIntensityColors {
  /// The colour stops, ascending from `i = -3` to `i = 7`, corrected for the
  /// current colour-vision setting.
  static List<(int level, Color color)> get stops => [
    (-3, const Color(0xFF0005D0).vision),
    (-2, const Color(0xFF004BF8).vision),
    (-1, const Color(0xFF009EF8).vision),
    (0, const Color(0xFF79E5FD).vision),
    (1, const Color(0xFF49E9AD).vision),
    (2, const Color(0xFF44FA34).vision),
    (3, const Color(0xFFBEFF0C).vision),
    (4, const Color(0xFFFFF000).vision),
    (5, const Color(0xFFFF9300).vision),
    (6, const Color(0xFFFC5235).vision),
    (7, const Color(0xFFB720E9).vision),
  ];

  /// The stop colours only, ascending `i = -3 → 7` — e.g. a legend gradient.
  static List<Color> get ramp => [for (final (_, color) in stops) color];

  /// A MapLibre `interpolate` expression colouring a feature by its numeric `i`
  /// property across [stops], so the dots draw from the same definition as the
  /// legend. Linear between stops; clamps to the end colours outside −3 → 7.
  ///
  /// The hex is written from an already-corrected [stops] colour — `toHexRgb`
  /// stays a pure converter, so the expression carries exactly one transform.
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
  /// The colour for scale index [level] (0 → 9), corrected for the current
  /// colour-vision setting; out-of-range clamps to the ends.
  static Color discrete(int level) => _corrected[level.clamp(0, 9)];

  /// The published CWA colour for [level] (0 → 9), **untransformed**.
  ///
  /// For a colour-vision *picker* only, which has to paint each option under
  /// *its own* setting: [discrete] has already applied the one currently in
  /// force, and correcting that again daltonises an already-daltonised colour —
  /// so the swatches drift as soon as any setting but "standard" is on. Never
  /// render with this anywhere else; everything the app draws comes from
  /// [discrete].
  static Color published(int level) => _base[level.clamp(0, 9)];

  /// The published CWA scale, untransformed. The one source of these values.
  static const List<Color> _base = [
    Color(0xFF9E9E9E), // 0 — grey
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

  /// [_base] under the current setting, rebuilt only when that setting moves.
  ///
  /// [discrete] is called per station dot, per legend swatch and per badge —
  /// thousands of times while an RTS frame lands. Transforming the whole table
  /// on every call, which a plain getter did, put ten sRGB→linear→matrix→sRGB
  /// conversions and a fresh list behind every one of those reads.
  static List<Color>? _cache;
  static ColorVision? _cachedFor;

  static List<Color> get _corrected {
    final vision = AppColorVision.current;
    if (_cachedFor != vision || _cache == null) {
      _cachedFor = vision;
      _cache = [
        for (final color in _base) ColorVisionFilter.transform(color, vision),
      ];
    }
    return _cache!;
  }
}
