import 'dart:math' as math;

/// Central Weather Administration (CWA) seismic-intensity utilities.
///
/// Intensity is represented both as a continuous value and as the discrete
/// CWA 0–9 scale, where 5/6/7/8 correspond to 5⁻/5⁺/6⁻/6⁺ and 9 to 7.
///
/// **Scale change:** from 2020-01-01 00:00 Taipei (新制) the felt scale splits
/// 5/6 into 弱/強. Events before that instant use the **舊制** 0–7 ladder —
/// see [displayForReport].
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

  /// Human-readable label for a discrete **新制** CWA [level] (0–9).
  static String label(int level) => switch (level) {
    5 => '5⁻',
    6 => '5⁺',
    7 => '6⁻',
    8 => '6⁺',
    9 => '7',
    _ => '$level',
  };

  /// Instant the CWA 新制 (5⁻/5⁺/6⁻/6⁺/7) took effect: 2020-01-01 00:00
  /// Taipei (= 2019-12-31 16:00 UTC). Events strictly before this use 舊制.
  static final DateTime newScaleSinceUtc = DateTime.utc(2019, 12, 31, 16);

  /// Whether [originTimeUtc] falls under the pre-2020 **舊制** (0–7 only).
  static bool usesLegacyScale(DateTime originTimeUtc) =>
      originTimeUtc.isBefore(newScaleSinceUtc);

  /// Label + palette index for a report's max intensity.
  ///
  /// **2020 以前是舊制**：震度只有 0–7（沒有 5弱/5強/6弱/6強），且 wire
  /// **不會出現 7、8**（那是新制 6弱/6強）。顯示時：
  /// - 5 →「5」，顏色用新制 5弱（index 5）
  /// - 6 →「6」，顏色用新制 6弱（index 7）
  /// - 9 →「7」，顏色用新制 7（index 9）— 舊制最高級在資料裡對到新制 index 9
  ///
  /// 2020 起（含）走 [label] + raw index 上色。
  static IntensityPresentation displayForReport(
    int intensity,
    DateTime originTimeUtc,
  ) {
    if (usesLegacyScale(originTimeUtc)) {
      return switch (intensity) {
        5 => const IntensityPresentation(label: '5', colorLevel: 5),
        6 => const IntensityPresentation(label: '6', colorLevel: 7),
        9 => const IntensityPresentation(label: '7', colorLevel: 9),
        _ => IntensityPresentation(
          label: '$intensity',
          colorLevel: intensity.clamp(0, 9),
        ),
      };
    }
    final level = intensity.clamp(0, 9);
    return IntensityPresentation(label: label(level), colorLevel: level);
  }
}

/// Badge copy + palette index for a report intensity (see
/// [Intensity.displayForReport]).
final class IntensityPresentation {
  const IntensityPresentation({required this.label, required this.colorLevel});

  /// Text drawn on the intensity badge.
  final String label;

  /// Index into the discrete felt-intensity palette (`0`…`9`).
  final int colorLevel;
}
