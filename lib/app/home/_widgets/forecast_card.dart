import 'dart:math';
import 'package:dpip/utils/log.dart';
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
  final Map<int, double> _measuredHeights = {};
  final Map<int, GlobalKey> _pageKeys = {};
  final Set<int> _measuringPages = {};
  List<List<dynamic>> _pages = [];
  double maxWeatherWidth = 0;
  List<dynamic>? _lastForecast;

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
      if (_lastForecast != data) {
        _lastForecast = data;

        final List<String> allWeatherTexts = [];
        for (final item in data) {
          final w = item['weather'] as String?;
          if (w != null && w.isNotEmpty) allWeatherTexts.add(w);
        }

        double longestWidth = 0;
        for (final text in allWeatherTexts) {
          final tp = TextPainter(
            text: TextSpan(
              text: text,
              style: context.theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(minWidth: 0, maxWidth: double.infinity);

          longestWidth = max(longestWidth, tp.width);
          tp.dispose();
        }

        const iconWidth = 30;
        const spacing = 8;
        const popWidth = 55;
        maxWeatherWidth = iconWidth + spacing + longestWidth + spacing + popWidth;
      }

      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      for (final item in data) {
        final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;
        minTemp = min(minTemp, temp);
        maxTemp = max(maxTemp, temp);
      }

      _pages = <List<dynamic>>[];
      for (int i = 0; i < data.length; i += 6) {
        _pages.add(data.skip(i).take(6).toList());
      }
      final pages = _pages;

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
                    final globalIndex = pageIndex * 6 + i;
                    final isExpanded = _expandedItems.contains(globalIndex);
                    height += isExpanded ? 320 : 84;
                    if (i < pageData.length - 1 && !isExpanded) height += 1;
                  }
                  return height + 4;
                }

                final calculatedHeight = pages.isNotEmpty ? calculatePageHeight(_currentPage) : 0.0;
                final pageHeight = _measuredHeights[_currentPage] ?? calculatedHeight;

                return AnimatedSize(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: SizedBox(
                    height: pageHeight,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: pages.length,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                          if (index < _pages.length) {
                            final currentPageStart = index * 6;
                            final currentPageEnd = currentPageStart + _pages[index].length - 1;
                            _expandedItems.removeWhere((expandedIndex) {
                              return expandedIndex < currentPageStart || expandedIndex > currentPageEnd;
                            });
                            if (_expandedItems.isNotEmpty) {
                              _measuredHeights.clear();
                            }
                          }
                          _measuredHeights.removeWhere((key, value) => key != index);
                        });
                      },
                      itemBuilder: (context, pageIndex) {
                        if (!_pageKeys.containsKey(pageIndex)) {
                          _pageKeys[pageIndex] = GlobalKey();
                        }
                        final key = _pageKeys[pageIndex]!;
                        if (!_measuredHeights.containsKey(pageIndex) && !_measuringPages.contains(pageIndex)) {
                          _measuringPages.add(pageIndex);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            final ctx = key.currentContext;
                            if (ctx == null) return;
                            final box = ctx.findRenderObject() as RenderBox?;
                            if (box == null || !box.hasSize) return;
                            final h = box.size.height;
                            if (!_measuredHeights.containsKey(pageIndex)) {
                              setState(() {
                                _measuredHeights[pageIndex] = h;
                              });
                            }
                            _measuringPages.remove(pageIndex);
                          });
                        }
                        return SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            key: key,
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: pages[pageIndex].asMap().entries.map((entry) {
                                final globalIndex = pageIndex * 6 + entry.key;
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
    } catch (e, s) {
      TalkerManager.instance.error('Failed to render forecast card', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('無法載入天氣預報'.i18n)));
    }
    return const SizedBox.shrink();
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
    final tempPercent = tempRange > 0 ? ((temp - minTemp) / tempRange).clamp(0.0, 1.0) : 0.5;

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
                  _expandedItems
                    ..clear()
                    ..add(index);
                }
                final pageIndex = index ~/ 6;
                _measuredHeights.remove(pageIndex);
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: isExpanded ? 10 : 14),
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
                      SizedBox(
                        width: 54,
                        child: Text(
                          time,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.colors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: maxWeatherWidth,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: _getWeatherIcon(weather, context),
                            ),
                            if (weather.isNotEmpty)
                            Text(
                              weather,
                              style: context.theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
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
                                children: [
                                  Icon(
                                    Symbols.rainy_rounded,
                                    size: 13,
                                    color: Colors.indigo,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$pop%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barWidth = constraints.maxWidth;
                            final indicatorPosition = tempPercent * barWidth;
                            final indicatorWidth = 20.0;
                            final maxLeft = (barWidth - indicatorWidth).clamp(0.0, double.infinity);
                            final leftPos = (indicatorPosition - indicatorWidth / 2).clamp(0.0, maxLeft);

                            return Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: leftPos,
                                    width: indicatorWidth,
                                    height: 20,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            context.colors.primary,
                                            context.colors.primary.withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${temp.round()}°',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                        size: 20,
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
                            '氣溫'.i18n,
                            '${temp.round()}°C',
                            Colors.orange,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.thermostat_rounded,
                            '體感'.i18n,
                            '${apparent.round()}°C',
                            Colors.deepOrange,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.air_rounded,
                            '風速'.i18n,
                            '${windSpeed}m/s',
                            context.colors.primary,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.explore_rounded,
                            '風向'.i18n,
                            windDirection.isNotEmpty ? _convertWindDirection(windDirection) : '-',
                            context.colors.primary,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.wind_power_rounded,
                            '風級'.i18n,
                            '${windBeaufort}級'.i18n,
                            Colors.teal,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.humidity_percentage_rounded,
                            '濕度'.i18n,
                            '${humidity.round()}%',
                            Colors.blue,
                          ),
                          _buildDetailChip(
                            context,
                            Symbols.rainy_rounded,
                            '降雨機率'.i18n,
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
        if (index % 4 != 3 && !isExpanded)
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
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 16);
    } else if (weather.contains('雨')) {
      return Icon(Icons.grain, color: Colors.blue, size: 16);
    } else if (weather.contains('雲') || weather.contains('陰')) {
      return Icon(Icons.cloud, color: context.colors.onSurface.withValues(alpha: 0.6), size: 16);
    } else if (weather.contains('雷')) {
      return Icon(Icons.flash_on, color: Colors.amber, size: 16);
    } else {
      return Icon(Icons.wb_cloudy, color: context.colors.onSurface.withValues(alpha: 0.6), size: 16);
    }
  }

  String _convertWindDirection(String direction) {
    const Map<String, String> directionMap = {
      'N': '北',
      'NNE': '北北東',
      'NE': '東北',
      'ENE': '東北東',
      'E': '東',
      'ESE': '東南東',
      'SE': '東南',
      'SSE': '南南東',
      'S': '南',
      'SSW': '南南西',
      'SW': '西南',
      'WSW': '西南西',
      'W': '西',
      'WNW': '西北西',
      'NW': '西北',
      'NNW': '北北西',
    };
    return directionMap[direction.toUpperCase()] ?? direction;
  }
}
