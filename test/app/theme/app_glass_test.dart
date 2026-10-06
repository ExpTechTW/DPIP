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
    expect(weatherSkyIsLight(WeatherMode.cloudy), isTrue);
    expect(weatherSkyIsLight(WeatherMode.snow), isTrue);
    expect(weatherSkyIsLight(WeatherMode.auto), isTrue);
    expect(weatherSkyIsLight(WeatherMode.fog), isTrue);
    expect(weatherSkyIsLight(WeatherMode.rain), isFalse);
    expect(weatherSkyIsLight(WeatherMode.thunderstorm), isFalse);
    expect(weatherSkyIsLight(WeatherMode.overcast), isFalse);
    expect(weatherSkyIsLight(WeatherMode.sand), isFalse);
  });

  test('sky card tint follows the hour bucket and stays 20% opaque', () {
    const sky = Color(0xFF4DA3FF);
    final morning = skyCardTint(sky, hour: 6);
    final midday = skyCardTint(sky, hour: 12);
    final night = skyCardTint(sky, hour: 22);
    expect(morning.a, closeTo(glassRevealedAlpha, 0.001));
    expect(midday.a, closeTo(glassRevealedAlpha, 0.001));
    expect(night.a, closeTo(glassRevealedAlpha, 0.001));
    // Midday darkens more than morning; night lightens.
    expect(
      HSLColor.fromColor(midday).lightness,
      lessThan(HSLColor.fromColor(morning).lightness),
    );
    expect(
      HSLColor.fromColor(night).lightness,
      greaterThan(HSLColor.fromColor(sky).lightness),
    );
  });

  test('glass surface stays opaque in light theme and frosts in dark', () {
    expect(glassSurface(light, 0), light.surfaceContainerLow);
    expect(
      glassSurface(light, 1, sky: const Color(0xFF88CCFF)),
      light.surfaceContainerLow,
    );

    final bare = glassSurface(dark, 1);
    expect(bare.a, closeTo(0.92, 0.001));

    const sky = Color(0xFF4DA3FF);
    final first = glassSurface(dark, 1, sky: sky, hour: 11);
    final again = glassSurface(dark, 1, sky: sky, hour: 11);
    expect(again, first);
    // No hour: the Taipei wall clock picks the bucket.
    expect(glassSurface(dark, 0.5, sky: sky).a, greaterThan(0));
  });

  test('glass ink follows the sky only in dark theme', () {
    expect(
      glassOnSurface(light, reveal: 1, skyIsLight: false),
      light.onSurface,
    );
    expect(
      glassOnSurfaceVariant(light, reveal: 1, skyIsLight: true),
      light.onSurfaceVariant,
    );
    final onSky = glassOnSurface(dark, reveal: 1, skyIsLight: true);
    expect(onSky.computeLuminance(), lessThan(0.2));
    final muted = glassOnSurfaceVariant(dark, reveal: 1, skyIsLight: false);
    expect(muted.computeLuminance(), greaterThan(0.5));
  });

  test('sky lightness uses the baked colour, then remembers it', () {
    expect(skyIsLightFrom(null, WeatherMode.rain), isFalse);
    expect(skyIsLightFrom(null, WeatherMode.clear), isTrue);
    const noon = Color(0xFFBEE6FF);
    expect(skyIsLightFrom(noon, WeatherMode.rain), isTrue);
    expect(skyIsLightFrom(noon, WeatherMode.rain), isTrue);
    expect(skyIsLightFrom(const Color(0xFF101820), WeatherMode.clear), isFalse);
  });

  test('lightenOnReveal leaves a light sky alone', () {
    const base = Color(0xFF336699);
    expect(lightenOnReveal(base, 1, skyIsLight: true), base);
    final lifted = lightenOnReveal(base, 1);
    expect(lifted.computeLuminance(), greaterThan(base.computeLuminance()));
  });
}
