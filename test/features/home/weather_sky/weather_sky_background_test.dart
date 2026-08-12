import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The animated sky must not repaint when it is stopped: the scroll-blur
/// subtree above it rebuilds on every scroll tick while the sky is frozen
/// underneath, and a fresh painter instance every tick would re-render the
/// whole full-screen shader stack for no visible change.
void main() {
  testWidgets('a stopped backdrop reuses its painter across rebuilds', (
    tester,
  ) async {
    await pumpLoaded(
      tester,
      const MaterialApp(home: WeatherSkyBackground(active: false)),
    );

    CustomPainter painterOf() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(WeatherSkyBackground),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;

    final first = painterOf();
    // An identical rebuild of the widget (what a scroll tick above produces)
    // must not swap the painter.
    await tester.pumpWidget(
      const MaterialApp(home: WeatherSkyBackground(active: false)),
    );
    await tester.pump();
    expect(identical(first, painterOf()), isTrue);

    // Re-activating the animation advances the clock, so the next frame gets a
    // fresh painter again.
    await tester.pumpWidget(
      const MaterialApp(home: WeatherSkyBackground(active: true)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(identical(first, painterOf()), isFalse);
  });
}

/// Pumps [widget] and waits for the backdrop's shader/sprite load — a real
/// async load that the fake test clock cannot advance on its own.
Future<void> pumpLoaded(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  final sky = find.byType(WeatherSkyBackground);
  final paint = find.descendant(of: sky, matching: find.byType(CustomPaint));
  for (var i = 0; i < 40 && tester.widgetList(paint).isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  expect(paint, findsOneWidget, reason: 'the sky shaders should load');
}
