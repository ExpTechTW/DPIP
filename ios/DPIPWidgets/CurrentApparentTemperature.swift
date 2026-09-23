import Foundation

/// CWA outdoor, ventilated, shaded apparent temperature in degrees Celsius.
func currentApparentTemperature(
    temperature: Double?,
    humidity: Int?,
    windSpeed: Double?
) -> Double? {
    guard let temperature, let humidity, let windSpeed,
          temperature.isFinite, windSpeed.isFinite,
          (0...100).contains(humidity), windSpeed >= 0 else {
        return nil
    }

    let vapourPressure = Double(humidity) / 100 * 6.105
        * exp(17.27 * temperature / (237.7 + temperature))
    let apparentTemperature = 1.04 * temperature + 0.2 * vapourPressure
        - 0.65 * windSpeed - 2.7
    return apparentTemperature.isFinite ? apparentTemperature : nil
}
