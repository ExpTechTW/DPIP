import 'dart:math';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ForecastCard extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const ForecastCard(this.forecast, {super.key});

  (String, String) _formatTime(String time) {
    final parts = time.split(':');
    if (parts.isEmpty) return ('--', '--');

    final hour24 = int.tryParse(parts[0]) ?? 0;
    final period = hour24 < 12 ? '上午'.i18n : '下午'.i18n;
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return (period, '$hour12時'.i18n);
  }

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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: context.colors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: context.colors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '天氣預報(24h)'.i18n,
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index] as Map<String, dynamic>;
                    return _buildForecastItem(
                      context,
                      item,
                      minTemp,
                      maxTemp,
                      index == 0,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e, s) {
      TalkerManager.instance.error('Failed to render forecast card', e, s);
      context.scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('無法載入天氣預報'.i18n)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildForecastItem(
    BuildContext context,
    Map<String, dynamic> item,
    double minTemp,
    double maxTemp,
    bool isFirst,
  ) {
    final time = item['time'] as String? ?? '';
    final weather = item['weather'] as String? ?? '';
    final pop = item['pop'] as int? ?? 0;
    final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;
    final (period, hour) = _formatTime(time);

    final tempRange = maxTemp - minTemp;
    final tempPercent = tempRange > 0
        ? ((temp - minTemp) / tempRange).clamp(0.0, 1.0)
        : 0.5;

    return Container(
      width: 52,
      margin: EdgeInsets.only(left: isFirst ? 0 : 2, right: 2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                period,
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 9,
                  height: 1.1,
                ),
              ),
              Text(
                hour,
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _getWeatherIcon(weather, context),
          ),
          if (pop > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Symbols.water_drop_rounded,
                  size: 8,
                  color: Colors.blue,
                ),
                Text(
                  '$pop%',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 10),
          SizedBox(
            height: 50,
            width: 14,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 14,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: context.colors.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                Positioned(
                  bottom: tempPercent * 36,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.colors.primary,
                          context.colors.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${temp.round()}°',
            style: context.theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Icon _getWeatherIcon(String weather, BuildContext context) {
    if (weather.contains('晴')) {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 18);
    } else if (weather.contains('雨')) {
      return Icon(Icons.grain, color: Colors.blue, size: 18);
    } else if (weather.contains('雲') || weather.contains('陰')) {
      return Icon(
        Icons.cloud,
        color: context.colors.onSurface.withValues(alpha: 0.6),
        size: 18,
      );
    } else if (weather.contains('雷')) {
      return Icon(Icons.flash_on, color: Colors.amber, size: 18);
    } else {
      return Icon(
        Icons.wb_cloudy,
        color: context.colors.onSurface.withValues(alpha: 0.6),
        size: 18,
      );
    }
  }
}
