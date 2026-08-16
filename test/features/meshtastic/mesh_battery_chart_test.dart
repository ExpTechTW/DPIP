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

  testWidgets('a row about something else is not a hole', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [
            _sample(0, battery: 92),
            _sample(5, battery: 91),
            // A row written because the radio's counter block arrived. It has
            // nothing to say about the battery, which is not the same as the
            // battery having gone unread — the readings either side are five
            // minutes apart as usual.
            _sample(10),
            _sample(15, battery: 90),
            _sample(20, battery: 89),
          ],
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData, hasLength(1));
    expect(chart.data.lineBarsData.single.spots, hasLength(4));
  });

  testWidgets('a real absence still breaks it', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [
            _sample(0, battery: 92),
            _sample(5, battery: 91),
            _sample(10, battery: 90),
            // Six hours where the radio said nothing at all.
            _sample(370, battery: 60),
            _sample(375, battery: 59),
          ],
        ),
      ),
    );
    expect(
      tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData,
      hasLength(2),
    );
  });

  testWidgets('a lone reading is not invented into a line', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshBatteryChart(
          samples: [
            for (var m = 0; m <= 20; m += 5) _sample(m, battery: 92),
            // Stranded between two outages: real, but not a line.
            _sample(400, battery: 80),
            for (var m = 800; m <= 815; m += 5) _sample(m, battery: 70),
          ],
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    // Two two-point runs; the lone reading in the middle draws nothing, which
    // is exactly the false continuity this chart refuses.
    expect(chart.data.lineBarsData, hasLength(2));
  });

  group('a hole is a hole, in every chart', () {
    // A genuine outage between two runs: the radio was away, so there are no
    // rows at all for those hours. Each chart must hand fl_chart two bars —
    // one per continuous run — rather than one that runs straight across the
    // time nothing was reported.
    List<MeshMetricSample> gapped(
      MeshMetricSample Function(int hour) reading,
    ) => [reading(1), reading(2), reading(3), reading(15), reading(16)];

    int runs(WidgetTester tester) => tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .length;

    testWidgets('utilization', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshUtilizationChart(
            samples: gapped(
              (h) => MeshMetricSample(
                at: DateTime.utc(2026, 8, 15, h),
                channelUtilization: 5,
                airUtilTx: 2,
              ),
            ),
          ),
        ),
      );
      // Two series x two runs each.
      expect(runs(tester), 4);
    });

    testWidgets('nodes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshNodesChart(
            samples: gapped(
              (h) => MeshMetricSample(
                at: DateTime.utc(2026, 8, 15, h),
                nodesTotal: 40,
                nodesOnline: 12,
              ),
            ),
          ),
        ),
      );
      expect(runs(tester), 4);
    });

    testWidgets('traffic', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshTrafficChart(
            samples: gapped(
              (h) => MeshMetricSample(
                at: DateTime.utc(2026, 8, 15, h),
                rxPackets: 30,
                txPackets: 2,
              ),
            ),
          ),
        ),
      );
      expect(runs(tester), 4);
    });
  });

  testWidgets('a hole with no rows in it still breaks the line', (
    tester,
  ) async {
    // The case a null-only rule cannot see: the recorder writes a row when
    // there is something to record, so an outage leaves no rows at all — the
    // two halves of the day sit adjacent with nothing null between them.
    await tester.pumpWidget(
      _wrap(
        MeshUtilizationChart(
          samples: [
            for (final m in [0, 1, 2, 360, 361, 362])
              MeshMetricSample(
                at: DateTime.utc(2026, 8, 15, 10).add(Duration(minutes: m)),
                channelUtilization: 5,
              ),
          ],
        ),
      ),
    );
    final bars = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData;
    expect(bars, hasLength(2), reason: 'six hours of silence is not a line');
  });

  group('the slope', () {
    MeshMetricSample at(int minute, int battery) => MeshMetricSample(
      at: DateTime.utc(2026, 8, 15, 6).add(Duration(minutes: minute)),
      batteryPercent: battery,
    );

    testWidgets('follows the recent trend, not the whole day', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshBatteryChart(
            samples: [
              // Six hours of hard draining, long over.
              for (var m = 0; m < 360; m += 10) at(m, 100 - m ~/ 10),
              // Then an hour flat — a pack on external power, or simply idle.
              for (var m = 360; m < 420; m++) at(m, 64),
            ],
          ),
        ),
      );
      // A fit over everything would still be predicting a death that stopped
      // approaching an hour ago.
      expect(find.textContaining('%/h'), findsNothing);
      expect(find.textContaining('stable'), findsOneWidget);
    });

    testWidgets('a charging pack says when it will be full', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshBatteryChart(
            samples: [
              // +10%/h for an hour, currently at 50%.
              for (var m = 0; m <= 60; m++) at(m, 40 + (m ~/ 6)),
            ],
          ),
        ),
      );
      expect(find.textContaining('charging'), findsOneWidget);
      expect(find.textContaining('+10.0%/h'), findsOneWidget);
      // 50 points to go at 10%/h.
      expect(find.textContaining('~5h'), findsOneWidget);
    });

    testWidgets('never reaches back across a hole to fill the window', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MeshBatteryChart(
            samples: [
              // Yesterday: a steep, long-finished drain.
              for (var m = 0; m < 600; m += 10) at(m, 100 - m ~/ 10),
              // Then nothing for a day, and five flat readings since.
              for (var m = 2000; m < 2005; m++) at(m, 40),
            ],
          ),
        ),
      );
      // Sixty *points* would swallow the whole outage and fit a line through
      // an hour of now and an hour of yesterday. Only the recent readings
      // count, and five minutes of them is not a slope.
      expect(find.textContaining('%/h'), findsNothing);
    });

    testWidgets('a draining pack says how long is left', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshBatteryChart(
            samples: [for (var m = 0; m <= 60; m++) at(m, 60 - (m ~/ 6))],
          ),
        ),
      );
      expect(find.textContaining('-10.0%/h'), findsOneWidget);
      // 50% left at 10%/h.
      expect(find.textContaining('~5h'), findsOneWidget);
    });
  });
}
