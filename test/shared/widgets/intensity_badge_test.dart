/// Numbered reports are a solid badge and 小區域 reports are a hollow ring. If
/// the ring fills in, or the ink on a dark fill stays black, the catalogue
/// and the detail header stop agreeing on which report kind the user is
/// reading.
library;

import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, IntensityBadge badge) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: badge)),
    ),
  );
}

void main() {
  testWidgets('a dark fill uses white ink and a light fill uses dark ink', (
    tester,
  ) async {
    await _pump(
      tester,
      const IntensityBadge(label: '5⁻', color: Color(0xFF111111), size: 64),
    );
    var text = tester.widget<Text>(find.text('5⁻'));
    expect(text.style?.color, Colors.white);
    expect(text.style?.fontSize, isNotNull);
    final filled = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((filled.decoration as BoxDecoration).color, const Color(0xFF111111));
    expect((filled.decoration as BoxDecoration).border, isNull);
    final box = tester.getSize(find.byType(IntensityBadge));
    expect(box, const Size(64, 64));

    await _pump(
      tester,
      const IntensityBadge(label: '1', color: Color(0xFFF5F5F5)),
    );
    text = tester.widget<Text>(find.text('1'));
    expect(text.style?.color, Colors.black87);
  });

  testWidgets('outlined draws a ring and leaves the label to the surface', (
    tester,
  ) async {
    await _pump(
      tester,
      const IntensityBadge(
        label: '3',
        color: Color(0xFF2E7D32),
        outlined: true,
      ),
    );
    final decoration =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
            as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    expect(decoration.border?.top.color, const Color(0xFF2E7D32));
    expect(decoration.border?.top.width, 3);
    final text = tester.widget<Text>(find.text('3'));
    expect(text.style?.color, isNot(Colors.white));
    expect(text.style?.color, isNot(Colors.black87));
  });
}
