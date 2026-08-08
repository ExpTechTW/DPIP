import 'package:dpip/app/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// A filled square badge showing a felt-intensity label (e.g. `5⁻`) over its
/// palette [color] — the report list row and report detail header share this
/// so the two never drift in style.
class IntensityBadge extends StatelessWidget {
  const IntensityBadge({
    super.key,
    required this.label,
    required this.color,
    this.size = 48,
  });

  /// Text drawn on the badge (see [Intensity.displayForReport]).
  final String label;

  /// Palette colour for the badge fill (see `IntensityColors.discrete`).
  final Color color;

  /// Edge length of the square badge.
  final double size;

  @override
  Widget build(BuildContext context) {
    final onBadge =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final titleLarge = Theme.of(context).textTheme.titleLarge;
    // Scale proportionally from the reference 48px badge size so larger/
    // smaller badges (e.g. the detail header) keep the same visual weight.
    final fontSize = (titleLarge?.fontSize ?? 22) * (size / 48);
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.small),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            label,
            style: titleLarge?.copyWith(
              color: onBadge,
              fontWeight: FontWeight.w900,
              height: 1,
              fontSize: fontSize,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
