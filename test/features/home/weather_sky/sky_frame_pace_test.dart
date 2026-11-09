import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_frame_pace.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_background.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sky's repaint budget, and the fact that the gap between paints does
/// not schedule a Flutter frame. A timer wakes the ticker; until it fires
/// the engine is not asked for a vsync.
void main() {
  const strike = LightningFrame(age: 0.2, flash: 1, bolt: 1, seed: 2);
  final below = kSkyPrecipitationThreshold / 2;

  group('skyFrameInterval', () {
    test('rain or a strike paints every 16 ms', () {
      expect(
        skyFrameInterval(
          rain: kSkyPrecipitationThreshold,
          snow: 0,
          lightning: LightningFrame.none,
        ),
        const Duration(milliseconds: 16),
      );
      expect(
        skyFrameInterval(rain: 0, snow: 0, lightning: strike),
        const Duration(milliseconds: 16),
      );
    });

    test('snow paints every 33 ms', () {
      // Rain under the painter's gate must not steal the fast budget.
      expect(
        skyFrameInterval(
          rain: below,
          snow: kSkyPrecipitationThreshold,
          lightning: LightningFrame.none,
        ),
        const Duration(milliseconds: 33),
      );
    });

    test('clouds, stars and sun paint every 66 ms', () {
      expect(
        skyFrameInterval(
          rain: below,
          snow: below,
          lightning: LightningFrame.none,
        ),
        const Duration(milliseconds: 66),
      );
    });

    test('rain and a strike outrank snow', () {
      expect(
        skyFrameInterval(
          rain: kSkyPrecipitationThreshold,
          snow: 1,
          lightning: LightningFrame.none,
        ),
        const Duration(milliseconds: 16),
      );
      expect(
        skyFrameInterval(rain: 0, snow: 1, lightning: strike),
        const Duration(milliseconds: 16),
      );
    });
  });

  testWidgets('skipped frames accumulate dt', (tester) async {
    var now = 0.0;
    WeatherSkyBackground.debugFrameNow = () => now;
    addTearDown(() => WeatherSkyBackground.debugFrameNow = null);

    await pumpLoaded(
      tester,
      const MaterialApp(
        home: WeatherSkyBackground(active: true, mode: WeatherMode.snow),
      ),
    );

    final held = skyPainter(tester);
    // The load ran on the overridden clock, so this picture is the zero
    // anchor and the gaps below are the whole time since it.
    expect(held.frame.time, 0);

    // Snow's budget is 33 ms. The pump duration only wakes the vsync; the
    // sky clock is [now]. Both of these land inside the budget, so the
    // picture stays put and the paint mark must not move.
    for (final t in <double>[0.016, 0.032]) {
      now = t;
      await tester.pump(const Duration(milliseconds: 16));
      expect(identical(skyPainter(tester), held), isTrue);
    }

    // 48 ms since the painted frame: past 33 ms, under the 1/20 s clamp.
    // A mark that advanced on the skipped vsyncs would report 16 ms here.
    now = 0.048;
    await tester.pump(const Duration(milliseconds: 16));
    final painted = skyPainter(tester);
    expect(identical(painted, held), isFalse);
    expect(painted.dt, 0.048);
  });

  testWidgets('a weather or resume change paints before the interval', (
    tester,
  ) async {
    var now = 0.0;
    WeatherSkyBackground.debugFrameNow = () => now;
    addTearDown(() => WeatherSkyBackground.debugFrameNow = null);

    await pumpLoaded(
      tester,
      const MaterialApp(
        home: WeatherSkyBackground(active: true, mode: WeatherMode.clear),
      ),
    );
    final held = skyPainter(tester);
    expect(held.frame.time, 0);

    // 10 ms is inside both the calm budget and rain's, so only the change
    // itself can justify a new picture.
    now = 0.010;
    await tester.pump(const Duration(milliseconds: 16));
    expect(identical(skyPainter(tester), held), isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherSkyBackground(active: true, mode: WeatherMode.rain),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final raining = skyPainter(tester);
    expect(identical(raining, held), isFalse);
    expect(raining.dt, 0.010);

    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherSkyBackground(active: false, mode: WeatherMode.rain),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(identical(skyPainter(tester), raining), isTrue);

    now = 0.012;
    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherSkyBackground(active: true, mode: WeatherMode.rain),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final resumed = skyPainter(tester);
    expect(identical(resumed, raining), isFalse);
    expect(resumed.dt, closeTo(0.002, 1e-9));
  });

  testWidgets('a calm sky schedules no frame until the pace timer', (
    tester,
  ) async {
    await pumpLoaded(
      tester,
      const MaterialApp(
        home: WeatherSkyBackground(active: true, mode: WeatherMode.clear),
      ),
    );
    // The opening picture has painted and the post-frame callback has armed
    // the timer. Nothing further is scheduled.
    expect(tester.binding.hasScheduledFrame, isFalse);

    final wait = skyFrameInterval(
      rain: 0,
      snow: 0,
      lightning: LightningFrame.none,
    );
    final early =
        wait - WeatherSkyBackground.paceLead - const Duration(milliseconds: 5);
    // delayed advances the fake clock without flushing a frame, so a timer
    // that restarted the ticker leaves hasScheduledFrame set.
    await tester.binding.delayed(early);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.binding.delayed(const Duration(milliseconds: 10));
    expect(tester.binding.hasScheduledFrame, isTrue);
    // Consume the tick the timer requested. Leaving it pending fails the
    // test for a stray frame callback.
    await tester.pump();
  });

  testWidgets('a mode change schedules a frame immediately', (tester) async {
    var now = 0.0;
    WeatherSkyBackground.debugFrameNow = () => now;
    addTearDown(() => WeatherSkyBackground.debugFrameNow = null);

    late StateSetter setMode;
    var mode = WeatherMode.clear;
    await pumpLoaded(
      tester,
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setMode = setState;
            return WeatherSkyBackground(active: true, mode: mode);
          },
        ),
      ),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    final held = skyPainter(tester);

    mode = WeatherMode.rain;
    setMode(() {});
    // The pace timer has not fired. The update itself scheduled the frame.
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(identical(skyPainter(tester), held), isFalse);
  });

  testWidgets('active: false schedules nothing and leaves no timer', (
    tester,
  ) async {
    late StateSetter setActive;
    var active = false;
    await pumpLoaded(
      tester,
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setActive = setState;
            return WeatherSkyBackground(
              active: active,
              mode: WeatherMode.clear,
            );
          },
        ),
      ),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    // delayed, not pump: a timer that restarted the ticker would leave a
    // frame scheduled. pump would draw that frame and hide it.
    await tester.binding.delayed(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);

    active = true;
    setActive(() {});
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    active = false;
    setActive(() {});
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.binding.delayed(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

WeatherSkyPainter skyPainter(WidgetTester tester) {
  return tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(WeatherSkyBackground),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!
      as WeatherSkyPainter;
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
