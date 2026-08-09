import 'package:dpip/core/realtime/app_time.dart';
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

/// The card fill the reference paints once the weather is showing: **the sky's own
/// colour at 20 % alpha**, with only its HSL lightness moved.
///
/// The reference's `D()` converts the sky-gradient colour to HSL, shifts `L`
/// alone — −0.30 in the morning bucket, −0.40 around midday, +0.20 otherwise —
/// converts back, and returns `Color.argb(51, …)`. Hue and saturation are never
/// touched, which is why the card reads as a pane of the sky rather than a grey
/// plate laid over it, and 51/255 = 0.20 is a literal in that method rather
/// than anything device- or theme-dependent.
///
/// [hour] is the local hour that picks the bucket (the reference
/// buckets 4–9 / 10–14 / rest); it is a parameter so this stays pure.
Color skyCardTint(Color sky, {required int hour}) {
  final shift = hour >= 4 && hour <= 9
      ? -0.30
      : hour >= 10 && hour <= 14
      ? -0.40
      : 0.20;
  final hsl = HSLColor.fromColor(sky);
  return hsl
      .withLightness((hsl.lightness + shift).clamp(0.0, 1.0))
      .toColor()
      .withValues(alpha: glassRevealedAlpha);
}

/// The reference's card alpha once the weather backdrop is showing (`Color.argb(51,…)`).
///
/// It is this low on purpose: the falling rain has to be visible *through* the
/// card. A card opaque enough to hide it stops the rain dead at its edge, which
/// is the single thing that most gives a port away.
const double glassRevealedAlpha = 0.20;

/// The translucent card/surface tint: resting
/// [ColorScheme.surfaceContainerHighest] → the reference's sky-tinted 20 % fill as
/// [reveal] rises.
///
/// Without a [sky] colour (no backdrop running, or before the first LUT bake)
/// it falls back to a near-opaque theme surface, because 20 % of nothing is an
/// unreadable card.
Color glassSurface(
  ColorScheme colors,
  double reveal, {
  Color? sky,
  int? hour,
}) => Color.lerp(
  colors.surfaceContainerHighest.withValues(alpha: 0.55),
  sky == null
      ? colors.surface.withValues(alpha: 0.92)
      : skyCardTint(sky, hour: hour ?? AppTime.utc8.hour),
  reveal,
)!;

/// Ink for content **inside** a [glassSurface] card.
///
/// At rest the card is its own plate and the theme's on-surface roles are
/// right. Once [reveal] dissolves it to the 20 % fill above, the card is no
/// longer a plate — it is a pane of the sky — so its ink has to follow the sky
/// exactly the way [inkOverWeather] does. Leaving it on [ColorScheme.onSurface]
/// puts near-black text on a rain sky in a light theme.
Color glassOnSurface(
  ColorScheme colors, {
  double reveal = 0,
  bool skyIsLight = false,
}) => inkOverWeather(colors, reveal, skyIsLight: skyIsLight);

/// Secondary ink for content inside a [glassSurface] card.
Color glassOnSurfaceVariant(
  ColorScheme colors, {
  double reveal = 0,
  bool skyIsLight = false,
}) => inkOverWeatherVariant(colors, reveal, skyIsLight: skyIsLight);

/// Whether [mode]'s sky is light enough that dark foregrounds read better than
/// white once the weather backdrop is showing.
///
/// A **fallback only**, for the brief window before the sky has actually
/// baked (`SkyLutCache.panelAmbient` is still null): the table only knows the
/// weather *type*, not the time of day, so `clear`/`cloudy`/`snow`/`fog`/`auto`
/// all resolve to "light" even at night — a clear night sky is the darkest
/// thing on screen, and this alone would pick near-black ink for it. Once a
/// sky colour exists, [skyIsLightFrom] must be used instead.
bool weatherSkyIsLight(WeatherMode mode) => switch (mode) {
  WeatherMode.rain ||
  WeatherMode.thunderstorm ||
  WeatherMode.overcast ||
  WeatherMode.sand => false,
  WeatherMode.clear ||
  WeatherMode.cloudy ||
  WeatherMode.snow ||
  WeatherMode.fog ||
  WeatherMode.auto => true,
};

/// Whether [sky] — the actual rendered sky colour (`SkyLutCache.panelAmbient`)
/// — is light enough that dark foregrounds read better than white.
///
/// This is what every ink-on-sky decision should call: [weatherSkyIsLight]
/// alone can only guess from the weather *type*, and the same "clear" sky is
/// bright blue at noon and near-black past sunset. Falls back to
/// [weatherSkyIsLight] only while [sky] is still null (nothing has baked yet),
/// so ink is never left unset before the first frame.
///
/// Uses [ThemeData.estimateBrightnessForColor] rather than a hand-picked
/// luminance cutoff — it is the same "is this background light or dark"
/// judgment Flutter already ships and tunes, so a border-hue sky (dawn, a
/// hazy overcast) resolves the way the rest of the framework would resolve it.
bool skyIsLightFrom(Color? sky, WeatherMode fallbackMode) {
  if (sky == null) return weatherSkyIsLight(fallbackMode);
  return ThemeData.estimateBrightnessForColor(sky) == Brightness.light;
}

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
