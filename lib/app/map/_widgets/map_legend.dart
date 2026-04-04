/// Legend widgets used in the map overlay panels.
library;

import 'package:collection/collection.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/layout.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';

/// A single entry in a [ColorLegend], pairing a colour swatch with a value.
class ColorLegendItem {
  /// The colour displayed in the swatch for this entry.
  final Color color;

  /// An optional override label; defaults to [value] when `null`.
  final String? label;

  /// The numeric value associated with this colour band.
  final num value;

  /// Whether the top edge of this swatch blends with the previous item's
  /// colour.
  final bool blendHead;

  /// Whether the bottom edge of this swatch blends with the next item's
  /// colour.
  final bool blendTail;

  /// When `true`, this item is omitted from the rendered legend.
  final bool hidden;

  /// Creates a [ColorLegendItem] with the required [color] and [value].
  ColorLegendItem({
    required this.color,
    required this.value,
    this.label,
    this.blendHead = true,
    this.blendTail = true,
    this.hidden = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is ColorLegendItem) {
      return color == other.color &&
          value == other.value &&
          label == other.label &&
          blendHead == other.blendHead &&
          blendTail == other.blendTail &&
          hidden == other.hidden;
    }

    return false;
  }

  @override
  int get hashCode => Object.hash(color, value, blendHead, blendTail, hidden);
}

/// A vertical colour-scale legend rendered as blended gradient swatches.
///
/// Set [reverse] to `true` to display [items] from bottom to top. Provide
/// [unit] to show a unit label; set [appendUnit] to append it inline next to
/// each value instead of below the legend.
class ColorLegend extends StatelessWidget {
  /// The list of colour band items to display.
  final List<ColorLegendItem> items;

  /// Whether to display items in reverse order.
  final bool reverse;

  /// The unit string shown below or inline with the legend values.
  final String? unit;

  /// When `true`, appends [unit] after each value label instead of below.
  final bool appendUnit;

  /// Creates a [ColorLegend] from the given [items].
  const ColorLegend({
    super.key,
    required this.items,
    this.reverse = false,
    this.appendUnit = false,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final items = reverse ? this.items.reversed.toList() : this.items;
    final visibleItems = items.where((item) => !item.hidden).toList();

    final children = items.mapIndexed((index, item) {
      if (item.hidden) return const SizedBox.shrink();

      final visibleIndex = visibleItems.indexOf(item);

      final previous = index == 0 ? null : items.elementAtOrNull(index - 1);
      final next = items.elementAtOrNull(index + 1);

      final headColor = item.blendHead
          ? (previous != null
                ? Color.alphaBlend(
                    item.color.withValues(alpha: 0.5),
                    previous.color,
                  )
                : item.color)
          : item.color;
      final tailColor = item.blendTail
          ? (next != null
                ? Color.alphaBlend(
                    item.color.withValues(alpha: 0.5),
                    next.color,
                  )
                : item.color)
          : item.color;

      return IntrinsicHeight(
        child: Layout.row.stretch[6](
          children: [
            if (!item.blendHead && !item.blendTail)
              ColoredBox(color: item.color)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headColor, item.color, tailColor],
                    begin: .topCenter,
                    end: .bottomCenter,
                  ),
                  borderRadius: visibleIndex == 0
                      ? const .vertical(top: Radius.circular(8))
                      : (visibleIndex + 1) == visibleItems.length
                      ? const .vertical(bottom: Radius.circular(8))
                      : null,
                ),
                width: 8,
              ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: item.label ?? '${item.value}'),
                  if (unit != null && appendUnit)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(color: context.colors.outline),
                    ),
                ],
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Layout.col.left[2](
      children: [
        Layout.col.left(children: children),
        if (unit != null && !appendUnit)
          Text(
            '單位：{unit}'.i18n.args({'unit': unit!}),
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// A single entry in a [Legend], combining an icon widget with a text label.
class LegendItem {
  /// The icon widget displayed beside [label].
  final Widget icon;

  /// The descriptive text for this legend entry.
  final String label;

  /// Creates a [LegendItem] with the required [icon] and [label].
  LegendItem({required this.icon, required this.label});
}

/// A vertical icon-based legend for categorical map data.
///
/// Set [reverse] to `true` to display [items] from bottom to top. Provide
/// [unit] to show a unit label; set [appendUnit] to append it inline.
class Legend extends StatelessWidget {
  /// The list of icon-label entries to display.
  final List<LegendItem> items;

  /// Whether to display items in reverse order.
  final bool reverse;

  /// The unit string shown below or inline with the legend values.
  final String? unit;

  /// When `true`, appends [unit] after each label instead of below.
  final bool appendUnit;

  /// Creates a [Legend] from the given [items].
  const Legend({
    super.key,
    required this.items,
    this.reverse = false,
    this.appendUnit = false,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final items = reverse ? this.items.reversed.toList() : this.items;

    final children = items.map((item) {
      return Layout.row.left[2](
        children: [
          item.icon,
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: item.label),
                if (unit != null && appendUnit)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(color: context.colors.outline),
                  ),
              ],
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      );
    }).toList();

    return Layout.col.left[2](
      children: [
        Layout.col.left(children: children),
        if (unit != null && !appendUnit)
          Text(
            '單位：{unit}'.i18n.args({'unit': unit!}),
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// An icon rendered with an independent fill colour and outline colour.
///
/// Achieved by stacking two [Icon] widgets: one filled and one stroked.
class OutlinedIcon extends StatelessWidget {
  /// The icon glyph to render.
  final IconData icon;

  /// The interior fill colour of the icon.
  final Color? fill;

  /// The outline stroke colour of the icon.
  final Color? stroke;

  /// The logical pixel size of the icon.
  final double? size;

  /// Creates an [OutlinedIcon] for [icon].
  const OutlinedIcon(this.icon, {super.key, this.fill, this.stroke, this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(icon, fill: 1, color: fill, size: size),
        Icon(icon, fill: 0, color: stroke, size: size),
      ],
    );
  }
}
