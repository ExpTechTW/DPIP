/// The radio's battery chart: what it plots, and what it refuses to imply.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/features/meshtastic/presentation/widgets/mesh_charts.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

MeshMetricSample _sample(int minute, {int? battery, double? voltage}) =>
    MeshMetricSample(
      at: DateTime.utc(2026, 8, 15, 10, minute),
      batteryPercent: battery,
      voltage: voltage,
    );

extension on MeshMetricSample {
  MeshMetricSample copyWithHour(int hour) => MeshMetricSample(
    at: DateTime.utc(2026, 8, 15, hour),
    batteryPercent: batteryPercent,
    voltage: voltage,
  );
}

void main() {
  testWidgets('nodes chart plots known and online', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshNodesChart(
          samples: [
            MeshMetricSample(
              at: DateTime.utc(2026, 8, 15, 10),
              nodesTotal: 42,
              nodesOnline: 17,
            ),
            MeshMetricSample(
              at: DateTime.utc(2026, 8, 15, 11),
              nodesTotal: 45,
              nodesOnline: 21,
            ),
          ],
        ),
      ),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('21'), findsWidgets); // current online + peak stat
  });

  testWidgets('traffic chart totals the day', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshTrafficChart(
          samples: [
            MeshMetricSample(
              at: DateTime.utc(2026, 8, 15, 10),
              rxPackets: 30,
              txPackets: 2,
            ),
            MeshMetricSample(
              at: DateTime.utc(2026, 8, 15, 11),
              rxPackets: 50,
              txPackets: 3,
            ),
          ],
        ),
      ),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('80'), findsOneWidget); // rx total
    expect(find.text('5'), findsOneWidget); // tx total
  });

  testWidgets('battery drain and time-left appear with a day of decline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [
            for (var hour = 0; hour < 12; hour++)
              _sample(
                0,
                battery: 96 - hour * 2,
                voltage: 4.1 - hour * 0.02,
              ).copyWithHour(hour),
          ],
        ),
      ),
    );
    // −2%/h over 12 h → the fit reports the slope and a ~48 h estimate
    // (96/2), which formats as days.
    expect(find.textContaining('-2.0%/h'), findsOneWidget);
    expect(find.textContaining('~'), findsOneWidget);
  });

  testWidgets('plots the day and shows the current volts', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [
            _sample(0, battery: 92, voltage: 4.11),
            _sample(10, battery: 90, voltage: 4.08),
            _sample(20, battery: 87, voltage: 4.03),
          ],
        ),
      ),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    // The volts ride the legend: percent pins at 101 on external power, so
    // the voltage is the reading that shows a cell ageing.
    expect(find.text('4.03 V'), findsOneWidget);
  });

  testWidgets('external power caps the line at full, not 101', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [_sample(0, battery: 101), _sample(10, battery: 101)],
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(spots.every((s) => s.y <= 100), isTrue);
    expect(find.text('100%'), findsWidgets);
  });

  testWidgets('one sample is no history, not a chart', (tester) async {
    await tester.pumpWidget(
      _wrap(MeshBatteryChart(samples: [_sample(0, battery: 88)])),
    );
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('samples with no battery reading break the line', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [
            _sample(0, battery: 92),
            _sample(5, battery: 91),
            _sample(10), // utilization-only sample — a gap
            _sample(15, battery: 90),
            _sample(20, battery: 89),
          ],
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    // Two runs of readings, not one line bridged across the gap.
    expect(chart.data.lineBarsData, hasLength(2));
    expect(chart.data.lineBarsData[0].spots, hasLength(2));
    expect(chart.data.lineBarsData[1].spots, hasLength(2));
  });

  testWidgets('a single-point run draws no line at all', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [
            _sample(0, battery: 92),
            _sample(5), // gap
            _sample(10, battery: 91),
          ],
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    // Every run is one point — there is no line to draw, and inventing one
    // would be exactly the false continuity this chart refuses.
    expect(chart.data.lineBarsData, isEmpty);
  });
}
