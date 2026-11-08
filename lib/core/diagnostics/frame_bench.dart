/// Per-frame timing capture for the map and sky benchmarks
/// (`tool/dev/bench_map.sh`, `tool/dev/bench_sky.sh`).
///
/// Compiled out unless the build sets `--dart-define=DPIP_FRAME_BENCH=true`,
/// which only the benchmark's own profile build does. Every frame's build and
/// raster time is appended to `frame_bench.csv` in the app's support directory;
/// the script reads it back with `run-as` (a profile APK is debuggable) and
/// keeps the rows inside the window it timed with the device's own clock.
///
/// A file rather than the log: `Log` writes to the console in debug builds
/// only, and a profile build is the only one whose frame times mean anything.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

/// Whether this build records frame timings for the benchmark.
const bool frameBenchEnabled = bool.fromEnvironment('DPIP_FRAME_BENCH');

abstract final class FrameBench {
  const FrameBench._();

  static RandomAccessFile? _file;

  /// Starts recording when [frameBenchEnabled]; otherwise does nothing.
  static Future<void> installIfEnabled() async {
    if (!frameBenchEnabled) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _file = await File('${dir.path}/frame_bench.csv')
          .open(mode: FileMode.write);
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      Log.info('frame bench: recording');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'frame bench: could not open its file');
    }
  }

  /// One row per frame: `wall ms, build µs, raster µs, total µs`. The batch
  /// arrives roughly every 100 ms, so a synchronous append of a few hundred
  /// bytes is noise next to the frames it describes.
  static void _onTimings(List<FrameTiming> timings) {
    final file = _file;
    if (file == null) return;
    // wall-clock: rows are matched against the bench script's `date +%s%3N`
    // window, which reads this same device clock.
    final wall = DateTime.now().millisecondsSinceEpoch;
    final rows = StringBuffer();
    for (final t in timings) {
      rows
        ..write(wall)
        ..write(',')
        ..write(t.buildDuration.inMicroseconds)
        ..write(',')
        ..write(t.rasterDuration.inMicroseconds)
        ..write(',')
        ..write(t.totalSpan.inMicroseconds)
        ..write('\n');
    }
    file.writeStringSync(rows.toString());
  }
}
