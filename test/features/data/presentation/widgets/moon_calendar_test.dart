/// The calendar and the timeline share one range. A day outside that range
/// must not select, and the month arrows must stop at the same ends.
library;

import 'package:dpip/features/data/presentation/widgets/moon_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a day inside the range selects, and next month is offered', (
    tester,
  ) async {
    DateTime? picked;
    DateTime? month;
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoonCalendar(
            month: DateTime.utc(2026, 4),
            selected: DateTime.utc(2026, 4, 8),
            today: DateTime.utc(2026, 4, 8),
            firstDay: DateTime.utc(2026, 4, 1),
            lastDay: DateTime.utc(2026, 5, 31),
            onMonthChanged: (value) => month = value,
            onDaySelected: (value) => picked = value,
            phaseAt: (_) => 0,
          ),
        ),
      ),
    );

    await tester.tap(find.text('15'));
    expect(picked, DateTime.utc(2026, 4, 15));

    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(month, DateTime.utc(2026, 5));
  });
}
