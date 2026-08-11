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

  /// The chart built for [usage] bars with real traffic.
  Future<BarChartData> pumpChart(WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        NetworkUsageChart(
          history: [
            for (var h = 0; h < 24; h++) usage(h, down: 2048, saved: 1024),
          ],
        ),
      ),
    );
    return tester.widget<BarChart>(find.byType(BarChart)).data;
  }

  /// Taps one [SegmentedButton] segment by its label.
  Future<void> tapSegment(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<NetworkChartMode>),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty history shows a placeholder, no chart', (tester) async {
    await tester.pumpWidget(
      wrap(NetworkUsageChart(history: [for (var h = 0; h < 24; h++) usage(h)])),
    );

    expect(find.byType(BarChart), findsNothing);
    expect(find.textContaining('No traffic recorded yet'), findsOneWidget);
  });

  testWidgets('defaults to stacked red download over green saved', (
    tester,
  ) async {
    final data = await pumpChart(tester);

    expect(find.text('Downloaded'), findsOneWidget);
    // "Saved" appears twice: the legend dot row and the switch segment.
    expect(find.text('Saved'), findsNWidgets(2));

    // The chart is the data, not a blank stub: 24 groups with one rod each.
    expect(data.barGroups, hasLength(24));
    final stacks = data.barGroups.first.barRods.first.rodStackItems;
    expect(stacks, hasLength(2));
    expect(stacks[0].color, const Color(0xFFE53935));
    expect(stacks[1].color, const Color(0xFF66BB6A));
  });

  testWidgets('switching to Download plots only the red series', (
    tester,
  ) async {
    await pumpChart(tester);
    await tapSegment(tester, 'Download');

    final stacks = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups
        .first
        .barRods
        .first
        .rodStackItems;
    expect(stacks, hasLength(1));
    expect(stacks.single.color, const Color(0xFFE53935));
    // The green legend dot row is gone; only the switch segment still says it.
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('switching to Saved plots only the green series', (tester) async {
    await pumpChart(tester);
    await tapSegment(tester, 'Saved');

    final stacks = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups
        .first
        .barRods
        .first
        .rodStackItems;
    expect(stacks, hasLength(1));
    expect(stacks.single.color, const Color(0xFF66BB6A));
    expect(find.text('Downloaded'), findsNothing);
  });
}
