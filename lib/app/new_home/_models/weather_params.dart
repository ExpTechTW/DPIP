/// Continuous weights derived from realtime weather data, used to drive the
/// procedural sky background.
library;

import 'package:dpip/api/model/weather_schema.dart';

/// Resolves a time-of-day scene index for the sky shader.
///
/// `0` = day, `1` = night, `2` = dawn, `3` = sunset.
int resolveSkyScene(int hour) {
  if (hour < 5 || hour >= 19) return 1;
  if (hour < 7) return 2;
  if (hour >= 17) return 3;
  return 0;
}

/// Cloud coverage in `[0, 1]`.
///
/// Combines weather code (`2xx` partly cloudy = `0.50`, `3xx` overcast = `0.85`)
/// with a humidity boost above 60% and a small extra weight for cold humid air
/// (low temperature with high humidity tends to thicken cloud).
double cloudWeight(RealtimeWeatherData? d) {
  if (d == null) return 0;
  final base = switch (d.weatherCode ~/ 100) {
    2 => 0.50,
    3 => 0.85,
    _ => 0.0,
  };
  final humidityBoost = ((d.humidity - 60).clamp(0, 40) / 40.0) * 0.15;
  final coldHumid = (d.temperature < 15 && d.humidity > 80) ? 0.10 : 0.0;
  return (base + humidityBoost + coldHumid).clamp(0.0, 1.0);
}

/// Rain intensity in `[0, 1]`.
///
/// Takes the maximum of two signals: the weather-code precipitation type
/// (showers, thunderstorm, etc.) and the measured rainfall in mm/h, capped at
/// 5 mm/h for normalization.
double rainWeight(RealtimeWeatherData? d) {
  if (d == null) return 0;
  final fromCode = switch (d.weatherCode % 100) {
    3 || 4 => 0.55,
    6 || 11 => 0.45,
    7 || 12 => 0.40,
    14 || 17 => 0.65,
    18 || 19 => 0.85,
    _ => 0.0,
  };
  final fromAmount = (d.rain / 5.0).clamp(0.0, 1.0);
  return fromCode > fromAmount ? fromCode : fromAmount;
}

/// Wind strength in `[0, 1]` from the Beaufort scale, normalized at force 8.
double windWeight(RealtimeWeatherData? d) {
  if (d == null) return 0.3;
  return (d.wind.beaufort / 8.0).clamp(0.0, 1.0);
}

/// Solar phase in `[0, 1]` across the visible window from 5am to 7pm.
///
/// `0.0` ≈ sunrise at the eastern edge, `0.5` ≈ noon overhead,
/// `1.0` ≈ sunset at the western edge. The shader maps this to a horizontal
/// arc, so the sun is no longer pinned to the screen center.
double sunPhase(DateTime now) {
  final h = now.hour + now.minute / 60.0;
  return ((h - 5.0) / 14.0).clamp(0.0, 1.0);
}
