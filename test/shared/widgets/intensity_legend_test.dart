/// The map legend is the only key for the station dots. A continuous bar that
/// drops the zero stop, or a discrete scale that forgets the 5/6 split, would
/// make a colour on the map mean a different intensity than the one printed
/// beside it.
library;

import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, IntensityLegend legend) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: legend)));
}

void main() {
  testWidgets('the realtime scale is one gradient labelled 7 down to 0', (
    tester,
  ) async {
    await _pump(tester, const IntensityLegend());
    for (final label in ['7', '6', '5', '4', '3', '2', '1', '0']) {
      expect(find.text(label), findsOneWidget);
    }
    final box = tester.widget<Container>(find.byType(Container));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    expect((decoration.gradient! as LinearGradient).colors.length, 71);
  });

  testWidgets(
    'the felt scale stacks 7 through 1 with the weak and strong split',
    (tester) async {
      await _pump(tester, const IntensityLegend(mode: IntensityLegendMode.eew));
      for (final label in ['7', '6⁺', '6⁻', '5⁺', '5⁻', '4', '3', '2', '1']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(Container), findsNWidgets(9));
    },
  );
}
