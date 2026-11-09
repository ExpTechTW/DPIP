/// The card's edge water shares the sky pace. A tick does not ask for the
/// next vsync; a timer does, one rain interval later.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_card.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_frame_pace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppTime.install(
      ServerClock(
        _Clock(DateTime.utc(2026, 1, 15, 18)),
        const _Elapsed(),
        const _Source(),
      ),
    );
  });

  testWidgets(
    'a raining card schedules the next frame only after the pace interval',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: Center(
              child: SizedBox(
                width: 280,
                height: 120,
                // The face droplets are a second ticker. Off, so the only
                // frame source is this card's edge water.
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

      // The shader load is real async. Once a tick has run, nothing is
      // scheduled until the pace interval asks for the next frame.
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
        // The load's setState still owes a frame, or the ticker has not
        // ticked yet.
        if (SchedulerBinding.instance.hasScheduledFrame) continue;

        expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
        // The pulse has not asked for the next frame yet.
        await tester.binding.delayed(
          kSkyRainInterval - kSkyPaceLead - const Duration(milliseconds: 1),
        );
        expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

        // By the interval the early wake has scheduled exactly one frame.
        // A card whose shader is still loading schedules nothing here.
        await tester.binding.delayed(
          kSkyPaceLead + const Duration(milliseconds: 1),
        );
        if (SchedulerBinding.instance.hasScheduledFrame) break;
      }
      expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);

      await tester.pump();
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    },
  );
}

class _Clock implements Clock {
  _Clock(this.current);
  final DateTime current;

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
