/// Every EEW card reads local intensity and the S-wave countdown through this
/// one tile. A label that loses its value, or an alert red that changes with
/// the theme, would make the same warning look calm on one screen and urgent
/// on another.
library;

import 'package:dpip/shared/widgets/eew_estimate_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the label over the value in the given colours', (
    tester,
  ) async {
    const background = Color(0xFFFFE082);
    const foreground = Color(0xFF1A1A1A);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EewEstimateTile(
            label: 'Local',
            value: '5⁻',
            background: background,
            foreground: foreground,
          ),
        ),
      ),
    );
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('5⁻'), findsOneWidget);
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((box.decoration as BoxDecoration).color, background);
    final value = tester.widget<Text>(find.text('5⁻'));
    expect(value.style?.color, foreground);
    expect(value.style?.fontWeight, FontWeight.w800);
  });

  test('alert red is a stable light-scheme error, not a theme lookup', () {
    final first = EewEstimateTile.alertRed();
    final second = EewEstimateTile.alertRed();
    expect(identical(first, second), isTrue);
    expect(first.a, greaterThan(0));
  });
}
