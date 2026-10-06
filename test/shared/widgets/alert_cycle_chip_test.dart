/// The monitor and the report replay both cycle one alert card at a time.
/// A chip that prints the wrong position would send the next tap to a
/// different event than the one the user thinks they are on.
library;

import 'package:dpip/shared/widgets/alert_cycle_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prints the 1-based position over the total', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AlertCycleChip(position: 2, count: 5)),
      ),
    );
    expect(find.text('2/5'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });
}
