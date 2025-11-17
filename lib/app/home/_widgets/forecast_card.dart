import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/core/i18n.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ForecastCard extends StatefulWidget {
  final Map<String, dynamic> forecast;

  const ForecastCard(this.forecast, {super.key});

  @override
  State<ForecastCard> createState() => _ForecastCardState();
}

class _ForecastCardState extends State<ForecastCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<int> _expandedItems = {};
  final Map<int, GlobalKey> _pageKeys = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final data = widget.forecast['forecast'] as List<dynamic>?;
      if (data == null || data.isEmpty) return const SizedBox.shrink();

      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      for (final item in data) {
        final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;
        minTemp = min(minTemp, temp);
        maxTemp = max(maxTemp, temp);
      }

      final pages = <List<dynamic>>[];
      for (int i = 0; i < data.length; i += 3) {
        pages.add(data.skip(i).take(3).toList());
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.colors.outline.withValues(alpha: 0.1)),
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
                      color: context.colors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.wb_sunny_outlined, color: context.colors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '天氣預報(24h)'.i18n,
                    style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (pages.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${pages.length}',
                        style: context.theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                double calculatePageHeight(int pageIndex) {
                  double height = 0;
                  final pageData = pages[pageIndex];
                  for (int i = 0; i < pageData.length; i++) {
                    final globalIndex = pageIndex * 3 + i;
                    final isExpanded = _expandedItems.contains(globalIndex);
                    height += isExpanded ? 220 : 50;
                    if (i < pageData.length - 1 && !isExpanded) height += 1;
                  }
                  return (height + 4).clamp(0, 600);
                }

                double? measuredHeight;
                final currentKey = _pageKeys[_currentPage];
                if (currentKey?.currentContext != null) {
                  final RenderBox? box = currentKey!.currentContext!.findRenderObject() as RenderBox?;
                  if (box != null && box.hasSize) measuredHeight = box.size.height;
                }

                final pageHeight = measuredHeight ?? (pages.isNotEmpty ? calculatePageHeight(_currentPage) : 0.0);

                return AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    height: pageHeight > 0 ? pageHeight : null,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: pages.length,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final key = _pageKeys[index];
                          if (key?.currentContext != null) {
                            final RenderBox? box = key!.currentContext!.findRenderObject() as RenderBox?;
                            if (box != null && box.hasSize && mounted) setState(() {});
                          }
                        });
                      },
                      itemBuilder: (context, pageIndex) {
                        if (!_pageKeys.containsKey(pageIndex)) {
                          _pageKeys[pageIndex] = GlobalKey();
                        }
                        return SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            key: _pageKeys[pageIndex],
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: pages[pageIndex].asMap().entries.map((entry) {
                                final globalIndex = pageIndex * 3 + entry.key;
                                return _buildForecastItem(
                                  context,
                                  entry.value as Map<String, dynamic>,
                                  minTemp,
                                  maxTemp,
                                  globalIndex,
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildForecastItem(
    BuildContext context,
    Map<String, dynamic> item,
    double minTemp,
    double maxTemp,
    int index,
  ) {
    final time = item['time'] as String? ?? '';
    final weather = item['weather'] as String? ?? '';
    final pop = item['pop'] as int? ?? 0;
    final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;
    final apparent = (item['apparentTemp'] as num?)?.toDouble() ?? 0.0;
    final wind = item['wind'] as Map<String, dynamic>?;
    final windSpeed = (wind?['speed'] ?? 0) as num;
    final windDirection = (wind?['direction'] ?? '') as String;
    final windBeaufort = (wind?['beaufort'] ?? 0) as num;
    final humidity = (item['humidity'] ?? 0) as num;
    final isExpanded = _expandedItems.contains(index);
    final tempRange = maxTemp - minTemp;
    final tempPercent = tempRange > 0 ? ((temp - minTemp) / tempRange) : 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(index);
                } else {
                  _expandedItems.add(index);
                }
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final key = _pageKeys[_currentPage];
                if (key?.currentContext != null && mounted) setState(() {});
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isExpanded ? context.colors.surfaceContainerHighest.withValues(alpha: 0.3) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          time,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: context.colors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _getWeatherIcon(weather, context),
                          ),
                          if (weather.isNotEmpty)
                            Text(
                              weather,
                              style: context.theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          if (pop > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 2,
                                children: [
                                  Icon(
                                    Symbols.rainy_rounded,
                                    size: 11,
                                    color: Colors.indigo,
                                  ),
                                  Text(
                                    '$pop%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: tempPercent.clamp(0.05, 1.0),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        context.colors.primary,
                                        context.colors.primary.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${temp.round()}°',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                        size: 18,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.colors.outline.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDetailChip(
                            context,
                            Symbols.thermometer_rounded,
                            '氣溫',
                            '${temp.round()}°C',
                            Colors.orange,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.thermostat_rounded,
                            '體感',
                            '${apparent.round()}°C',
                            Colors.deepOrange,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.air_rounded,
                            '風速',
                            '${windSpeed}m/s',
                            context.colors.primary,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.explore_rounded,
                            '風向',
                            windDirection.isNotEmpty ? windDirection : '-',
                            context.colors.primary,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.wind_power_rounded,
                            '蒲福',
                            '${windBeaufort}級',
                            Colors.teal,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.humidity_percentage_rounded,
                            '濕度',
                            '${humidity.round()}%',
                            Colors.blue,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.rainy_rounded,
                            '降雨機率',
                            '$pop%',
                            Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (index % 3 != 2 && !isExpanded)
          Divider(
            height: 1,
            indent: 10,
            endIndent: 10,
            color: context.colors.outlineVariant.withValues(alpha: 0.2),
          ),
      ],
    );
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(icon, size: 14, color: color, weight: 600),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 9,
                  height: 1.0,
                ),
              ),
              Text(
                value,
                style: context.theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Icon _getWeatherIcon(String weather, BuildContext context) {
    if (weather.contains('晴')) {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 14);
    } else if (weather.contains('雨')) {
      return Icon(Icons.grain, color: Colors.blue, size: 14);
    } else if (weather.contains('雲') || weather.contains('陰')) {
      return Icon(Icons.cloud, color: context.colors.onSurface.withValues(alpha: 0.6), size: 14);
    } else if (weather.contains('雷')) {
      return Icon(Icons.flash_on, color: Colors.amber, size: 14);
    } else {
      return Icon(Icons.wb_cloudy, color: context.colors.onSurface.withValues(alpha: 0.6), size: 14);
    }
  }
}
