/// Compact map-overlay legends — a frosted card holding either a continuous
/// colour scale ([ColorScaleLegend]) or a list of symbol rows ([SymbolLegend]).
///
/// Placed top-left by [MapScaffold] via each layer's [MapLayer.buildLegend].
/// Matches the RTS intensity legend's density so every layer reads the same.
///
/// **Colour-vision: these widgets transform nothing, deliberately.** A legend
/// is handed the very colours its layer paints with, so the correction has
/// already been applied — or deliberately withheld — where those colours are
/// defined. Correcting again here would daltonise a daltonised colour and make
/// the key disagree with the map. It would also be wrong in the one case that
/// matters most: the radar and satellite legends describe server-rendered
/// raster tiles, whose pixels MapLibre cannot recolour, so their stops are
/// wrapped in `ColorVisionFilter.rasterExemptHex` at the definition — in
/// `RadarLayer` and `SatelliteLegend` — and must arrive here untouched. `colorFromHexRgb` below stays a pure converter for the same
/// reason (see `shared/color_hex.dart`).
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';

/// One stop on a continuous colour ramp: [at] is the labelled value, [hex] an
/// opaque `#RRGGBB` (same wire form the map layers feed MapLibre).
typedef ColorStop = (double at, String hex);

/// Frosted card wrapping a legend body so it reads over any map tile.
class MapLegendCard extends StatelessWidget {
  const MapLegendCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FrostedSurface(
      borderRadius: AppRadius.small,
      shadow: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: child,
      ),
    );
  }
}

/// Vertical colour scale built from ascending [stops] — strongest (last stop)
/// at the top, matching legacy `ColorLegend(reverse: true)`.
///
/// The unit, when present, is always shown **below** the scale ([unit]); it is
/// never appended to every value label — a number column stays numbers.
class ColorScaleLegend extends StatelessWidget {
  const ColorScaleLegend({
    super.key,
    required this.stops,
    this.unit,
    this.banded = false,
  });

  /// Ascending value → hex colour pairs (same order as MapLibre ramps), in
  /// whatever colour the layer actually paints — corrected, or raster-exempt,
  /// at their definition. Drawn here as given; see the library doc.
  final List<ColorStop> stops;

  /// Unit shown below the scale, e.g. `m/s` or `°C`.
  final String? unit;

  /// Draw hard-edged bands instead of a gradient.
  ///
  /// A banded scale is a table of categories, so each stop paints a solid cell
  /// and its value is printed **on the boundary** it opens — the reading a
  /// number marks is where one band ends and the next begins, not the middle of
  /// a swatch. The lowest stop is the below-threshold band and prints no
  /// number, which is why N stops show N-1 labels.
  final bool banded;

  static const double _cell = 14;
  static const double _swatch = 8;
  static const double _corner = 4;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      height: 1,
      color: colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Display strongest → weakest (top → bottom).
    final rows = stops.reversed.toList();
    final swatchColors = [
      for (final stop in rows) colorFromHexRgb(stop.$2) ?? colors.outline,
    ];
    final height = _cell * rows.length;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _swatch,
              height: height,
              clipBehavior: banded ? Clip.antiAlias : Clip.none,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_corner),
                gradient: banded
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: swatchColors,
                      ),
              ),
              child: banded
                  ? Column(
                      // ColoredBox has no intrinsic width, and the default
                      // cross axis is center — under the Container's loose
                      // (0.._swatch) width the band column would collapse to
                      // zero and the whole strip would vanish, leaving the
                      // boundary numbers with no colour beside them. Stretch
                      // forces every band to fill the swatch width.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final color in swatchColors)
                          Expanded(child: ColoredBox(color: color)),
                      ],
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: height,
              child: banded
                  ? _BandBoundaryLabels(rows: rows, style: labelStyle)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final stop in rows)
                          Expanded(
                            child: Text(_label(stop.$1), style: labelStyle),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        if (unit != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.mapLegendUnit(unit!), style: labelStyle),
        ],
      ],
    );
  }

  static String _label(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

/// One row of a categorical / discrete legend.
class SymbolLegendItem {
  const SymbolLegendItem({required this.swatch, required this.label});

  /// Leading mark (coloured icon, line, or circle).
  final Widget swatch;

  /// Value / category text.
  final String label;
}

/// Vertical list of [SymbolLegendItem]s — wind buckets, typhoon track keys, etc.
class SymbolLegend extends StatelessWidget {
  const SymbolLegend({super.key, required this.items, this.unit});

  final List<SymbolLegendItem> items;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          if (item != items.first) const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              item.swatch,
              const SizedBox(width: AppSpacing.sm),
              Text(item.label, style: labelStyle),
            ],
          ),
        ],
        if (unit != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.mapLegendUnit(unit!), style: labelStyle),
        ],
      ],
    );
  }
}

/// A solid circular colour swatch for a [SymbolLegendItem] — the dot mark for
/// discrete categories (feed status, storm intensity, station type). Drawn the
/// same way as the layer's map markers where applicable.
class LegendDot extends StatelessWidget {
  const LegendDot({
    super.key,
    required this.color,
    this.size = 10,
    this.borderWidth = 0,
  });

  final Color color;
  final double size;

  /// White ring width — `1` matches a marker that's ringed on the map.
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: Colors.white, width: borderWidth)
            : null,
      ),
    );
  }
}

/// A short line sample for a [SymbolLegendItem] — the swatch for an outline
/// overlay (an administrative border, a coverage boundary).
///
/// Draws the *same* construction the map does, casing included, so the key can
/// be matched to the line on screen rather than merely described.
class LineSwatch extends StatelessWidget {
  const LineSwatch({
    super.key,
    required this.color,
    this.width = 1.2,
    this.opacity = 1,
    this.casingColor,
    this.casingWidth = 0,
    this.casingOpacity = 1,
    this.dash,
  });

  /// The core stroke.
  final Color color;
  final double width;
  final double opacity;

  /// Optional wider stroke drawn beneath [color].
  final Color? casingColor;
  final double casingWidth;
  final double casingOpacity;

  /// `[dash, gap]` in logical pixels; null draws a solid line.
  final List<double>? dash;

  static const Size _size = Size(20, 12);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: _size,
      painter: _LineSwatchPainter(
        color: color,
        width: width,
        opacity: opacity,
        casingColor: casingColor,
        casingWidth: casingWidth,
        casingOpacity: casingOpacity,
        dash: dash,
      ),
    );
  }
}

class _LineSwatchPainter extends CustomPainter {
  _LineSwatchPainter({
    required this.color,
    required this.width,
    required this.opacity,
    required this.casingColor,
    required this.casingWidth,
    required this.casingOpacity,
    required this.dash,
  });

  final Color color;
  final double width;
  final double opacity;
  final Color? casingColor;
  final double casingWidth;
  final double casingOpacity;
  final List<double>? dash;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final casing = casingColor;
    if (casing != null && casingWidth > 0) {
      _stroke(
        canvas,
        size,
        y,
        casing.withValues(alpha: casingOpacity),
        casingWidth,
      );
    }
    _stroke(canvas, size, y, color.withValues(alpha: opacity), width);
  }

  void _stroke(Canvas canvas, Size size, double y, Color c, double w) {
    final paint = Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final pattern = dash;
    if (pattern == null || pattern.length < 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    // Dash lengths are in line-width multiples on the map, as MapLibre defines
    // `line-dasharray`, so scale them the same way here.
    final on = pattern[0] * w;
    final off = pattern[1] * w;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + on, size.width), y),
        paint,
      );
      x += on + off;
    }
  }

  @override
  bool shouldRepaint(covariant _LineSwatchPainter old) =>
      old.color != color ||
      old.width != width ||
      old.opacity != opacity ||
      old.casingColor != casingColor ||
      old.casingWidth != casingWidth ||
      old.dash != dash;
}

/// The number column of a banded scale.
///
/// Each label is centred on the line between two bands rather than inside one,
/// which is how a published rainfall scale reads: `70` is the point the band
/// changes, not a sample from within it. [rows] is strongest-first (top-down),
/// so row *i* opens the boundary one cell below the top of its own band, and
/// the last row — the below-threshold band — opens nothing and is skipped.
class _BandBoundaryLabels extends StatelessWidget {
  const _BandBoundaryLabels({required this.rows, required this.style});

  final List<ColorStop> rows;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    const cell = ColorScaleLegend._cell;
    final labels = [
      for (var i = 0; i < rows.length - 1; i++)
        ColorScaleLegend._label(rows[i].$1),
    ];
    // The label column sits in a Row, which hands children unbounded width —
    // and a Stack refuses that. Measure the widest boundary label so this
    // column carries its own bounded width (text scaling included) instead of
    // asking the map's collapsed-legend chip for one; without it, expanding
    // the 雨量 legend throws a layout assertion every frame and the legend
    // never appears.
    final width = _widestLabel(labels, style, MediaQuery.textScalerOf(context));
    return SizedBox(
      width: width,
      height: cell * rows.length,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < labels.length; i++)
            Positioned(
              top: (i + 1) * cell - cell / 2,
              left: 0,
              height: cell,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(labels[i], style: style),
              ),
            ),
        ],
      ),
    );
  }

  static double _widestLabel(
    List<String> labels,
    TextStyle? style,
    TextScaler textScaler,
  ) {
    var widest = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest;
  }
}
