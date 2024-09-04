import 'package:dpip/model/meteor_station.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:dpip/api/exptech.dart';

class AdvancedWeatherChart extends StatefulWidget {
  final String stationId;
  final VoidCallback onClose;

  const AdvancedWeatherChart({
    super.key,
    required this.stationId,
    required this.onClose,
  });

  @override
  State<AdvancedWeatherChart> createState() => _AdvancedWeatherChartState();
}

class _AdvancedWeatherChartState extends State<AdvancedWeatherChart> {
  String selectedDataType = 'temperature';
  int touchedIndex = -1;
  bool isLoading = true;
  Map<String, List<double>> weatherData = {};
  List<double> windDirection = [];
  MeteorStation? data;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    data = await ExpTech().getMeteorStation(widget.stationId);
    setState(() {
      windDirection = data!.windDirection.reversed.toList();
      weatherData = {
        'temperature': data!.temperature.reversed.toList(),
        'wind_speed': data!.windSpeed.reversed.toList(),
        'precipitation': data!.precipitation.reversed.toList(),
        'humidity': data!.humidity.reversed.toList(),
        'pressure': data!.pressure.reversed.toList(),
        'time': data!.time.reversed.toList().map((item) => double.tryParse(item.toString()) ?? 0).toList(),
      };
      isLoading = false;
    });
  }

  final Map<String, String> dataTypeToChineseMap = {
    'temperature': '溫度',
    'wind_speed': '風速',
    'precipitation': '降水',
    'humidity': '濕度',
    'pressure': '氣壓',
  };

  final Map<String, String> units = {
    'temperature': '°C',
    'wind_speed': 'm/s',
    'precipitation': 'mm',
    'humidity': '%',
    'pressure': 'hPa',
  };

  Color getDataTypeColor(String dataType) {
    switch (dataType) {
      case 'temperature':
        return Colors.red;
      case 'wind_speed':
        return Colors.orange;
      case 'precipitation':
        return Colors.blue;
      case 'humidity':
        return Colors.purple;
      case 'pressure':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
          automaticallyImplyLeading: false,
          title: Text('${widget.stationId} ${data?.station.county ?? ""}${data?.station.name ?? ""}'),
          actions: [_buildDataTypeSelector(), const SizedBox(width: 8)],
        ),
        if (isLoading)
          const CircularProgressIndicator()
        else
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildChart(),
                const SizedBox(height: 16),
                _buildLegend(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    String displayValue = touchedIndex != -1
        ? '${DateFormat('MM/dd HH時').format(DateTime.fromMillisecondsSinceEpoch(weatherData['time']![touchedIndex].toInt()))}   ${weatherData[selectedDataType]![touchedIndex]}${units[selectedDataType]}'
        : '24小時平均   ${_calculate24HourAverage()}${units[selectedDataType]}';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '24小時${dataTypeToChineseMap[selectedDataType]}趨勢',
                  style: context.theme.textTheme.titleMedium,
                ),
                if (selectedDataType == 'wind_speed')
                  Transform.rotate(
                    angle: (windDirection[touchedIndex != -1 ? touchedIndex : 0] + 180) % 360 * 3.14159 / 180,
                    child: Icon(Icons.arrow_upward, color: getDataTypeColor(selectedDataType)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayValue,
              style: context.theme.textTheme.titleSmall?.copyWith(
                color: getDataTypeColor(selectedDataType),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculate24HourAverage() {
    List<double> validData = weatherData[selectedDataType]!.where((value) => value != -99).toList();
    if (validData.isEmpty) return 'N/A';
    double sum = validData.reduce((a, b) => a + b);
    return (sum / validData.length).toStringAsFixed(1);
  }

  Widget _buildChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: selectedDataType == 'precipitation' ? _buildBarChart() : _buildLineChart(),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    Color lineColor = getDataTypeColor(selectedDataType);
    List<FlSpot> spots = [];
    for (int i = 0; i < weatherData[selectedDataType]!.length; i++) {
      if (weatherData[selectedDataType]![i] == -99) {
        spots.add(FlSpot.nullSpot);
      } else {
        spots.add(FlSpot(i.toDouble(), weatherData[selectedDataType]![i]));
      }
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
                int index = value.toInt();
                if (index >= 0 && index < weatherData['time']!.length) {
                  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(weatherData['time']![index].toInt());
                  return Text(DateFormat('HH時').format(dateTime));
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
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.3),
              gradient: LinearGradient(
                colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)],
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
                const FlLine(
                  color: Colors.white,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.grey,
                    );
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
    Color barColor = getDataTypeColor(selectedDataType);
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index % 3 == 0 && index >= 0 && index < weatherData['time']!.length) {
                  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(weatherData['time']![index].toInt());
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('HH時').format(dateTime),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                } else {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: const Text(''),
                  );
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: weatherData[selectedDataType]!
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value == -99 ? 0 : entry.value,
                      color: touchedIndex != -1 && touchedIndex != entry.key ? Colors.grey : barColor,
                      width: 3,
                    )
                  ],
                ))
            .toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
          ),
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

  Widget _buildDataTypeSelector() {
    final tempItems = <DropdownMenuItem<String>>[];

    for (final value in weatherData.keys) {
      final label = dataTypeToChineseMap[value];
      if (label != null) {
        tempItems.add(
          DropdownMenuItem<String>(
            value: value,
            child: Text(
              label,
              style: TextStyle(
                color: context.colors.onSecondaryContainer,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.colors.secondaryContainer,
      ),
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
          icon: Icon(
            Icons.arrow_drop_down,
            color: context.colors.onSecondaryContainer,
            size: 20,
          ),
          dropdownColor: context.colors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('圖例', style: context.theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 3,
                  color: getDataTypeColor(selectedDataType),
                ),
                const SizedBox(width: 8),
                Text(dataTypeToChineseMap[selectedDataType]!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 1,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('24小時平均'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
