import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_deck.dart';
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

  testWidgets('the cloud deck re-renders at most twelve times a second', (
    tester,
  ) async {
    // A full-size sky makes one pump slower than the deck period, so a
    // correct 12 fps clock and a once-per-frame clock count the same. A
    // small surface keeps the pump well under a period.
    tester.view.physicalSize = const Size(240, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpLoaded(
      tester,
      const MaterialApp(home: WeatherSkyBackground(active: true)),
    );
    // Let the opening raster land so the measurement window is the steady
    // clock, not the first bake.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump();
    debugResetSkyDeckRenders();

    final clock = Stopwatch()..start();
    var pumps = 0;
    // Wall time has to pass: the deck's clock is a Stopwatch, and a burst of
    // pumps would otherwise finish inside one period.
    while (clock.elapsedMilliseconds < 500) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 16)),
      );
      pumps++;
    }
    final elapsed = clock.elapsedMilliseconds / 1000.0;
    // One extra for a bake that was already due at the window's first tick,
    // and one for a raster that finishes just inside the window.
    final cap = (elapsed / kSkyDeckPeriod).ceil() + 2;
    expect(pumps, greaterThan(8));
    expect(debugSkyDeckRenders, greaterThanOrEqualTo(1));
    expect(debugSkyDeckRenders, lessThan(pumps));
    expect(debugSkyDeckRenders, lessThanOrEqualTo(cap));
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
