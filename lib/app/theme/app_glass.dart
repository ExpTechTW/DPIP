import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter/material.dart';

/// Reveal-driven "glass" tinting for content layered over the weather backdrop.
///
/// As a `reveal` dial rises 0→1 (the home sheet exposing the weather behind it),
/// card surfaces frost toward an opaque-enough plate so theme ink stays
/// legible on them. Foregrounds that sit *directly* on the weather sky (header,
/// region bar) use [inkOverWeather] — dark on a light sky, white on a dark sky
/// — because dark-theme [ColorScheme.onSurface] is white and vanishes on clear
/// daylight.

/// The translucent card/surface tint: resting
/// [ColorScheme.surfaceContainerHighest] → near-opaque theme surface as
/// [reveal] rises.
Color glassSurface(ColorScheme colors, double reveal) => Color.lerp(
  colors.surfaceContainerHighest.withValues(alpha: 0.55),
  colors.surface.withValues(alpha: 0.92),
  reveal,
)!;

/// Ink for content **inside** a [glassSurface] card — always the theme
/// on-surface roles. Cards carry their own plate; do not wash these toward
/// white or black for the sky.
Color glassOnSurface(ColorScheme colors) => colors.onSurface;

/// Secondary ink for content inside a [glassSurface] card.
Color glassOnSurfaceVariant(ColorScheme colors) => colors.onSurfaceVariant;

/// Whether [mode]'s sky is light enough that dark foregrounds read better than
/// white once the weather backdrop is showing.
bool weatherSkyIsLight(WeatherMode mode) => switch (mode) {
  WeatherMode.rain || WeatherMode.thunderstorm => false,
  WeatherMode.clear || WeatherMode.fog || WeatherMode.auto => true,
};

/// Ink for content drawn **on** the weather sky (header, region badges).
///
/// As [reveal] rises, shifts toward dark ink on a light sky (critical in dark
/// theme, where [ColorScheme.onSurface] is white) or toward white on a dark
/// sky. At [reveal] `0` returns [ColorScheme.onSurface] unchanged.
Color inkOverWeather(
  ColorScheme colors,
  double reveal, {
  required bool skyIsLight,
}) {
  final target = skyIsLight ? const Color(0xFF121212) : Colors.white;
  return Color.lerp(colors.onSurface, target, reveal)!;
}

/// Secondary ink for content on the weather sky (labels, muted icons).
Color inkOverWeatherVariant(
  ColorScheme colors,
  double reveal, {
  required bool skyIsLight,
}) {
  final target = skyIsLight
      ? const Color(0xFF5A5A5A)
      : Colors.white.withValues(alpha: 0.75);
  return Color.lerp(colors.onSurfaceVariant, target, reveal)!;
}

/// Shifts a foreground [base] colour toward white as [reveal] rises, so text and
/// icons stay legible on a **dark** weather sky. Pass [skyIsLight] from
/// [weatherSkyIsLight] — on a light sky the colour stays [base] (callers that
/// need dark ink on a light sky in dark theme should use [inkOverWeather]
/// instead).
Color lightenOnReveal(
  Color base,
  double reveal, {
  double toAlpha = 1,
  bool skyIsLight = false,
}) {
  if (skyIsLight) return base;
  return Color.lerp(base, Colors.white.withValues(alpha: toAlpha), reveal)!;
}
