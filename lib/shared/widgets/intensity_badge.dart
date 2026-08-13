import 'package:dpip/app/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// A filled square badge showing a felt-intensity label (e.g. `5⁻`) over its
/// palette [color] — the report list row and report detail header share this
/// so the two never drift in style.
///
/// [outlined] renders the legacy `IntensityBox(border: true)` form — a bare
/// coloured ring over the surface (used for 小區域 reports in the catalogue,
/// whose wire intensity is not backed by a numbered CWA report). The legacy
/// app distinguished the two report kinds by fill: numbered = solid, 小區域 =
/// hollow ring; the detail header only ever uses the solid form.
class IntensityBadge extends StatelessWidget {
  const IntensityBadge({
    super.key,
    required this.label,
    required this.color,
    this.size = 48,
    this.outlined = false,
  });

  /// Text drawn on the badge (see [Intensity.displayForReport]).
  final String label;

  /// Palette colour for the badge fill (see `IntensityColors.discrete`).
  final Color color;

  /// Edge length of the square badge.
  final double size;

  /// Hollow-ring form (border only, no fill) — see the class doc.
  final bool outlined;

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
    final decoration = outlined
        ? BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: color, width: 3),
            borderRadius: AppRadius.small,
          )
        : BoxDecoration(color: color, borderRadius: AppRadius.small);
    return DecoratedBox(
      decoration: decoration,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            label,
            style: titleLarge?.copyWith(
              // The hollow ring sits on the surface — its label must read in
              // the surface's own text colour, not guess from the ring colour.
              color: outlined ? null : onBadge,
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
