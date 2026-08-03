/// Compact map-overlay legends — a frosted card holding either a continuous
/// colour scale ([ColorScaleLegend]) or a list of symbol rows ([SymbolLegend]).
///
/// Placed top-left by [MapScaffold] via each layer's [MapLayer.buildLegend].
/// Matches the RTS intensity legend's density so every layer reads the same.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.small,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: child,
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
