import 'dart:math' as math;

/// CWA outdoor, ventilated, shaded apparent temperature in degrees Celsius.
double? currentApparentTemperature({
  required double? temperature,
  required int? humidity,
  required double? windSpeed,
}) {
  if (temperature == null ||
      humidity == null ||
      windSpeed == null ||
      !temperature.isFinite ||
      !windSpeed.isFinite ||
      humidity < 0 ||
      humidity > 100 ||
      windSpeed < 0) {
    return null;
  }

  final vapourPressure =
      (humidity / 100) *
      6.105 *
      math.exp(17.27 * temperature / (237.7 + temperature));
  final apparentTemperature =
      1.04 * temperature + 0.2 * vapourPressure - 0.65 * windSpeed - 2.7;
  return apparentTemperature.isFinite ? apparentTemperature : null;
}
