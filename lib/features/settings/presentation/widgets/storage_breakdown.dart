/// Storage breakdown: a donut chart of what is on disk plus a labelled legend
/// with sizes and percentages.
///
/// Deliberately English-only like the rest of the Developer page (it exists to
/// be screenshotted into a bug report). No tooltips — a pie label balloon was
/// exactly what overflowed the screen in the network chart, and a legend
/// beside the chart is readable at a glance anyway.
library;

import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Colour for the [index]th slice — a fixed, distinguishable palette.
const List<Color> storageSliceColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
  Color(0xFFD81B60),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
];

class StorageBreakdown extends StatelessWidget {
  const StorageBreakdown({
    super.key,
    required this.slices,
    required this.total,
  });

  /// Already-sorted slices; the pie is drawn from these.
  final List<StorageSlice> slices;

  /// The total the percentages are measured against.
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (total <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 30,
                sectionsSpace: 2,
                sections: [
                  for (var i = 0; i < slices.length; i++)
                    PieChartSectionData(
                      value: slices[i].bytes.toDouble(),
                      color: storageSliceColors[i % storageSliceColors.length],
                      radius: 46,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < slices.length; i++) _legendRow(theme, i),
        ],
      ),
    );
  }

  Widget _legendRow(ThemeData theme, int i) {
    final slice = slices[i];
    final percent = total == 0 ? 0.0 : slice.bytes / total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: storageSliceColors[i % storageSliceColors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(slice.label, style: theme.textTheme.bodySmall)),
          Text(
            '${formatBytes(slice.bytes)} · ${percent.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
