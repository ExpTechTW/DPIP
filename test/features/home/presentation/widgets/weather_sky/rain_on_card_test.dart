/// Rain on a card is a ticker plus a position gate. A card that starts dry,
/// fades out, or scrolls toward the toolbar has to stop spending frames, and
/// a tall phone picks a different drop size than a landscape window.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_card.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_raster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clock = _Clock(DateTime.utc(2026, 1, 15, 18));
  setUp(() {
    AppTime.install(ServerClock(clock, const _Elapsed(), const _Source()));
  });

  testWidgets('grades, screen aspects, and the scroll gate all run', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    Future<void> pump({
      required Size screen,
      required double intensity,
      double opacity = 1,
      bool active = true,
      bool glass = true,
      bool silhouette = false,
      bool gated = true,
      bool scrolling = false,
    }) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: screen),
          child: MaterialApp(
            home: scrolling
                ? ListView(
                    controller: scroll,
                    children: [
                      const SizedBox(height: 240),
                      RainOnCard(
                        intensity: intensity,
                        opacity: opacity,
                        active: active,
                        glass: glass,
                        silhouette: silhouette,
                        gated: gated,
                        child: const SizedBox(
                          height: 80,
                          child: ColoredBox(color: Color(0xFF224466)),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: SizedBox(
                      width: screen.width <= 0 ? 0 : 280,
                      height: screen.height <= 0 ? 0 : 120,
                      child: RainOnCard(
                        intensity: intensity,
                        opacity: opacity,
                        active: active,
                        glass: glass,
                        silhouette: silhouette,
                        gated: gated,
                        child: silhouette
                            ? const Text('rain')
                            : const ColoredBox(color: Color(0xFF224466)),
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    await pump(screen: Size.zero, intensity: 0);
    await pump(screen: const Size(200, 500), intensity: 0.2);
    await _waitForShader(tester);
    // The first tick records a zero dt; the next one steps the water.
    await tester.pump(const Duration(milliseconds: 32));
    await tester.pump(const Duration(milliseconds: 32));

    await pump(screen: const Size(400, 600), intensity: 0.5);
    await tester.pump(const Duration(milliseconds: 32));
    await pump(screen: const Size(800, 400), intensity: 0.9, glass: false);
    await tester.pump(const Duration(milliseconds: 32));

    clock.current = DateTime.utc(2026, 1, 15, 4);
    await pump(
      screen: const Size(400, 700),
      intensity: 0.5,
      gated: false,
      glass: false,
    );
    await tester.pump(const Duration(milliseconds: 32));

    await pump(screen: const Size(400, 700), intensity: 0.5, opacity: 0);
    await tester.pump();
    await pump(screen: const Size(400, 700), intensity: 0.5, opacity: 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));

    await pump(screen: const Size(400, 700), intensity: 0.5, active: false);
    await tester.pump();
    await pump(screen: const Size(400, 700), intensity: 0);
    await tester.pump();

    await pump(
      screen: const Size(400, 800),
      intensity: 0.6,
      silhouette: true,
      glass: false,
    );
    await _waitForShader(tester);
    await tester.pump(const Duration(milliseconds: 32));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    await pump(screen: const Size(400, 800), intensity: 0.6, scrolling: true);
    await _waitForShader(tester);
    await tester.pump(const Duration(milliseconds: 32));
    await tester.pump(const Duration(milliseconds: 32));
    scroll.jumpTo(120);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));

    await tester.pumpWidget(const SizedBox());
    addTearDown(tester.view.reset);
  });

  testWidgets('a frame the solver skips does not toImageSync', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(400, 800)),
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 280,
              height: 120,
              child: RainOnCard(
                intensity: 0.5,
                child: ColoredBox(color: Color(0xFF224466)),
              ),
            ),
          ),
        ),
      ),
    );
    await _waitForShader(tester);
    // The first tick records a zero dt; the ones after it step and emit.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }
    debugResetWeatherRasterCounts();

    var idle = 0;
    var stepped = 0;
    for (var i = 0; i < 30; i++) {
      final sync = debugWeatherToImageSyncCount;
      final steps = debugWeatherSolverSteps;
      final rasters = debugWeatherTickRasters;
      await tester.pump(const Duration(milliseconds: 8));
      expect(debugWeatherToImageSyncCount, sync);
      if (debugWeatherSolverSteps == steps) {
        expect(debugWeatherTickRasters, rasters);
        idle++;
      } else {
        stepped++;
      }
    }
    expect(idle, greaterThan(0));
    expect(stepped, greaterThan(0));
    expect(debugWeatherToImageCount, greaterThan(0));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a solver step rasterizes the accumulation atlas once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(400, 800)),
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 280,
              height: 120,
              // Face droplets bake their own image. Off, so the counter is
              // the edge-water atlas and nothing else.
              child: RainOnCard(
                intensity: 0.5,
                glass: false,
                child: ColoredBox(color: Color(0xFF224466)),
              ),
            ),
          ),
        ),
      ),
    );
    await _waitForShader(tester);
    // Land the first drops and finish any raster already in flight, so the
    // window below only counts rasters this run starts.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 32));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    debugResetWeatherRasterCounts();

    for (var i = 0; i < 24; i++) {
      final steps = debugWeatherSolverSteps;
      final images = debugWeatherToImageCount;
      await tester.pump(const Duration(milliseconds: 16));
      // toImage finishes off the test's fake clock. Waiting here counts a
      // second raster of the same step, if one were still issued.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(
        debugWeatherToImageCount - images,
        lessThanOrEqualTo(debugWeatherSolverSteps - steps),
      );
    }
    expect(debugWeatherSolverSteps, greaterThan(0));
    expect(debugWeatherToImageCount, greaterThan(0));
    expect(
      debugWeatherToImageCount,
      lessThanOrEqualTo(debugWeatherSolverSteps),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

Future<void> _waitForShader(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
}

class _Clock implements Clock {
  _Clock(this.current);
  DateTime current;

  @override
  DateTime now() => current;
}

class _Elapsed implements Elapsed {
  const _Elapsed();

  @override
  Duration get elapsed => Duration.zero;
}

class _Source implements ServerTimeSource {
  const _Source();

  @override
  Future<Result<int>> serverTimeMs() async =>
      const Err(UnexpectedFailure('unused'));
}
