import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

/// `resolveBackdrop` — the home sheet's backdrop inputs must follow the live
/// CWB code under `auto`, and switch to a pure forced look when the
/// experimental settings pin one. The second half is the regression: a forced
/// 晴天 used to keep the live rain/snow overrides, so the sky rendered sunny
/// keyframes with rain drops on top.
void main() {
  const raining = WeatherRealtimeData(
    weather: '有雨',
    weatherCode: 106,
    humidity: 92,
    wind: WeatherWind(),
    gust: WeatherWind(),
  );

  test('auto mode follows the live code and its overrides', () {
    final b = resolveBackdrop(WeatherMode.auto, raining);
    expect(b.mode, WeatherMode.rain);
    expect(b.rain, 0.35); // 有雨 → the 小雨 rung
    expect(b.snow, isNull);
    expect(b.humidity, 92);
  });

  test('a forced mode drops every live override', () {
    final b = resolveBackdrop(WeatherMode.clear, raining);
    expect(b.mode, WeatherMode.clear);
    expect(b.rain, isNull);
    expect(b.snow, isNull);
    expect(b.humidity, isNull);
  });

  test('auto mode with no reading falls back to the auto look', () {
    final b = resolveBackdrop(WeatherMode.auto, null);
    expect(b.mode, WeatherMode.auto);
    expect(b.rain, isNull);
    expect(b.snow, isNull);
    expect(b.humidity, isNull);
  });

  test('a forced auto is indistinguishable from auto (no data)', () {
    final b = resolveBackdrop(WeatherMode.auto, null);
    expect(b.mode, WeatherMode.auto);
  });
}
