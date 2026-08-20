import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_glass.dart';
import 'package:flutter/material.dart';
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
}
