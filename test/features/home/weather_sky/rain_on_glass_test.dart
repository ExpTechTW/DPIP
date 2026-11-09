import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_glass.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_frame_pace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// `RainOnGlass` wraps the home sheet's own content, which is the surface the
/// user drags to collapse the sheet. A decorative filter must never eat that
/// gesture.
void main() {
  testWidgets('a scrollable inside RainOnGlass still scrolls', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: RainOnGlass(
          intensity: 0.8,
          child: ListView.builder(
            controller: controller,
            itemCount: 60,
            itemBuilder: (context, i) =>
                SizedBox(height: 50, child: Text('row $i')),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.text('row 1'), const Offset(0, -300));
    // The droplet ticker repeats forever, so `pumpAndSettle` would never
    // return — pump a fixed number of frames instead.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      controller.offset,
      greaterThan(0),
      reason: 'drag did not scroll: offset ${controller.offset}',
    );
    controller.dispose();
  });

  testWidgets('taps reach a button inside RainOnGlass', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RainOnGlass(
          intensity: 0.8,
          child: Center(
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('tap me'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('tap me'));
    await tester.pump();

    expect(taps, 1, reason: 'tap did not reach the button');
  });

  testWidgets('an unsupported shader filter stops scheduling frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RainOnGlass(intensity: 0.8, child: SizedBox.expand()),
      ),
    );

    // Widget tests use Skia, where ImageFilter.shader is unsupported. Once
    // that capability check fails, there is no drawable effect and therefore
    // no reason to keep a 60 fps ticker alive.
    await tester.pumpAndSettle(const Duration(milliseconds: 16));

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a card faded to zero opacity schedules no frames', (
    tester,
  ) async {
    // `build` never constructs the filter below opacity 0.004, so the Skia
    // capability check above never fires here — the only thing that can stop
    // the ticker is the opacity gate itself. Before it existed, this widget
    // spun a vsync loop forever on an invisible card.
    await tester.pumpWidget(
      const MaterialApp(
        home: RainOnGlass(intensity: 0.8, opacity: 0, child: SizedBox.expand()),
      ),
    );
    // A bounded pump: with the bug the ticker repeats forever and
    // `pumpAndSettle` would never return.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('rain on the glass schedules the next frame one interval later', (
    tester,
  ) async {
    // The test backend has no shader image filter, so the ticker would
    // otherwise never start and there would be no paced gap to see.
    addTearDown(() => RainOnGlass.debugRunTickerWithoutShaderFilter = false);
    RainOnGlass.debugRunTickerWithoutShaderFilter = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: RainOnGlass(intensity: 0.8, child: SizedBox.expand()),
      ),
    );

    // Shader load is real async. The load starts the ticker, which asks
    // for one frame and then stops until the shared pulse wakes it.
    var armed = false;
    for (var i = 0; i < 40 && !armed; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      if (SchedulerBinding.instance.hasScheduledFrame) {
        armed = true;
        break;
      }
      await tester.pump();
      armed = SchedulerBinding.instance.hasScheduledFrame;
    }
    expect(armed, isTrue, reason: 'the glass ticker should ask for a frame');

    await tester.pump();
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

    // Elapse without yielding first: the pulse timer is fake time, and a
    // yield here lets the coverage raster land and the next tick build a
    // filter the test backend cannot draw.
    final elapsed = tester.binding.delayed(kSkyRainInterval);
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await elapsed;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  });
}
