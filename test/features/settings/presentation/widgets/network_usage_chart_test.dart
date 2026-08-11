import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/features/settings/presentation/widgets/network_usage_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  HourUsage usage(int hour, {int down = 0, int saved = 0}) => HourUsage(
    hour: hour,
    down: down,
    saved: saved,
    hits: down > 0 ? 0 : 1,
    misses: down > 0 ? 1 : 0,
  );

  testWidgets('empty history shows a placeholder, no chart', (tester) async {
    await tester.pumpWidget(
      wrap(NetworkUsageChart(history: [for (var h = 0; h < 24; h++) usage(h)])),
    );

    expect(find.byType(BarChart), findsNothing);
    expect(find.textContaining('No traffic recorded yet'), findsOneWidget);
  });

  testWidgets('renders a stacked bar per hour with a legend', (tester) async {
    await tester.pumpWidget(
      wrap(
        NetworkUsageChart(
          history: [
            for (var h = 0; h < 24; h++) usage(h, down: 2048, saved: 1024),
          ],
        ),
      ),
    );

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Downloaded'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    // The chart is the data, not a blank stub: 24 groups with one rod each.
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final data = chart.data;
    expect(data.barGroups, hasLength(24));
    expect(data.barGroups.first.barRods, hasLength(1));
    expect(data.barGroups.first.barRods.first.rodStackItems, hasLength(2));
  });
}
