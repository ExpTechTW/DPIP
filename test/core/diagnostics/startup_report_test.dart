/// A launch summary has to stay bounded and has to say the same thing about
/// the same frames — and it must leave the device at most once a session.
library;

import 'dart:ui' show FrameTiming, TimingsCallback;

import 'package:dpip/core/diagnostics/crash_reporting.dart';
import 'package:dpip/core/diagnostics/prerelease_diagnostics.dart';
import 'package:dpip/core/diagnostics/startup_report.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/install_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// A frame whose build took [buildUs] and raster took [rasterUs].
FrameTiming frame(int buildUs, int rasterUs) => FrameTiming(
  vsyncStart: 0,
  buildStart: 0,
  buildFinish: buildUs,
  rasterStart: buildUs,
  rasterFinish: buildUs + rasterUs,
  rasterFinishWallTime: buildUs + rasterUs,
);

class _Engine {
  TimingsCallback? callback;
  int removed = 0;

  void add(TimingsCallback c) => callback = c;
  // `==`, as SchedulerBinding's own list removal does: a method tear-off is
  // equal to, not identical with, the one that was added.
  void remove(TimingsCallback c) {
    if (c == callback) callback = null;
    removed++;
  }

  void deliver(List<FrameTiming> timings) => callback?.call(timings);
}

class _Reporter implements CrashReporter {
  final keys = <String, Object>{};
  final errors = <Object>[];
  final lines = <String>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
  @override
  Future<void> deleteUnsentReports() async {}
  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    required bool fatal,
  }) async => errors.add(error);
  @override
  Future<void> log(String message) async => lines.add(message);
  @override
  Future<void> setKey(String key, Object value) async => keys[key] = value;
}

FrameSummary summaryOf(int frames, {int buildUs = 4000}) => FrameSummary.of(
  List.filled(frames, buildUs),
  List.filled(frames, 5000),
  budgetUs: 16667,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Percentiles', () {
    test('nearest rank: every percentile is a value that was observed', () {
      final p = Percentiles.of(List.generate(100, (i) => i + 1));
      expect(p.p50, 50);
      expect(p.p90, 90);
      expect(p.p99, 99);
    });

    test('one slow frame in a hundred is the p99, not an average', () {
      final values = [...List.filled(99, 5000), 80000];
      final p = Percentiles.of(values);
      expect(p.p50, 5000);
      expect(p.p99, 5000);
      expect(Percentiles.of([...values, 80000]).p99, 80000);
    });

    test('empty and single inputs do not throw', () {
      expect(Percentiles.of(const []).p99, 0);
      expect(Percentiles.of(const [7]).p50, 7);
      expect(Percentiles.of(const [7]).p99, 7);
    });
  });

  group('FrameSummary', () {
    test('a frame is janky when either thread missed the budget', () {
      final summary = FrameSummary.of(
        [4000, 20000, 4000, 4000],
        [4000, 4000, 30000, 4000],
        budgetUs: 16667,
      );
      expect(summary.frames, 4);
      expect(summary.janky, 2);
      expect(summary.jankyFraction, 0.5);
      expect(summary.keys['frames_janky'], 2);
      expect(summary.keys['build_p99_us'], 20000);
      expect(summary.keys['raster_p99_us'], 30000);
      expect(
        summary.describe(),
        startsWith('frames=4 janky=2 (50.0%) budget=16.7ms'),
      );
    });

    test('an empty window is not a division by zero', () {
      final summary = FrameSummary.of(const [], const [], budgetUs: 16667);
      expect(summary.jankyFraction, 0);
      expect(summary.describe(), contains('frames=0'));
    });
  });

  group('StartupFrameSampler', () {
    test('summarizes at the end of the window and stops listening', () {
      fakeAsync((async) {
        final engine = _Engine();
        FrameSummary? out;
        StartupFrameSampler(
          onSummary: (s) => out = s,
          window: const Duration(seconds: 20),
          budgetUs: 16667,
          addTimings: engine.add,
          removeTimings: engine.remove,
        ).start();

        engine.deliver([frame(4000, 5000), frame(20000, 5000)]);
        async.elapse(const Duration(seconds: 19));
        expect(out, isNull);
        engine.deliver([frame(4000, 5000)]);
        async.elapse(const Duration(seconds: 2));

        expect(out!.frames, 3);
        expect(out!.janky, 1);
        expect(engine.callback, isNull, reason: 'the engine stops reporting');
        // Nothing after the window counts or calls back again.
        engine.deliver([frame(1, 1)]);
        expect(out!.frames, 3);
      });
    });

    test('a frame ceiling ends the window early', () {
      fakeAsync((async) {
        final engine = _Engine();
        final summaries = <FrameSummary>[];
        StartupFrameSampler(
          onSummary: summaries.add,
          maxFrames: 5,
          budgetUs: 16667,
          addTimings: engine.add,
          removeTimings: engine.remove,
        ).start();

        engine.deliver(List.generate(8, (_) => frame(1000, 1000)));
        expect(summaries, hasLength(1));
        expect(summaries.single.frames, 5);
        async.elapse(const Duration(minutes: 1));
        expect(summaries, hasLength(1), reason: 'the timer was cancelled');
      });
    });

    test('batches that arrive off the measured screen are dropped', () {
      fakeAsync((async) {
        final engine = _Engine();
        var onMap = true;
        FrameSummary? out;
        StartupFrameSampler(
          onSummary: (s) => out = s,
          counting: () => onMap,
          budgetUs: 16667,
          addTimings: engine.add,
          removeTimings: engine.remove,
        ).start();

        engine.deliver([frame(1000, 1000), frame(1000, 1000)]);
        onMap = false;
        engine.deliver([frame(90000, 90000)]);
        onMap = true;
        engine.deliver([frame(1000, 1000)]);
        async.elapse(const Duration(seconds: 21));

        expect(out!.frames, 3);
        expect(out!.janky, 0);
      });
    });

    test('stop abandons the window without a summary', () {
      fakeAsync((async) {
        final engine = _Engine();
        var called = false;
        final sampler = StartupFrameSampler(
          onSummary: (_) => called = true,
          budgetUs: 16667,
          addTimings: engine.add,
          removeTimings: engine.remove,
        )..start();
        sampler.stop();
        async.elapse(const Duration(minutes: 1));
        expect(called, isFalse);
        expect(engine.callback, isNull);
      });
    });

    test('the budget follows a sane refresh rate', () {
      final budget = StartupFrameSampler.refreshBudgetUs();
      // 240 Hz .. 30 Hz.
      expect(budget, inInclusiveRange(4166, 33334));
    });
  });

  group('PrereleaseDiagnostics.reportStartup', () {
    late _Reporter reporter;

    setUp(() async {
      StartupMarks.debugReset();
      PrereleaseDiagnostics.debugReset();
      InstallSourceService.debugSet(InstallSource.testFlight);
      reporter = _Reporter();
      await PrereleaseDiagnostics.start(
        reporter: reporter,
        prerelease: true,
        device: () async => null,
      );
      reporter.keys.clear();
    });

    tearDown(() {
      StartupMarks.debugReset();
      PrereleaseDiagnostics.debugReset();
      InstallSourceService.debugSet(null);
      Log.crashSink = null;
    });

    test('sends one summary with the phases and the frames as keys', () async {
      StartupMarks.mark('ready', 420);
      StartupMarks.mark('first_frame', 610);

      await PrereleaseDiagnostics.reportStartup(
        summaryOf(120),
        debugMode: false,
      );

      expect(reporter.errors.single, isA<StartupPerformanceReport>());
      expect(reporter.keys['startup_ready_ms'], 420);
      expect(reporter.keys['startup_first_frame_ms'], 610);
      expect(reporter.keys['frames_sampled'], 120);
      expect(reporter.lines.single, contains('ready=420ms'));
    });

    test('at most once a session', () async {
      await PrereleaseDiagnostics.reportStartup(
        summaryOf(120),
        debugMode: false,
      );
      await PrereleaseDiagnostics.reportStartup(
        summaryOf(120),
        debugMode: false,
      );
      expect(reporter.errors, hasLength(1));
    });

    test('a debug build only logs it', () async {
      await PrereleaseDiagnostics.reportStartup(
        summaryOf(120),
        debugMode: true,
      );
      expect(reporter.errors, isEmpty);
      expect(reporter.keys, isEmpty);
    });

    test('too few frames is not a launch worth sending', () async {
      await PrereleaseDiagnostics.reportStartup(
        summaryOf(PrereleaseDiagnostics.minStartupFrames - 1),
        debugMode: false,
      );
      expect(reporter.errors, isEmpty);
      // And it does not use up the session's one summary.
      await PrereleaseDiagnostics.reportStartup(
        summaryOf(PrereleaseDiagnostics.minStartupFrames),
        debugMode: false,
      );
      expect(reporter.errors, hasLength(1));
    });

    test('production has no reporter, so nothing is sent', () async {
      PrereleaseDiagnostics.debugReset();
      await PrereleaseDiagnostics.start(reporter: reporter, prerelease: false);
      await PrereleaseDiagnostics.reportStartup(
        summaryOf(120),
        debugMode: false,
      );
      expect(reporter.errors, isEmpty);
    });

    test('the first mark for a phase wins over a hot restart', () {
      StartupMarks.mark('ready', 400);
      StartupMarks.mark('ready', 9000);
      expect(StartupMarks.all['ready'], 400);
    });
  });
}
