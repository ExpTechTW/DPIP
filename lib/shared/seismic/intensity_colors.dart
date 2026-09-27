/// The two seismic-intensity colour scales, as a single source of truth so the
/// map's station dots and the legend can never drift apart. The discrete one is
/// CWA's published scale, ported verbatim from the legacy palette.
///
///  - [InstrumentalIntensityColors] — the **continuous** instrumental intensity
///    `i` shown by the real-time monitor's station dots: rts-image-go's
///    101-step blue → green → yellow → red table, as TREM-Lite draws it.
///  - [IntensityColors] — the **discrete** felt-intensity scale (震度 0 → 7, with
///    5 and 6 split into 弱/強, indexed 0 → 9) used by 震度 reports and EEW.
///
/// The literals below are the *standard-vision* palettes; each one is routed
/// through the colour-vision transform, so the whole scale is recoloured when a
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

/// The real-time monitor's station dots, coloured by the continuous
/// instrumental intensity `i` — rts-image-go's station table, the colours
/// TREM-Lite draws, so the two monitors show the same reading the same way.
///
/// Two steps, as there:
///  1. `i` moves onto the table's own scale, −3 → 7 with green at 0: every
///     `i ≤ 0` is the darkest blue, `0 < i ≤ 1` runs blue → green, and above 1
///     green (at 1) runs to dark red (at 7).
///  2. That value is looked up in 0.1 steps, rounded half away from zero (Go's
///     `math.Round`, and MapLibre's `round`), clamped to the table's ends.
abstract final class InstrumentalIntensityColors {
  /// The colour for reading [i], corrected for the current colour-vision
  /// setting — the same one [mapLibreExpression] paints a dot with.
  static Color of(double i) => _corrected[_index(i)];

  /// Where [i] lands on the table's −3 → 7 scale (step 1 above).
  static double tableScale(double i) {
    if (i <= 0) return -3;
    if (i <= 1) return -3 + 3 * i;
    return 7 * (i - 1) / 6;
  }

  static int _index(double i) =>
      ((tableScale(i) * 10).round() + _offset).clamp(0, _table.length - 1);

  /// Table index of the scale's −3.0 — `round(scale × 10) + 30`.
  static const int _offset = 30;

  /// A MapLibre expression colouring a feature by its numeric `i` property
  /// exactly as [of] does: the same scale in the expression language, then a
  /// `step` over integer tenths so every stop compares exactly.
  ///
  /// The hex is written from the already-corrected table — `toHexRgb` stays a
  /// pure converter, so the expression carries exactly one transform.
  static List<Object> get mapLibreExpression {
    const i = ['get', 'i'];
    final colors = _corrected;
    return [
      'step',
      [
        'round',
        [
          '*',
          [
            'case',
            ['<=', i, 0],
            -3,
            ['<=', i, 1],
            [
              '+',
              -3,
              ['*', 3, i],
            ],
            [
              '/',
              [
                '*',
                7,
                ['-', i, 1],
              ],
              6,
            ],
          ],
          10,
        ],
      ],
      colors.first.toHexRgb(),
      for (var n = 1; n < colors.length; n++) ...[
        n - _offset,
        colors[n].toHexRgb(),
      ],
    ];
  }

  /// rts-image-go's `resource/color.json`: one colour per 0.1 of the table's
  /// scale, −3.0 → 7.0.
  static const List<Color> _table = [
    Color(0xFF0000CD),
    Color(0xFF0007D1),
    Color(0xFF000ED6),
    Color(0xFF0015DA),
    Color(0xFF001CDF),
    Color(0xFF0024E3),
    Color(0xFF002BE7),
    Color(0xFF0032EC),
    Color(0xFF0039F0),
    Color(0xFF0040F5),
    Color(0xFF0048FA),
    Color(0xFF0055EE),
    Color(0xFF0063E3),
    Color(0xFF0070D8),
    Color(0xFF007ECD),
    Color(0xFF008CC2),
    Color(0xFF0099B7),
    Color(0xFF00A7AC),
    Color(0xFF00B4A1),
    Color(0xFF00C296),
    Color(0xFF00D08B),
    Color(0xFF06D482),
    Color(0xFF0CD879),
    Color(0xFF12DC71),
    Color(0xFF19E068),
    Color(0xFF1FE460),
    Color(0xFF25E958),
    Color(0xFF2CED4F),
    Color(0xFF32F147),
    Color(0xFF38F53E),
    Color(0xFF3FFA36),
    Color(0xFF4BFA31),
    Color(0xFF58FA2D),
    Color(0xFF64FB29),
    Color(0xFF71FB25),
    Color(0xFF7DFC21),
    Color(0xFF8AFC1C),
    Color(0xFF97FD18),
    Color(0xFFA3FD14),
    Color(0xFFB0FE10),
    Color(0xFFBDFF0C),
    Color(0xFFC3FE0A),
    Color(0xFFCAFE09),
    Color(0xFFD0FE08),
    Color(0xFFD7FE07),
    Color(0xFFDEFF05),
    Color(0xFFE4FE04),
    Color(0xFFEBFF03),
    Color(0xFFF1FE02),
    Color(0xFFF8FF01),
    Color(0xFFFFFF00),
    Color(0xFFFEFB00),
    Color(0xFFFEF800),
    Color(0xFFFEF400),
    Color(0xFFFEF100),
    Color(0xFFFFEE00),
    Color(0xFFFEEA00),
    Color(0xFFFFE700),
    Color(0xFFFEE300),
    Color(0xFFFFE000),
    Color(0xFFFFDD00),
    Color(0xFFFED500),
    Color(0xFFFECD00),
    Color(0xFFFEC500),
    Color(0xFFFEBE00),
    Color(0xFFFFB600),
    Color(0xFFFEAE00),
    Color(0xFFFFA700),
    Color(0xFFFE9F00),
    Color(0xFFFF9700),
    Color(0xFFFF9000),
    Color(0xFFFE8800),
    Color(0xFFFE8000),
    Color(0xFFFE7900),
    Color(0xFFFE7100),
    Color(0xFFFF6A00),
    Color(0xFFFE6200),
    Color(0xFFFF5A00),
    Color(0xFFFE5300),
    Color(0xFFFF4B00),
    Color(0xFFFF4400),
    Color(0xFFFE3D00),
    Color(0xFFFD3600),
    Color(0xFFFC2F00),
    Color(0xFFFB2800),
    Color(0xFFFA2100),
    Color(0xFFF91B00),
    Color(0xFFF81400),
    Color(0xFFF70D00),
    Color(0xFFF60600),
    Color(0xFFF50000),
    Color(0xFFEE0000),
    Color(0xFFE60000),
    Color(0xFFDF0000),
    Color(0xFFD70000),
    Color(0xFFD00000),
    Color(0xFFC80000),
    Color(0xFFC00000),
    Color(0xFFB90000),
    Color(0xFFB10000),
    Color(0xFFAA0000),
  ];

  /// [_table] under the current setting, rebuilt only when that setting
  /// moves — [of] runs per station, per frame.
  static List<Color>? _cache;
  static ColorVision? _cachedFor;

  static List<Color> get _corrected {
    final vision = AppColorVision.current;
    if (_cachedFor != vision || _cache == null) {
      _cachedFor = vision;
      _cache = [
        for (final color in _table) ColorVisionFilter.transform(color, vision),
      ];
    }
    return _cache!;
  }
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

  /// The readable ink colour for text/icons drawn directly on [discrete]'s
  /// [level] fill — white on the scale's darker/more saturated stops, near-
  /// black on the pale yellow ones (4, 5⁻); the same contrast rule
  /// [IntensityBadge] already applies to its own label, generalised here so a
  /// second caller (an [EewEstimateTile] background) doesn't have to guess.
  static Color onDiscrete(int level) =>
      ThemeData.estimateBrightnessForColor(discrete(level)) == Brightness.dark
      ? Colors.white
      : Colors.black87;

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
