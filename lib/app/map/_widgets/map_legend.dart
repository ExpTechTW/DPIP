import 'package:collection/collection.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/layout.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';

class ColorLegendItem {
  final Color color;
  final String? label;
  final num value;
  final bool blendHead;
  final bool blendTail;
  final bool hidden;

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

class ColorLegend extends StatelessWidget {
  final List<ColorLegendItem> items;
  final bool reverse;
  final String? unit;
  final bool appendUnit;

  const ColorLegend({super.key, required this.items, this.reverse = false, this.appendUnit = false, this.unit});

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
          ? (previous != null ? Color.alphaBlend(item.color.withValues(alpha: 0.5), previous.color) : item.color)
          : item.color;
      final tailColor = item.blendTail
          ? (next != null ? Color.alphaBlend(item.color.withValues(alpha: 0.5), next.color) : item.color)
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: visibleIndex == 0
                      ? const BorderRadius.vertical(top: Radius.circular(8))
                      : (visibleIndex + 1) == visibleItems.length
                      ? const BorderRadius.vertical(bottom: Radius.circular(8))
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
                style: context.textTheme.labelSmall?.copyWith(
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
            style: context.textTheme.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

class LegendItem {
  final Widget icon;
  final String label;

  LegendItem({required this.icon, required this.label});
}

class Legend extends StatelessWidget {
  final List<LegendItem> items;
  final bool reverse;
  final String? unit;
  final bool appendUnit;

  const Legend({super.key, required this.items, this.reverse = false, this.appendUnit = false, this.unit});

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
              style: context.textTheme.labelSmall?.copyWith(
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
            style: context.textTheme.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

class OutlinedIcon extends StatelessWidget {
  final IconData icon;
  final Color? fill;
  final Color? stroke;
  final double? size;

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
