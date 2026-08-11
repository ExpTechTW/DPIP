import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the wind-chart crash
/// `tooltipItems and touchedSpots size should be same`.
///
/// The wind curve is drawn as per-bucket segment bars that **share their
/// boundary spots**, so one touch near a threshold crossing lands on two bars
/// at once and fl_chart hands the tooltip builder two spots. fl_chart
/// hard-requires one `LineTooltipItem` per touched spot — the chart used to
/// dedupe them (same x → same point), which shrank the list and threw in
/// `drawTouchTooltip`.
void main() {
  final colors = ThemeData.light().colorScheme;
  final textTheme = ThemeData.light().textTheme;
  String timeLabel(double x) => '${x.toInt()}h';
  int? directionAt(double _) => 45;
  Color accentAt(double _) => const Color(0xFF03A9F4);

  test('a shared-x touch keeps one item per touched spot (no dedupe)', () {
    // Two bars share the boundary spot at x=100 (the crash's precondition):
    // the touch hits both, so fl_chart passes two spots with the same x.
    final sharedBar = LineChartBarData(
      spots: const [FlSpot(100, 4.0), FlSpot(101, 5.0)],
    );
    final nextBar = LineChartBarData(
      spots: const [FlSpot(100, 4.0), FlSpot(102, 9.0)],
    );
    final items = windTooltipItems(
      touched: [
        LineBarSpot(sharedBar, 0, const FlSpot(100, 4.0)),
        LineBarSpot(nextBar, 1, const FlSpot(100, 4.0)),
      ],
      unit: 'm/s',
      timeLabel: timeLabel,
      directionAt: directionAt,
      accentAt: accentAt,
      colors: colors,
      textTheme: textTheme,
    );

    // Before the fix the dedupe collapsed the two same-x spots into one item
    // and drawTouchTooltip threw "tooltipItems and touchedSpots size should be
    // same". The builder must return exactly one item per touched spot.
    expect(items.length, 2);
  });

  test('a single-spot touch still yields one item', () {
    final bar = LineChartBarData(spots: const [FlSpot(100, 4.0)]);
    final items = windTooltipItems(
      touched: [LineBarSpot(bar, 0, const FlSpot(100, 4.0))],
      unit: 'm/s',
      timeLabel: timeLabel,
      directionAt: directionAt,
      accentAt: accentAt,
      colors: colors,
      textTheme: textTheme,
    );

    expect(items.length, 1);
  });
}
