/// Forces the sky to a point in the day, independent of the weather.
///
/// The backdrop's look is the product of two things — the weather type and
/// where the keyframe ring currently sits — so testing it needs both axes.
/// Keeping time separate from [WeatherMode] gives every combination without
/// squaring the number of weather entries.
enum SkyTimeMode {
  /// Follow the real clock.
  auto,

  /// Just before sunrise — the blue hour.
  dawn,

  /// Sunrise.
  sunrise,

  /// Mid-morning.
  morning,

  /// Solar noon, the ring's peak.
  noon,

  /// Mid-afternoon.
  afternoon,

  /// The golden hour before sunset.
  golden,

  /// Sunset.
  sunset,

  /// After sunset — the blue hour again.
  dusk,

  /// Deep night.
  night,
}

/// The local hour each mode pins the sky to, or `null` for [SkyTimeMode.auto].
///
/// Hours are chosen against the 17-keyframe ring's own phase: it peaks at
/// keyframe 8, which an even split places at 11.3 h.
double? skyTimeHour(SkyTimeMode mode) => switch (mode) {
  SkyTimeMode.auto => null,
  SkyTimeMode.dawn => 5.0,
  SkyTimeMode.sunrise => 6.0,
  SkyTimeMode.morning => 8.5,
  SkyTimeMode.noon => 11.3,
  SkyTimeMode.afternoon => 15.0,
  SkyTimeMode.golden => 17.5,
  SkyTimeMode.sunset => 18.4,
  SkyTimeMode.dusk => 19.2,
  SkyTimeMode.night => 1.0,
};
