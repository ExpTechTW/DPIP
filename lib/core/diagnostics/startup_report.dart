/// How long launch took, and how smooth the first seconds after it were.
///
/// Measured in every build, sent from prerelease builds only — see
/// [PrereleaseDiagnostics.reportStartup].
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FrameTiming, PlatformDispatcher, TimingsCallback;

import 'package:flutter/scheduler.dart';

/// Milliseconds from launch to each named phase, in the order they happened.
///
/// `bootstrap` already logs these; they are kept here as numbers as well so a
/// summary can carry them without parsing a log line back.
abstract final class StartupMarks {
  static final Map<String, int> _marks = {};

  /// Records [phase] at [ms] after launch. The first value for a phase wins:
  /// a hot restart re-runs bootstrap, and its numbers are not a launch.
  static void mark(String phase, int ms) => _marks.putIfAbsent(phase, () => ms);

  static Map<String, int> get all => Map.unmodifiable(_marks);

  static void debugReset() => _marks.clear();
}

/// The distribution of a window of frames, in microseconds.
///
/// A frame is **janky** when either half of it — building the frame on the UI
/// thread, or rasterizing it on the raster thread — took longer than one
/// refresh interval. Either one alone is enough to miss the vsync, and naming
/// which half was slow is what tells a reader where to look.
class FrameSummary {
  const FrameSummary({
    required this.frames,
    required this.janky,
    required this.budgetUs,
    required this.buildUs,
    required this.rasterUs,
  });

  /// Summarizes parallel lists of build and raster durations.
  factory FrameSummary.of(
    List<int> buildUs,
    List<int> rasterUs, {
    required int budgetUs,
  }) {
    assert(buildUs.length == rasterUs.length);
    var janky = 0;
    for (var i = 0; i < buildUs.length; i++) {
      if (buildUs[i] > budgetUs || rasterUs[i] > budgetUs) janky++;
    }
    return FrameSummary(
      frames: buildUs.length,
      janky: janky,
      budgetUs: budgetUs,
      buildUs: Percentiles.of(buildUs),
      rasterUs: Percentiles.of(rasterUs),
    );
  }

  final int frames;
  final int janky;
  final int budgetUs;
  final Percentiles buildUs;
  final Percentiles rasterUs;

  double get jankyFraction => frames == 0 ? 0 : janky / frames;

  /// One line, the same one the log and the report carry.
  String describe() {
    String ms(int us) => (us / 1000).toStringAsFixed(1);
    final percent = (jankyFraction * 100).toStringAsFixed(1);
    return 'frames=$frames janky=$janky ($percent%) budget=${ms(budgetUs)}ms '
        'build p50/p90/p99=${ms(buildUs.p50)}/${ms(buildUs.p90)}/'
        '${ms(buildUs.p99)}ms '
        'raster p50/p90/p99=${ms(rasterUs.p50)}/${ms(rasterUs.p90)}/'
        '${ms(rasterUs.p99)}ms';
  }

  /// Flat values for a crash report's custom keys.
  Map<String, int> get keys => {
    'frames_sampled': frames,
    'frames_janky': janky,
    'frame_budget_us': budgetUs,
    'build_p50_us': buildUs.p50,
    'build_p90_us': buildUs.p90,
    'build_p99_us': buildUs.p99,
    'raster_p50_us': rasterUs.p50,
    'raster_p90_us': rasterUs.p90,
    'raster_p99_us': rasterUs.p99,
  };
}

/// Nearest-rank percentiles: each is a value that was actually observed, so a
/// p99 of 40 ms means some frame really took 40 ms.
class Percentiles {
  const Percentiles(this.p50, this.p90, this.p99);

  factory Percentiles.of(List<int> values) {
    if (values.isEmpty) return const Percentiles(0, 0, 0);
    final sorted = List<int>.of(values)..sort();
    int at(double p) {
      final rank = (p * sorted.length).ceil();
      return sorted[math.max(0, math.min(sorted.length, rank) - 1)];
    }

    return Percentiles(at(0.50), at(0.90), at(0.99));
  }

  final int p50;
  final int p90;
  final int p99;
}

/// Collects frame timings for a bounded window, then hands over one summary.
///
/// Bounded twice — by [window] and by [maxFrames] — so a session that runs
/// for hours costs exactly as much as one that runs for twenty seconds: two
/// integer lists of at most [maxFrames] each, and nothing at all once the
/// summary is out. The engine only reports timings while a callback is
/// registered, so after [stop] it stops measuring too.
///
/// Frames arrive in batches (about once a second in a release build), so the
/// last part-second of the window is not counted, and [counting] is asked once
/// per batch rather than once per frame: a batch that straddles a tab switch
/// is counted or dropped whole. A window in which no frame is drawn — an app
/// that sat still — still ends on time, with what it has.
class StartupFrameSampler {
  StartupFrameSampler({
    required this.onSummary,
    this.counting = _always,
    this.window = const Duration(seconds: 20),
    this.maxFrames = 1200,
    int? budgetUs,
    void Function(TimingsCallback)? addTimings,
    void Function(TimingsCallback)? removeTimings,
  }) : budgetUs = budgetUs ?? refreshBudgetUs(),
       _add = addTimings ?? SchedulerBinding.instance.addTimingsCallback,
       _remove =
           removeTimings ?? SchedulerBinding.instance.removeTimingsCallback;

  final void Function(FrameSummary summary) onSummary;

  /// Whether a batch arriving now describes the screen being measured.
  final bool Function() counting;
  final Duration window;
  final int maxFrames;
  final int budgetUs;
  final void Function(TimingsCallback) _add;
  final void Function(TimingsCallback) _remove;

  final List<int> _build = [];
  final List<int> _raster = [];
  Timer? _timer;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _add(_onTimings);
    _timer = Timer(window, _finish);
  }

  /// Abandons the window without a summary.
  void stop() {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _remove(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_running || !counting()) return;
    for (final timing in timings) {
      _build.add(timing.buildDuration.inMicroseconds);
      _raster.add(timing.rasterDuration.inMicroseconds);
      if (_build.length >= maxFrames) {
        _finish();
        return;
      }
    }
  }

  void _finish() {
    if (!_running) return;
    stop();
    onSummary(FrameSummary.of(_build, _raster, budgetUs: budgetUs));
    _build.clear();
    _raster.clear();
  }

  static bool _always() => true;

  /// One refresh interval of the display the app is on.
  ///
  /// Not a fixed 16.7 ms: a 90 Hz panel misses its vsync at 11.1 ms, and the
  /// cheap phones this is for are increasingly 90 Hz. A reading outside what
  /// any phone panel does is taken for 60 Hz.
  static int refreshBudgetUs() {
    final views = PlatformDispatcher.instance.views;
    final rate = views.isEmpty ? 60.0 : views.first.display.refreshRate;
    final hz = rate >= 30 && rate <= 240 ? rate : 60.0;
    return (1000000 / hz).round();
  }
}
