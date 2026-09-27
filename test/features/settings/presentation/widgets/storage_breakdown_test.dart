/// The Debug page's storage donut: proportions and the legend that explains
/// them.
///
/// The whole widget is a single early return away from drawing nothing —
/// `total <= 0` renders `SizedBox.shrink()`, which is correct before a scan
/// has run, but checking `slices.isEmpty` instead (an easy substitution that
/// reads almost the same) would make a report with a stale positive total and
/// no slices ship a blank donut with no explanation for why the page's
/// numbers do not match what Settings reports. The legend text is the whole
/// point of an English-only screenshot page, so [formatBytes] and the
/// percentage must actually match what the slice list says, not just look
/// plausible; and the fixed nine-colour palette must visibly wrap rather than
/// throw once a scan produces a tenth slice.
library;

import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/features/settings/presentation/widgets/storage_breakdown.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('a non-positive total draws nothing, even with slices present', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const StorageBreakdown(
          slices: [StorageSlice(label: 'Cache', bytes: 100)],
          total: 0,
        ),
      ),
    );

    expect(find.byType(PieChart), findsNothing);
    expect(find.text('Cache'), findsNothing);
  });

  testWidgets('each slice gets one legend row with its size and percent', (
    tester,
  ) async {
    const slices = [
      StorageSlice(label: 'ETag cache (SQLite)', bytes: 750 * 1024),
      StorageSlice(label: 'Caches', bytes: 250 * 1024),
    ];
    const total = 1000 * 1024;

    await tester.pumpWidget(
      _wrap(const StorageBreakdown(slices: slices, total: total)),
    );

    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('ETag cache (SQLite)'), findsOneWidget);
    expect(find.text('${formatBytes(750 * 1024)} · 75.0%'), findsOneWidget);
    expect(find.text('Caches'), findsOneWidget);
    expect(find.text('${formatBytes(250 * 1024)} · 25.0%'), findsOneWidget);

    final pie = tester.widget<PieChart>(find.byType(PieChart));
    expect(pie.data.sections, hasLength(2));
    expect(pie.data.sections[0].value, (750 * 1024).toDouble());
    expect(pie.data.sections[0].color, storageSliceColors[0]);
    expect(pie.data.sections[1].color, storageSliceColors[1]);
  });

  testWidgets('the slice palette wraps around past its length', (tester) async {
    final slices = [
      for (var i = 0; i < storageSliceColors.length + 1; i++)
        StorageSlice(label: 'slice $i', bytes: 10),
    ];
    final total = slices.length * 10;

    await tester.pumpWidget(
      _wrap(StorageBreakdown(slices: slices, total: total)),
    );

    final pie = tester.widget<PieChart>(find.byType(PieChart));
    expect(
      pie.data.sections.last.color,
      storageSliceColors[0],
      reason: 'index storageSliceColors.length wraps back to colour 0',
    );
  });
}
