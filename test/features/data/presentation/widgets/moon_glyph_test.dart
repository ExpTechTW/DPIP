/// The glyph is the only phase mark a calendar cell can resolve. A new moon
/// must still occupy its square, and a later phase must repaint rather than
/// keep the first silhouette.
library;

import 'dart:math' as math;

import 'package:dpip/features/data/presentation/widgets/moon_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new and full moons both paint a square mark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: MoonGlyph(
            angle: 0,
            size: 24,
            lit: Colors.white,
            dark: Colors.black,
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(MoonGlyph),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(MoonGlyph)), const Size.square(24));

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: MoonGlyph(
            angle: math.pi,
            size: 24,
            lit: Colors.white,
            dark: Colors.black,
          ),
        ),
      ),
    );
    expect(find.byType(MoonGlyph), findsOneWidget);
  });
}
