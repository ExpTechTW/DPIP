/// CWB weather-condition codes → icon and backdrop mode.
///
/// l10n-ignore-file: CJK substrings match the API's weather tokens (晴/多雲/…),
/// not user-facing copy — the server labels are Traditional Chinese only.
library;

import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter/material.dart';

/// The single mapping for CWB's weather-code table: families 100 (晴) / 200
/// (多雲) / 300 (陰), each carrying the same 20 phenomenon suffixes (ones
/// digits 1–19, `0` = the plain family sky). `0` alone means 缺值/未知.
///
/// Consumers never read the raw table — they call [weatherVisual] for the
/// icon/accent and [weatherModeFor] for the backdrop, so the code→look
/// decisions live in exactly one place.

/// Ones digit → backdrop mode. The suffix describes a phenomenon the family
/// base already classifies as sky cover; where the two conflict the phenomenon
/// wins — a clear-code 106 (有雨) is still rain.
const Map<int, WeatherMode> _phenomenonMode = {
  1: WeatherMode.fog, // 有霾
  2: WeatherMode.fog, // 有靄
  3: WeatherMode.thunderstorm, // 有閃電
  4: WeatherMode.thunderstorm, // 有雷聲
  5: WeatherMode.fog, // 有霧
  6: WeatherMode.rain, // 有雨
  7: WeatherMode.rain, // 有雨雪 — a rain-snow mix; rain is the dominant hazard
  8: WeatherMode.snow, // 有大雪
  9: WeatherMode.snow, // 有雪珠
  10: WeatherMode.snow, // 有冰珠
  11: WeatherMode.rain, // 有陣雨
  12: WeatherMode.snow, // 陣雨雪
  13: WeatherMode.rain, // 有雹
  14: WeatherMode.thunderstorm, // 有雷雨
  15: WeatherMode.thunderstorm, // 有雷雪
  16: WeatherMode.thunderstorm, // 有雷雹
  17: WeatherMode.thunderstorm, // 大雷雨
  18: WeatherMode.thunderstorm, // 大雷雹
  19: WeatherMode.thunderstorm, // 有雷
};

/// Ones digit → a distinct icon, finer than the eight backdrop modes.
///
/// `0` (the plain family sky) is absent here on purpose: a clear-day 100 must
/// stay a sun, not fall through to the text fallback. The [weatherModeFor]
/// mode still picks the accent colour, so a phenomenon only refines the glyph.
const Map<int, IconData> _phenomenonIcon = {
  1: Icons.blur_on_outlined, // 有霾 — suspended dust, not a fog bank
  2: Icons.blur_on_outlined, // 有靄
  3: Icons.bolt_outlined, // 有閃電 — lightning with no rain on the ground
  4: Icons.bolt_outlined, // 有雷聲
  5: Icons.foggy, // 有霧 — a real fog bank reads denser than 霾
  6: Icons.water_drop_outlined, // 有雨
  7: Icons.sunny_snowing, // 有雨雪 — the sun-through-snow glyph reads as the mix
  8: Icons.snowing, // 有大雪
  9: Icons.ac_unit_outlined, // 有雪珠
  10: Icons.ac_unit_outlined, // 有冰珠
  11: Icons.grain_outlined, // 有陣雨 — a shower, distinct from steady 有雨
  12: Icons.cloudy_snowing, // 陣雨雪
  13: Icons.grain_outlined, // 有雹
  14: Icons.thunderstorm_outlined, // 有雷雨
  15: Icons.thunderstorm_outlined, // 有雷雪
  16: Icons.thunderstorm_outlined, // 有雷雹
  17: Icons.thunderstorm, // 大雷雨 — filled: the heaviest rung, visually heavier
  18: Icons.thunderstorm, // 大雷雹
  19: Icons.bolt_outlined, // 有雷
};

/// The plain sky of a code's family (its hundreds digit), used when the ones
/// digit is `0` or unknown. `0` (缺值) and any unrecognised family fall back
/// to [WeatherMode.auto].
WeatherMode _familyMode(int code) => switch (code ~/ 100) {
  1 => WeatherMode.clear,
  2 => WeatherMode.cloudy,
  3 => WeatherMode.overcast,
  _ => WeatherMode.auto,
};

/// The backdrop mode for a CWB [code]: the phenomenon (ones digit) wins over
/// the family sky, and `0`/unknown codes fall back to [WeatherMode.auto].
WeatherMode weatherModeFor(int code) {
  if (code <= 0) return WeatherMode.auto;
  return _phenomenonMode[code % 100] ?? _familyMode(code);
}

/// Rain intensity for a CWB [code], on the painter's continuous ladder where
/// `0.321` is the 小雨 rung and `1.0` is 暴雨 — `null` when the code carries no
/// rain (the sky may still be rainy-looking through its mode's keyframes).
double? weatherRainIntensity(int code) {
  if (code <= 0) return null;
  return switch (code % 100) {
    // Lightning-only phenomena — the storm look, but the rain barely starts.
    3 || 4 || 19 => 0.15,
    6 || 11 => 0.35, // 有雨 / 有陣雨
    7 || 12 => 0.40, // 有雨雪 / 陣雨雪 — mixed; rain is the visible hazard
    13 => 0.50, // 有雹
    14 => 0.70, // 有雷雨
    16 || 18 => 0.85, // 有雷雹 / 大雷雹
    17 => 1.00, // 大雷雨
    _ => null,
  };
}

/// Snow intensity for a CWB [code], on the painter's continuous snow channel;
/// `null` when the code carries no snow.
double? weatherSnowIntensity(int code) {
  if (code <= 0) return null;
  return switch (code % 100) {
    8 => 1.0, // 有大雪
    10 => 0.6, // 有冰珠
    9 || 12 || 15 => 0.5, // 有雪珠 / 陣雨雪 / 有雷雪
    _ => null,
  };
}

/// Icon + accent for a forecast point's [weather] text and [weatherCode].
///
/// Codes are authoritative: the phenomenon's own icon ([_phenomenonIcon]) wins
/// when the suffix has one, then the family sky ([weatherModeFor]) for the
/// plain `0` suffix, and only a missing/unknown code falls back to the text.
/// The accent colour always follows the resolved mode, so 陣雨 and 大雷雨 share
/// their family's tint while still reading as different glyphs.
(IconData, Color?) weatherVisual(
  String weather,
  int weatherCode,
  ColorScheme colors,
) {
  if (weatherCode > 0) {
    final phenomenon = _phenomenonIcon[weatherCode % 100];
    if (phenomenon != null) {
      return (phenomenon, _accent(weatherModeFor(weatherCode), colors));
    }
  }
  final mode = weatherModeFor(weatherCode);
  return switch (mode) {
    // A missing/unknown code has no mode to key off — fall back to the text.
    WeatherMode.auto => _fallback(weather, colors),
    WeatherMode.thunderstorm => (Icons.thunderstorm_outlined, colors.tertiary),
    WeatherMode.snow => (Icons.ac_unit_outlined, colors.primary),
    WeatherMode.rain => (Icons.water_drop_outlined, colors.primary),
    WeatherMode.fog => (Icons.blur_on_outlined, colors.onSurfaceVariant),
    WeatherMode.sand => (Icons.air_outlined, colors.onSurfaceVariant),
    WeatherMode.clear => (Icons.wb_sunny_outlined, colors.tertiary),
    WeatherMode.cloudy => (Icons.wb_cloudy_outlined, colors.onSurfaceVariant),
    WeatherMode.overcast => (Icons.cloud_outlined, colors.onSurfaceVariant),
  };
}

/// The accent colour a mode's icons share.
Color? _accent(WeatherMode mode, ColorScheme colors) => switch (mode) {
  WeatherMode.clear || WeatherMode.thunderstorm => colors.tertiary,
  WeatherMode.rain || WeatherMode.snow => colors.primary,
  WeatherMode.fog ||
  WeatherMode.sand ||
  WeatherMode.cloudy ||
  WeatherMode.overcast => colors.onSurfaceVariant,
  WeatherMode.auto => null,
};

/// Text-only fallback for codes that resolve to [WeatherMode.auto] (missing or
/// unknown) — the pre-table substring matching.
(IconData, Color?) _fallback(String weather, ColorScheme colors) {
  if (weather.contains('雷')) {
    return (Icons.thunderstorm_outlined, colors.tertiary);
  }
  if (weather.contains('雪')) {
    return (Icons.ac_unit_outlined, colors.primary);
  }
  if (weather.contains('雨')) {
    return (Icons.water_drop_outlined, colors.primary);
  }
  if (weather.contains('晴')) {
    return (Icons.wb_sunny_outlined, colors.tertiary);
  }
  return (Icons.cloud_outlined, colors.onSurfaceVariant);
}
