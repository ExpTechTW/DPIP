import 'dart:math' as math;

/// Central Weather Administration (CWA) seismic-intensity utilities.
///
/// Intensity is represented both as a continuous value and as the discrete
/// CWA 0–9 scale, where 5/6/7/8 correspond to 5⁻/5⁺/6⁻/6⁺ and 9 to 7.
abstract final class Intensity {
  /// Continuous intensity from peak ground acceleration [pga] (gal).
  static double fromPga(double pga) => 2 * (math.log(pga) / math.ln10) + 0.7;

  /// Discrete CWA intensity (0–9) from a continuous intensity [value].
  static int toScale(double value) {
    if (value < 0.5) return 0;
    if (value < 1.5) return 1;
    if (value < 2.5) return 2;
    if (value < 3.5) return 3;
    if (value < 4.5) return 4;
    if (value < 5.0) return 5; // 5弱
    if (value < 5.5) return 6; // 5強
    if (value < 6.0) return 7; // 6弱
    if (value < 6.5) return 8; // 6強
    return 9; // 7
  }

  /// Discrete CWA intensity (0–9) directly from [pga] (gal).
  static int scaleFromPga(double pga) => toScale(fromPga(pga));

  /// Human-readable label for a discrete CWA [level] (0–9).
  static String label(int level) => switch (level) {
    5 => '5⁻',
    6 => '5⁺',
    7 => '6⁻',
    8 => '6⁺',
    9 => '7',
    _ => '$level',
  };
}
