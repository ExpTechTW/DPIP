/// 24-hour weather forecast card for the home screen.
///
/// 用簡約風格顯示 24 小時預報
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

const double _kColumnWidth = 56.0;

/// Renders a horizontal scrolling 24-hour forecast strip from raw [forecast]
/// JSON data.
///
/// Returns [SizedBox.shrink] when the data is missing or malformed.
class ForecastCard extends StatelessWidget {
  /// The raw forecast JSON map returned by the ExpTech API.
  final Map<String, dynamic> forecast;

  /// Creates a [ForecastCard] with the given raw [forecast] data.
  const ForecastCard(this.forecast, {super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final data = forecast['forecast'] as List<dynamic>?;
      if (data == null || data.isEmpty) return const SizedBox.shrink();

      return ResponsiveContainer(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '24 小時預報'.i18n,
                    style: context.texts.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < data.length; i++)
                        _HourColumn(
                          item: data[i] as Map<String, dynamic>,
                          isNow: i == 0,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, s) {
      TalkerManager.instance.error('Failed to render forecast card', e, s);
    }
    return const SizedBox.shrink();
  }
}

class _HourColumn extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isNow;

  const _HourColumn({required this.item, required this.isNow});

  static (IconData, Color?) _weatherIcon(BuildContext context, String weather) => switch (weather) {
    final s when s.contains('晴') => (Symbols.sunny_rounded, Colors.orangeAccent),
    final s when s.contains('雨') => (Symbols.rainy_light_rounded, Colors.blueAccent),
    final s when s.contains('雲') || s.contains('陰') => (
      Symbols.cloud_rounded,
      context.colors.onSurfaceVariant,
    ),
    final s when s.contains('雷') => (Symbols.flash_on_rounded, Colors.amber),
    final s when s.contains('雪') => (Symbols.snowflake_rounded, Colors.lightBlue[200]),
    _ => (Symbols.wb_cloudy_rounded, context.colors.onSurfaceVariant),
  };

  @override
  Widget build(BuildContext context) {
    final time = item['time'] as String? ?? '';
    final weather = item['weather'] as String? ?? '';
    final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;
    final pop = item['pop'] as int? ?? 0;

    final (icon, color) = _weatherIcon(context, weather);

    final primaryColor = isNow
        ? context.colors.onSurface
        : context.colors.onSurface.withValues(alpha: 0.82);
    final labelColor = isNow
        ? context.colors.onSurface
        : context.colors.onSurfaceVariant.withValues(alpha: 0.75);

    return SizedBox(
      width: _kColumnWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isNow ? '現在'.i18n : time,
            style: context.texts.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Icon(icon, color: color, fill: 1, size: 24),
          if (pop > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.water_drop_rounded,
                  size: 10,
                  color: Colors.blueAccent.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 2),
                Text(
                  '$pop%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blueAccent.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${temp.round()}°',
            style: context.texts.titleMedium?.copyWith(
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w600,
              color: primaryColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
