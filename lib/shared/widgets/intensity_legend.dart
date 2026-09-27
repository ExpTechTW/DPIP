/// The seismic-intensity colour legend shown over the map — a compact vertical
/// scale that relates each colour on the map to its intensity value.
///
/// Two modes, one per scale in `intensity_colors.dart`:
///  - [IntensityLegendMode.rts] — the real-time monitor's **continuous**
///    instrumental intensity, one 0 → 7 gradient bar (7 at the top), drawn
///    from the same table as the station dots.
///  - [IntensityLegendMode.eew] — the **discrete** felt-intensity scale
///    (1 → 7, with 5/6 split), stacked cells (7 at the top).
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/material.dart';

/// Which intensity scale the legend shows.
enum IntensityLegendMode { eew, rts }

class IntensityLegend extends StatelessWidget {
  const IntensityLegend({super.key, this.mode = IntensityLegendMode.rts});

  /// Which scale to render.
  final IntensityLegendMode mode;

  /// Height of one scale cell / gradient step (px).
  static const double _cell = 12;

  /// Width of the colour swatch column (px).
  static const double _swatch = 8;

  /// Corner rounding on the bar / cell ends — legend-intrinsic, smaller than the
  /// smallest [AppRadius] token would allow on an 8px-wide swatch.
  static const double _corner = 4;

  @override
  Widget build(BuildContext context) {
    // Pin the line height so a label's box never exceeds a [_cell]-tall row —
    // otherwise the taller default line height spaces the EEW cells apart and
    // the intended continuous bar fragments.
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(height: 1);
    return mode == IntensityLegendMode.rts
        ? _rtsScale(labelStyle)
        : _eewScale(labelStyle);
  }

  /// Continuous instrumental scale as one gradient bar, 7 (top) → 0 (bottom),
  /// with labels spread evenly alongside it.
  ///
  /// It stops at 0 because the dots do: every reading at or below 0 is the
  /// same darkest blue, so the bar's bottom stands for all of them. Sampled
  /// every 0.1 of `i`, top → bottom, so the bar holds each colour a dot can
  /// take at the height of its reading.
  Widget _rtsScale(TextStyle? labelStyle) {
    const labels = ['7', '6', '5', '4', '3', '2', '1', '0'];
    final colors = [
      for (var tenth = 70; tenth >= 0; tenth--)
        InstrumentalIntensityColors.of(tenth / 10),
    ];
    final height = _cell * labels.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _swatch,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_corner),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final label in labels)
                Expanded(child: Text(label, style: labelStyle)),
            ],
          ),
        ),
      ],
    );
  }

  /// Discrete felt-intensity scale as stacked cells, 7 (top) → 1 (bottom).
  Widget _eewScale(TextStyle? labelStyle) {
    // Scale index → label, top (strongest) to bottom.
    const rows = [
      (9, '7'),
      (8, '6⁺'),
      (7, '6⁻'),
      (6, '5⁺'),
      (5, '5⁻'),
      (4, '4'),
      (3, '3'),
      (2, '2'),
      (1, '1'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _swatch,
                height: _cell,
                decoration: BoxDecoration(
                  color: IntensityColors.discrete(rows[i].$1),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(i == 0 ? _corner : 0),
                    bottom: Radius.circular(i == rows.length - 1 ? _corner : 0),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(rows[i].$2, style: labelStyle),
            ],
          ),
      ],
    );
  }
}
