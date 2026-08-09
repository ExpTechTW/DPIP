/// Compact map-overlay legends — a frosted card holding either a continuous
/// colour scale ([ColorScaleLegend]) or a list of symbol rows ([SymbolLegend]).
///
/// Placed top-left by [MapScaffold] via each layer's [MapLayer.buildLegend].
/// Matches the RTS intensity legend's density so every layer reads the same.
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
class ColorScaleLegend extends StatelessWidget {
  const ColorScaleLegend({
    super.key,
    required this.stops,
    this.unit,
    this.appendUnit = false,
  });

  /// Ascending value → hex colour pairs (same order as MapLibre ramps).
  final List<ColorStop> stops;

  /// Optional unit shown below the scale, or appended to each label when
  /// [appendUnit] is true.
  final String? unit;

  /// When true, append [unit] after each value instead of under the scale.
  final bool appendUnit;

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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_corner),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: swatchColors,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final stop in rows)
                    Expanded(
                      child: Text(
                        _label(stop.$1, unit, appendUnit),
                        style: labelStyle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (unit != null && !appendUnit) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.mapLegendUnit(unit!), style: labelStyle),
        ],
      ],
    );
  }

  static String _label(double value, String? unit, bool appendUnit) {
    final number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    if (appendUnit && unit != null) return '$number $unit';
    return number;
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
