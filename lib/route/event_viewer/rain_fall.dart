import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdvancedWeatherChart extends StatefulWidget {
  const AdvancedWeatherChart({Key? key}) : super(key: key);

  @override
  State<AdvancedWeatherChart> createState() => _AdvancedWeatherChartState();
}

class _AdvancedWeatherChartState extends State<AdvancedWeatherChart> {
  String selectedDataType = '溫度';
  int touchedIndex = -1;

  final Map<String, List<double>> weatherData = {
    '溫度': [22, 23, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 16, 18, 20, 22, 24, 25, 26, 25, 24, 23, 22],
    '風速': [5, 6, 7, 8, 7, 6, 5, 4, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 4],
    '降水': [0, 0.5, 1.2, 0.8, 0.3, 0, 0, 0, 0.1, 0.4, 0.2, 0, 0, 0, 0.1, 0.3, 0.5, 0.7, 0.4, 0.2, 0.1, 0, 0, 0],
    '濕度': [65, 67, 70, 72, 75, 73, 70, 68, 65, 63, 60, 58, 55, 53, 50, 52, 55, 58, 60, 63, 65, 68, 70, 72],
    '氣壓': [1013, 1012, 1011, 1010, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1016, 1015, 1014, 1013, 1012, 1011, 1010, 1009, 1010, 1011, 1012],
    '風向': [0, 45, 90, 135, 180, 225, 270, 315, 0, 45, 90, 135, 180, 225, 270, 315, 0, 45, 90, 135, 180, 225, 270, 315],
  };

  final Map<String, String> units = {
    '溫度': '°C',
    '風速': 'm/s',
    '降水': 'mm',
    '濕度': '%',
    '氣壓': 'hPa',
    '風向': '°',
  };

  Color getDataTypeColor(String dataType) {
    switch (dataType) {
      case '溫度':
        return Colors.red;
      case '風速':
      case '風向':
        return Colors.orange;
      case '降水':
        return Colors.blue;
      case '濕度':
        return Colors.purple;
      case '氣壓':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('天氣趨勢圖'),
        actions: [_buildDataTypeSelector()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildChart(),
              const SizedBox(height: 24),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String displayValue = touchedIndex != -1
        ? '${touchedIndex}時: ${weatherData[selectedDataType]![touchedIndex]}${units[selectedDataType]}'
        : '24小時平均: ${_calculate24HourAverage()}${units[selectedDataType]}';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '24小時$selectedDataType趨勢',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              displayValue,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
    if (selectedDataType == '風向') {
      return ''; // 風向不計算平均
    }
    double sum = weatherData[selectedDataType]!.reduce((a, b) => a + b);
    return (sum / 24).toStringAsFixed(1);
  }

  Widget _buildChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: selectedDataType == '降水'
              ? _buildBarChart()
              : selectedDataType == '風向'
              ? _buildWindDirectionChart()
              : _buildLineChart(),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    Color lineColor = getDataTypeColor(selectedDataType);
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}時'),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: weatherData[selectedDataType]!
                .asMap()
                .entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                .toList(),
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
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
              } else if (touchResponse?.lineBarSpots != null &&
                  touchResponse!.lineBarSpots!.isNotEmpty) {
                touchedIndex = touchResponse.lineBarSpots![0].x.toInt();
              }
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  '${flSpot.y}${units[selectedDataType]}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: weatherData[selectedDataType]!.reduce((a, b) => a + b) / 24,
              color: Colors.black45,
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
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}時'),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: weatherData['降水']!
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
          x: entry.key,
          barRods: [BarChartRodData(toY: entry.value, color: barColor)],
        ))
            .toList(),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
            setState(() {
              if (event is FlPanEndEvent || event is FlTapUpEvent || event is FlLongPressEnd) {
                touchedIndex = -1;
              } else if (touchResponse?.spot != null) {
                touchedIndex = touchResponse!.spot!.touchedBarGroupIndex;
              }
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY}${units['降水']}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: weatherData['降水']!.reduce((a, b) => a + b) / 24,
              color: Colors.black45,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindDirectionChart() {
    // 這裡應該實現風向圖表，可能需要使用自定義繪製或其他圖表庫
    // 作為占位符，我們返回一個簡單的文本
    return const Center(child: Text('風向圖表 - 需要自定義實現'));
  }

  Widget _buildDataTypeSelector() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      initialValue: selectedDataType,
      onSelected: (String value) {
        setState(() {
          selectedDataType = value;
          touchedIndex = -1;
        });
      },
      itemBuilder: (BuildContext context) => weatherData.keys
          .map((String choice) => PopupMenuItem<String>(
        value: choice,
        child: Text(choice),
      ))
          .toList(),
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
            Text('圖例', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 3,
                  color: getDataTypeColor(selectedDataType),
                ),
                const SizedBox(width: 8),
                Text(selectedDataType),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 1,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black45,
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