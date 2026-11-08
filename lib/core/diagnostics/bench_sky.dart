/// Pins the home weather backdrop for `tool/dev/bench_sky.sh`.
///
/// Compiled in only when the build also sets
/// `--dart-define=DPIP_FRAME_BENCH=true` (the same switch [FrameBench] uses).
/// A normal debug, profile, or release build never reads it: both defines
/// below are empty, the file is never opened, and [benchWeatherOr] /
/// [benchSkyTimeOr] return the experimental settings unchanged.
///
/// Two ways to name the scene, the file winning when it is present so one
/// profile APK can measure every state:
///
/// * `--dart-define=DPIP_BENCH_WEATHER=rain` and
///   `--dart-define=DPIP_BENCH_SKY_TIME=noon` — [WeatherMode] / [SkyTimeMode]
///   names, case-insensitive.
/// * `bench_sky.txt` in the app support directory (`files/bench_sky.txt` on
///   Android), one line `weather sky` or `weather,sky`. The bench script
///   writes this with `run-as` before each launch. A token that is not a
///   mode name is ignored and the define (or the real setting) stands.
library;

import 'dart:io';

import 'package:dpip/core/diagnostics/frame_bench.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:path_provider/path_provider.dart';

/// Support-directory file [tool/dev/bench_sky.sh] writes before launch.
const String benchSkyFileName = 'bench_sky.txt';

/// Resolved once at startup. Null means "no bench pin" — follow settings.
abstract final class BenchSky {
  static WeatherMode? weather;
  static SkyTimeMode? skyTime;

  /// Reads the defines and, when present, [benchSkyFileName]. No-op unless
  /// this is a frame-bench build.
  static Future<void> load() async {
    if (!frameBenchEnabled) return;
    const defineWeather = String.fromEnvironment('DPIP_BENCH_WEATHER');
    const defineSkyTime = String.fromEnvironment('DPIP_BENCH_SKY_TIME');
    String? fileText;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$benchSkyFileName');
      if (file.existsSync()) fileText = file.readAsStringSync();
    } catch (error, stackTrace) {
      Log.handle(
        error,
        stackTrace,
        'bench sky: could not read $benchSkyFileName',
      );
    }
    final parsed = parseBenchSky(
      defineWeather: defineWeather,
      defineSkyTime: defineSkyTime,
      fileText: fileText,
    );
    weather = parsed.weather;
    skyTime = parsed.skyTime;
    Log.info(
      'bench sky: ${weather?.name ?? '(settings)'} '
      '${skyTime?.name ?? '(settings)'}',
    );
  }
}

/// The forced backdrop, or [settings] when this build is not a frame bench
/// or the bench did not name a weather mode.
WeatherMode benchWeatherOr(WeatherMode settings) {
  if (!frameBenchEnabled) return settings;
  return BenchSky.weather ?? settings;
}

/// The forced time of day, or [settings] when the bench did not name one.
SkyTimeMode benchSkyTimeOr(SkyTimeMode settings) {
  if (!frameBenchEnabled) return settings;
  return BenchSky.skyTime ?? settings;
}

/// Merges the compile-time defines with the optional scene file.
///
/// [fileText] replaces a define only for a token that is a real mode name.
/// An absent file (`null`) leaves the defines. An empty or junk token leaves
/// that axis on the define, which itself may be null.
({WeatherMode? weather, SkyTimeMode? skyTime}) parseBenchSky({
  String defineWeather = '',
  String defineSkyTime = '',
  String? fileText,
}) {
  var weather = _match(WeatherMode.values, defineWeather);
  var skyTime = _match(SkyTimeMode.values, defineSkyTime);
  if (fileText == null) return (weather: weather, skyTime: skyTime);
  final parts = fileText
      .trim()
      .split(RegExp(r'[\s,]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isNotEmpty) {
    final parsed = _match(WeatherMode.values, parts[0]);
    if (parsed != null) weather = parsed;
  }
  if (parts.length >= 2) {
    final parsed = _match(SkyTimeMode.values, parts[1]);
    if (parsed != null) skyTime = parsed;
  }
  return (weather: weather, skyTime: skyTime);
}

T? _match<T extends Enum>(List<T> values, String raw) {
  final name = raw.trim().toLowerCase();
  if (name.isEmpty) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
