/// CWB weather-condition codes → icon and backdrop mode.
///
/// l10n-ignore-file: CJK substrings match the API's weather tokens (晴/多雲/…),
/// not user-facing copy — the server labels are Traditional Chinese only.
library;

import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/core/weather/weather_icons.dart';
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

/// Ones digit → a distinct glyph, finer than the eight backdrop modes.
///
/// Drawn from the bundled weather font, which exists precisely because
/// Flutter's icon set has no rain glyph: the three rain intensities, the
/// rain-snow mixes and hail are all unavailable in `Icons`, so the table below
/// used to approximate them with snowflakes and dots.
///
/// `0` (the plain family sky) is absent on purpose — it resolves through
/// [_familySky], which also chooses between the day and night glyph. The
/// accent colour still follows [weatherModeFor], so a phenomenon only refines
/// the glyph, never the tint.
///
/// A few suffixes deliberately share a glyph, because they name the same
/// picture at different strengths (有霾/有靄; 有閃電/有雷聲/有雷; the three
/// hail codes) — the strength is carried by [weatherRainIntensity] and the
/// backdrop, not by inventing a distinction the icon cannot show.
const Map<int, IconData> _phenomenonIcon = {
  1: mist, // 有霾 — suspended dust: streaks, no cloud
  2: mist, // 有靄 — light mist, the same picture as 霾
  3: bolt, // 有閃電 — lightning with no rain on the ground
  4: bolt, // 有雷聲
  5: foggy, // 有霧 — a real fog bank reads denser than 霾
  6: rainy, // 有雨 — steady rain
  7: rainySnow, // 有雨雪 — the dedicated rain-and-snow glyph
  8: snowingHeavy, // 有大雪
  9: weatherSnowy, // 有雪珠 — graupel
  10: snowflake, // 有冰珠 — bare ice crystals
  11: rainyLight, // 有陣雨 — a shower, lighter than steady 有雨
  12: weatherMix, // 陣雨雪 — intermittent mixed precipitation
  13: weatherHail, // 有雹
  14: thunderstorm, // 有雷雨
  15: cloudySnowing, // 有雷雪 — snow from a storm cloud
  16: weatherHail, // 有雷雹 — hail is the distinguishing hazard
  17: rainyHeavy, // 大雷雨 — torrential; the rain is what does the damage
  18: weatherHail, // 大雷雹
  19: bolt, // 有雷
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

/// The plain-sky glyph for a family, by daylight.
///
/// This is the one place day and night differ: a clear midnight drawn as a sun
/// is wrong in a way every user notices, and 陰 (full overcast) is the same
/// picture either way because there is nothing behind the cloud to show.
IconData _familySky(WeatherMode mode, {required bool isNight}) =>
    switch (mode) {
      WeatherMode.clear => isNight ? clearNight : clearDay,
      WeatherMode.cloudy => isNight ? partlyCloudyNight : partlyCloudyDay,
      _ => cloudy,
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
/// when the suffix has one, then the family sky for the plain `0` suffix, and
/// only a missing/unknown code falls back to the text. The accent colour always
/// follows the resolved mode, so 陣雨 and 大雷雨 share their family's tint while
/// still reading as different glyphs.
///
/// [isNight] only selects between the day and night form of a plain sky; a
/// phenomenon looks the same at any hour.
(IconData, Color?) weatherVisual(
  String weather,
  int weatherCode,
  ColorScheme colors, {
  bool isNight = false,
}) {
  if (weatherCode > 0) {
    final phenomenon = _phenomenonIcon[weatherCode % 100];
    if (phenomenon != null) {
      return (phenomenon, _accent(weatherModeFor(weatherCode), colors));
    }
  }
  final mode = weatherModeFor(weatherCode);
  return switch (mode) {
    // A missing/unknown code has no mode to key off — fall back to the text.
    WeatherMode.auto => _fallback(weather, colors, isNight: isNight),
    WeatherMode.thunderstorm => (thunderstorm, colors.tertiary),
    WeatherMode.snow => (snowing, colors.primary),
    WeatherMode.rain => (rainy, colors.primary),
    WeatherMode.fog => (foggy, colors.onSurfaceVariant),
    WeatherMode.sand => (air, colors.onSurfaceVariant),
    WeatherMode.clear || WeatherMode.cloudy || WeatherMode.overcast => (
      _familySky(mode, isNight: isNight),
      _accent(mode, colors),
    ),
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
(IconData, Color?) _fallback(
  String weather,
  ColorScheme colors, {
  required bool isNight,
}) {
  if (weather.contains('雷')) return (thunderstorm, colors.tertiary);
  if (weather.contains('雪')) return (snowing, colors.primary);
  if (weather.contains('雨')) return (rainy, colors.primary);
  if (weather.contains('霧') || weather.contains('靄')) {
    return (foggy, colors.onSurfaceVariant);
  }
  if (weather.contains('晴')) {
    return (isNight ? clearNight : clearDay, colors.tertiary);
  }
  if (weather.contains('多雲')) {
    return (
      isNight ? partlyCloudyNight : partlyCloudyDay,
      colors.onSurfaceVariant,
    );
  }
  return (cloudy, colors.onSurfaceVariant);
}
