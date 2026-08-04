import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dark = ColorScheme.dark();
  const light = ColorScheme.light();

  test('inkOverWeather goes dark on a light sky in dark theme', () {
    final color = inkOverWeather(dark, 1, skyIsLight: true);
    expect(color.computeLuminance(), lessThan(0.2));
  });

  test('inkOverWeather goes white on a dark sky in light theme', () {
    final color = inkOverWeather(light, 1, skyIsLight: false);
    expect(color.computeLuminance(), greaterThan(0.8));
  });

  test('inkOverWeather at reveal 0 keeps theme onSurface', () {
    expect(inkOverWeather(dark, 0, skyIsLight: true), dark.onSurface);
    expect(inkOverWeather(light, 0, skyIsLight: false), light.onSurface);
  });

  test('weatherSkyIsLight matches mode', () {
    expect(weatherSkyIsLight(WeatherMode.clear), isTrue);
    expect(weatherSkyIsLight(WeatherMode.auto), isTrue);
    expect(weatherSkyIsLight(WeatherMode.fog), isTrue);
    expect(weatherSkyIsLight(WeatherMode.rain), isFalse);
    expect(weatherSkyIsLight(WeatherMode.thunderstorm), isFalse);
  });
}
