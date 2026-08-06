/// Icon + accent for a forecast weather condition.
///
/// l10n-ignore-file: CJK substrings match API `weather` tokens (晴/雨/…), not
/// user-facing copy — the server labels are Traditional Chinese only.
library;

import 'package:flutter/material.dart';

/// Maps a forecast point's [weather] text and [weatherCode] to a Material icon
/// and an optional accent colour.
///
/// Legacy matched Chinese substrings in `weather` (晴/雨/雲/陰/雷/雪). Rewrite
/// prefers [weatherCode] hundreds (100 clear / 200 cloudy / 300 overcast) and
/// still falls back to the text for rain / thunder / snow, which the hundreds
/// band alone does not distinguish.
(IconData, Color?) forecastWeatherVisual(
  String weather,
  int weatherCode,
  ColorScheme colors,
) {
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
  return switch (weatherCode ~/ 100) {
    1 => (Icons.wb_sunny_outlined, colors.tertiary),
    2 => (Icons.wb_cloudy_outlined, colors.onSurfaceVariant),
    3 => (Icons.cloud_outlined, colors.onSurfaceVariant),
    _ =>
      weather.contains('雲') || weather.contains('陰')
          ? (Icons.cloud_outlined, colors.onSurfaceVariant)
          : (Icons.cloud_outlined, colors.onSurfaceVariant),
  };
}
