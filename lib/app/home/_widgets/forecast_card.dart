import 'dart:math';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ForecastCard extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const ForecastCard(this.forecast, {super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final data = forecast['forecast'] as List<dynamic>?;
      if (data == null || data.isEmpty) return const SizedBox.shrink();

      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      for (final item in data) {
        final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;
        minTemp = min(minTemp, temp);
        maxTemp = max(maxTemp, temp);
      }

      return ResponsiveContainer(
        child: Card(
          margin: const .symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: .circular(16),
            side: BorderSide(
              color: context.colors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const .symmetric(vertical: 8),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    spacing: 8,
                    children: [
                      ContainedIcon(
                        Symbols.weather_mix_rounded,
                        color: context.colors.primary,
                        size: 18,
                      ),
                      TitleText.medium(
                        '天氣預報(24h)'.i18n,
                        weight: .bold,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: .horizontal,
                    padding: const .all(4),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index] as Map<String, dynamic>;
                      return _ForecastItem(
                        item: item,
                        minTemp: minTemp,
                        maxTemp: maxTemp,
                      );
                    },
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

class _ForecastItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final double minTemp;
  final double maxTemp;

  const _ForecastItem({
    required this.item,
    required this.minTemp,
    required this.maxTemp,
  });

  static (IconData, Color?) _weatherIcon(String weather) => switch (weather) {
    final s when s.contains('晴') => (
      Symbols.sunny_rounded,
      Colors.orangeAccent,
    ),
    final s when s.contains('雨') => (
      Symbols.rainy_light_rounded,
      Colors.blueAccent,
    ),
    final s when s.contains('雲') || s.contains('陰') => (
      Symbols.cloud_rounded,
      Colors.blueGrey[300],
    ),
    final s when s.contains('雷') => (
      Symbols.flash_on,
      Colors.yellow,
    ),
    final s when s.contains('雪') => (
      Symbols.snowflake_rounded,
      Colors.white70,
    ),
    _ => (Symbols.wb_cloudy, Colors.grey.withValues(alpha: 0.6)),
  };

  @override
  Widget build(BuildContext context) {
    final time = item['time'] as String? ?? '';
    final weather = item['weather'] as String? ?? '';
    final pop = item['pop'] as int? ?? 0;
    final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;

    final tempRange = maxTemp - minTemp;
    final tempPercent = tempRange > 0
        ? ((temp - minTemp) / tempRange).clamp(0.0, 1.0) * 0.82 + 0.18
        : 0.0;

    final (icon, color) = _weatherIcon(weather);

    return Container(
      width: 52,
      margin: const .symmetric(horizontal: 2),
      padding: const .symmetric(vertical: 4),
      child: Column(
        spacing: 4,
        children: [
          Container(
            padding: const .all(4),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: .circular(6),
            ),
            child: Icon(icon, color: color, fill: 1, size: 18),
          ),
          Row(
            mainAxisSize: .min,
            children: [
              const Icon(
                Symbols.water_drop_rounded,
                size: 10,
                color: Colors.blue,
              ),
              Text(
                '$pop%',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const .symmetric(vertical: 4),
              child: Column(
                verticalDirection: .up,
                children: [
                  Flexible(
                    flex: (1 - tempPercent).asPercentage,
                    child: const SizedBox(),
                  ),
                  Flexible(
                    flex: tempPercent.asPercentage,
                    child: Container(
                      width: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: .topCenter,
                          end: .bottomCenter,
                          colors: [
                            context.colors.tertiary,
                            context.colors.tertiary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: .circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BodyText.medium(
            '${temp.round()}°',
            weight: .bold,
            color: context.colors.onSurface,
          ),
          BodyText.small(
            time,
            color: context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
