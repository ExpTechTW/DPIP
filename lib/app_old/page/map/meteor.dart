import 'dart:math';

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/meteor_station.dart';
import 'package:dpip/utils/extensions/build_context.dart';

typedef StationIdUpdateCallback = void Function(String?);

class AdvancedWeatherChart extends StatefulWidget {
  final String stationId;
  final VoidCallback onClose;
  final String? type;

  const AdvancedWeatherChart({super.key, required this.stationId, required this.onClose, this.type = 'temperature'});

  @override
  State<AdvancedWeatherChart> createState() => _AdvancedWeatherChartState();

  static StationIdUpdateCallback? _activeCallback;

  static void setActiveCallback(StationIdUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updateStationId(String? getstationId) {
    _activeCallback?.call(getstationId);
  }
}

class _AdvancedWeatherChartState extends State<AdvancedWeatherChart> {
  String? selectedDataType;
  int touchedIndex = -1;
  bool isLoading = true;
  Map<String, List<double>> weatherData = {};
  List<double> windDirection = [];
  MeteorStation? data;
  String? stationId;

  @override
  void initState() {
    super.initState();
    stationId = widget.stationId;
    _fetchWeatherData();
    selectedDataType = widget.type;
    AdvancedWeatherChart.setActiveCallback(_handleStationIdUpdate);
  }

  @override
  void dispose() {
    AdvancedWeatherChart.clearActiveCallback();
    super.dispose();
  }

  void _handleStationIdUpdate(String? getstationId) {
    if (mounted) {
      setState(() {
        stationId = getstationId;
        isLoading = true;
      });
      _fetchWeatherData();
    }
  }

  Future<void> _fetchWeatherData() async {
    data = await ExpTech().getMeteorStation(stationId!);
    setState(() {
      windDirection = data!.windDirection.reversed.toList();
      weatherData = {
        'temperature': data!.temperature.reversed.toList(),
        'wind_speed': data!.windSpeed.reversed.toList(),
        'precipitation': data!.precipitation.reversed.toList(),
        'humidity': data!.humidity.reversed.toList(),
        'pressure': data!.pressure.reversed.toList(),
        'time': data!.time.reversed.toList().map((item) => double.tryParse(item) ?? 0).toList(),
      };
      isLoading = false;
    });
  }

  Map<String, String> get dataTypeToChineseMap {
    return {
      'temperature': context.i18n.temperature_monitor,
      'wind_speed': context.i18n.wind_direction_and_speed_monitor,
      'precipitation': context.i18n.precipitation_monitor,
      'humidity': context.i18n.humidity_monitor,
      'pressure': context.i18n.pressure_monitor,
    };
  }

  final Map<String, String> units = {
    'temperature': '°C',
    'wind_speed': 'm/s',
    'precipitation': 'mm',
    'humidity': '%',
    'pressure': 'hPa',
  };

  List<Color> getDataTypeColor(String dataType) {
    switch (dataType) {
      case 'temperature':
        return [Colors.deepOrangeAccent, Colors.orangeAccent];
      case 'wind_speed':
        return [Colors.green, Colors.blue];
      case 'precipitation':
        return [Colors.blue, Colors.blue];
      case 'humidity':
        return [Colors.blueAccent, Colors.greenAccent];
      case 'pressure':
        return [Colors.purple, Colors.purple];
      default:
        return [Colors.grey, Colors.grey];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onClose, tooltip: 'Back'),
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data?.station.county ?? ""}${data?.station.name ?? ""}',
                style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                stationId!,
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          actions: [_buildDataTypeSelector(), const SizedBox(width: 16)],
        ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary)),
            ),
          )
        else
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildHeader(), const SizedBox(height: 16), _buildChart()],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final String displayValue =
        touchedIndex != -1
            ? '${DateFormat('MM/dd HH時').format(DateTime.fromMillisecondsSinceEpoch(weatherData['time']![touchedIndex].toInt()))}   ${weatherData[selectedDataType]![touchedIndex]}${units[selectedDataType]}'
            : '${context.i18n.map_average}   ${_calculate24HourAverage()}${units[selectedDataType]}';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.i18n.hours_24_trend(dataTypeToChineseMap[selectedDataType].toString()),
                  style: context.theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  displayValue,
                  style: context.theme.textTheme.titleSmall?.copyWith(
                    color: getDataTypeColor(selectedDataType!)[0],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (selectedDataType == 'wind_speed' &&
                touchedIndex != -1 &&
                weatherData[selectedDataType]![touchedIndex] != 0)
              Transform.rotate(
                angle: (windDirection[touchedIndex] + 180) % 360 * 3.14159 / 180,
                child: Icon(Icons.arrow_upward, color: getDataTypeColor(selectedDataType!)[0], size: 48),
              ),
          ],
        ),
      ),
    );
  }

  String _calculate24HourAverage() {
    final List<double> validData = weatherData[selectedDataType]!.where((value) => value != -99).toList();
    if (validData.isEmpty) return 'N/A';
    final double sum = validData.reduce((a, b) => a + b);
    return (sum / validData.length).toStringAsFixed(1);
  }

  Widget _buildChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: selectedDataType == 'precipitation' ? _buildBarChart() : _buildLineChart(),
            ),
            const SizedBox(height: 8),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final List<Color> lineColor = getDataTypeColor(selectedDataType!);
    final List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final bool invalid = weatherData[selectedDataType]?.every((value) => value == -99) ?? true;

    if (invalid) {
      return Center(child: Text(context.i18n.map_no_data));
    }

    for (int i = 0; i < weatherData[selectedDataType]!.length; i++) {
      if (weatherData[selectedDataType]![i] == -99) {
        spots.add(FlSpot.nullSpot);
      } else {
        final double value = weatherData[selectedDataType]![i];
        spots.add(FlSpot(i.toDouble(), value));
        minY = min(minY, value);
        maxY = max(maxY, value);
      }
    }

    double interval;
    double startY;
    double endY;

    switch (selectedDataType) {
      case 'temperature':
        interval = 3;
        startY = (minY / interval).floor() * interval;
        endY = (maxY / interval).ceil() * interval;
      case 'wind_speed':
        interval = 1;
        startY = minY.floor().toDouble();
        endY = maxY.ceil().toDouble();
      case 'humidity':
        interval = 20;
        startY = 0;
        endY = 100;
      case 'pressure':
        interval = 15;
        startY = (minY / interval).floor() * interval;
        endY = (maxY / interval).ceil() * interval;
      default:
        interval = 1;
        startY = minY.floor().toDouble();
        endY = maxY.ceil().toDouble();
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < weatherData['time']!.length) {
                  final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(weatherData['time']![index].toInt());
                  return Text(
                    DateFormat(context.i18n.map_hh_time).format(dateTime),
                    style: const TextStyle(fontSize: 10),
                  );
                } else {
                  return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value >= startY && value <= endY && (value % interval).abs() < 0.001) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                } else {
                  return const Text('');
                }
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: true),
        minY: startY,
        maxY: endY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor[0],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor[0].withValues(alpha: 0.3),
              gradient: LinearGradient(
                colors: [lineColor[0].withValues(alpha: 0.8), lineColor[1].withValues(alpha: 0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            setState(() {
              if (event is FlPanEndEvent || event is FlTapUpEvent || event is FlLongPressEnd) {
                touchedIndex = -1;
              } else if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
                touchedIndex = touchResponse.lineBarSpots![0].x.toInt();
              }
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return List.filled(touchedBarSpots.length, null);
            },
          ),
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                const FlLine(color: Colors.white, dashArray: [5, 5]),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(radius: 3, color: Colors.white, strokeWidth: 2, strokeColor: Colors.grey);
                  },
                ),
              );
            }).toList();
          },
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: double.parse(_calculate24HourAverage()),
              color: Colors.grey,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final Color barColor = getDataTypeColor(selectedDataType!)[0];
    final Color abnormalColor = Colors.red.withValues(alpha: 0.3);

    final bool invalid = weatherData[selectedDataType]?.every((value) => value == -99) ?? true;

    if (invalid) {
      return Center(child: Text(context.i18n.map_no_data));
    }

    final double maxRainfall = weatherData[selectedDataType]!
        .where((value) => value != -99)
        .fold(0, (max, value) => value > max ? value : max);

    final double interval = _calculateDynamicInterval(maxRainfall);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: BackgroundPainter(
            data: weatherData[selectedDataType]!,
            abnormalColor: abnormalColor,
            chartAreaSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index % 3 == 0 && index >= 0 && index < weatherData['time']!.length) {
                        final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                          weatherData['time']![index].toInt(),
                        );
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            DateFormat(context.i18n.map_hh_time).format(dateTime),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      } else {
                        return SideTitleWidget(meta: meta, child: const Text(''));
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value % interval < 0.001) {
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                      } else {
                        return const Text('');
                      }
                    },
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              borderData: FlBorderData(show: true),
              barGroups:
                  weatherData[selectedDataType]!
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value == -99 ? 0 : entry.value,
                              color: touchedIndex != -1 && touchedIndex != entry.key ? Colors.grey : barColor,
                              width: 3,
                            ),
                          ],
                        ),
                      )
                      .toList(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => null),
                touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                  setState(() {
                    if (event is FlPanEndEvent || event is FlTapUpEvent || event is FlLongPressEnd) {
                      touchedIndex = -1;
                    } else if (touchResponse?.spot != null) {
                      touchedIndex = touchResponse!.spot!.touchedBarGroupIndex;
                    }
                  });
                },
              ),
              maxY: (maxRainfall / interval).ceil() * interval,
              minY: 0,
              backgroundColor: Colors.transparent,
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: double.parse(_calculate24HourAverage()),
                    color: Colors.grey,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateDynamicInterval(double maxValue) {
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 50) return 5;
    if (maxValue <= 100) return 10;
    return 20;
  }

  Widget _buildDataTypeSelector() {
    final tempItems = <DropdownMenuItem<String>>[];

    for (final value in weatherData.keys) {
      final label = dataTypeToChineseMap[value];
      if (label != null) {
        tempItems.add(
          DropdownMenuItem<String>(
            value: value,
            child: Text(label, style: TextStyle(color: context.colors.onSecondaryContainer, fontSize: 14)),
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: context.colors.secondaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDataType,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedDataType = newValue;
                touchedIndex = -1;
              });
            }
          },
          items: tempItems,
          icon: Icon(Icons.arrow_drop_down, color: context.colors.onSecondaryContainer, size: 20),
          dropdownColor: context.colors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Row(
          children: [
            Container(width: 20, height: 3, color: getDataTypeColor(selectedDataType!)[0]),
            const SizedBox(width: 8),
            Text(dataTypeToChineseMap[selectedDataType]!),
          ],
        ),
        const SizedBox(width: 15),
        Row(
          children: [
            Container(
              width: 20,
              height: 1,
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
            ),
            const SizedBox(width: 8),
            Text(context.i18n.map_average),
          ],
        ),
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final List<double> data;
  final Color abnormalColor;
  final Size chartAreaSize;

  BackgroundPainter({required this.data, required this.abnormalColor, required this.chartAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = abnormalColor
          ..style = PaintingStyle.fill;

    const double leftPadding = 55;
    const double bottomPadding = 30;
    const double topPadding = 0;
    const double rightPadding = 10;

    final double chartWidth = chartAreaSize.width - leftPadding - rightPadding;
    final double chartHeight = chartAreaSize.height - bottomPadding - topPadding;

    final barWidth = chartWidth / data.length;

    for (int i = 0; i < data.length; i++) {
      if (data[i] == -99) {
        final rect = Rect.fromLTWH(leftPadding + i * barWidth, topPadding, barWidth, chartHeight);
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
