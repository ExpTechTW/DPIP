/// The radio's free counters, one full-width chart each.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/features/meshtastic/presentation/widgets/mesh_chart_section.dart';
import 'package:dpip/features/meshtastic/presentation/widgets/mesh_ratio_chart.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

MeshMetricSample _sample(
  DateTime at, {
  int? rx,
  int? rxBad,
  int? tx,
  int? dupe,
  int? relay,
  int? relayCancel,
}) => MeshMetricSample(
  at: at,
  lsRx: rx,
  lsRxBad: rxBad,
  lsTx: tx,
  lsRxDupe: dupe,
  lsTxRelay: relay,
  lsTxRelayCancel: relayCancel,
);

void main() {
  final base = DateTime.utc(2026, 8, 16, 10);

  testWidgets('each slice is its own ratio, not a running total', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MeshRatioChart(
          ratio: MeshRatio.duplicates,
          samples: [
            _sample(base, rx: 100, dupe: 10),
            // A spike in this slice must show as a spike, not be diluted by
            // the hour before it.
            _sample(base.add(const Duration(minutes: 15)), rx: 100, dupe: 60),
          ],
        ),
      ),
    );
    final spots = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .single
        .spots;
    expect(spots.map((s) => s.y), [10, 60]);
  });

  testWidgets('a slice too small to mean anything is a gap', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MeshRatioChart(
          ratio: MeshRatio.errors,
          samples: [
            _sample(base, rx: 100, rxBad: 2),
            // Three packets can only be 0/33/67/100% — a cliff where nothing
            // happened.
            _sample(base.add(const Duration(minutes: 15)), rx: 2, rxBad: 1),
            _sample(base.add(const Duration(minutes: 30)), rx: 100, rxBad: 2),
          ],
        ),
      ),
    );
    final bars = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData;
    // The noisy slice breaks the line rather than spiking it to 33%.
    expect(
      bars.expand((b) => b.spots).map((s) => s.y),
      everyElement(lessThan(5)),
    );
  });

  testWidgets('an absent counter beside a present one is a zero', (
    tester,
  ) async {
    // lsRxBad missing while lsRx is present means "none bad", not "unknown".
    await tester.pumpWidget(
      _wrap(
        MeshRatioChart(
          ratio: MeshRatio.errors,
          samples: [
            _sample(base, rx: 100),
            _sample(base.add(const Duration(minutes: 15)), rx: 100),
          ],
        ),
      ),
    );
    expect(find.byType(LineChart), findsOneWidget);
  });

  group('the range switch', () {
    testWidgets('windows back from now, not from the newest sample', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 8, 16, 20);
      var handed = <MeshMetricSample>[];
      await tester.pumpWidget(
        _wrap(
          MeshChartSection(
            title: 'x',
            now: () => now,
            initialRange: MeshChartRange.hour,
            samples: [
              // Three hours stale: the radio has been away.
              _sample(now.subtract(const Duration(hours: 3)), rx: 100, dupe: 5),
              _sample(now.subtract(const Duration(hours: 2)), rx: 100, dupe: 5),
            ],
            builder: (windowed) {
              handed = windowed;
              return const SizedBox();
            },
          ),
        ),
      );
      // Nothing in the last hour, and that is the honest answer — showing the
      // newest hour of data instead would present 3-hour-old readings as now.
      expect(handed, isEmpty);
    });

    testWidgets('tapping a window narrows what the chart is handed', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 8, 16, 20);
      var handed = <MeshMetricSample>[];
      await tester.pumpWidget(
        _wrap(
          MeshChartSection(
            title: 'x',
            now: () => now,
            samples: [
              for (var h = 20; h >= 0; h--)
                _sample(now.subtract(Duration(hours: h)), rx: 100, dupe: 5),
            ],
            builder: (windowed) {
              handed = windowed;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(handed, hasLength(21), reason: '24h is the default');

      await tester.tap(find.text('6h'));
      await tester.pumpAndSettle();
      expect(handed, hasLength(7));

      await tester.tap(find.text('1h'));
      await tester.pumpAndSettle();
      expect(handed, hasLength(2));
    });
  });
}
