/// The weather animation shown behind the home screen.
///
/// [auto] follows real conditions (or a sensible default until a weather feed
/// is wired up); the rest force a fixed look for testing and demos.
enum WeatherMode {
  /// Follow real weather conditions.
  auto,

  /// Clear sky.
  clear,

  /// Broken cloud.
  cloudy,

  /// Solid overcast.
  overcast,

  /// Rain.
  rain,

  /// Snow.
  snow,

  /// Blowing dust.
  sand,

  /// Heavy fog / mist.
  fog,

  /// Thunderstorm (rain + lightning).
  thunderstorm,
}
