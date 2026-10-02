/// Pure semantic classification for CWB weather-condition codes.
library;

/// The weather meaning shared by Flutter visuals and platform transports.
enum WeatherCondition {
  clear,
  cloudy,
  overcast,
  rain,
  thunderstorm,
  snow,
  fog,
  unknown,
}

/// Weather-code suffix → weather phenomenon.
///
/// The phenomenon wins over the family sky: `106` is rain even though it is
/// in the clear-sky family. This is the authoritative suffix classification.
const Map<int, WeatherCondition> _phenomenonCondition = {
  1: WeatherCondition.fog, // 有霾
  2: WeatherCondition.fog, // 有靄
  3: WeatherCondition.thunderstorm, // 有閃電
  4: WeatherCondition.thunderstorm, // 有雷聲
  5: WeatherCondition.fog, // 有霧
  6: WeatherCondition.rain, // 有雨
  7: WeatherCondition.rain, // 有雨雪 — rain is the dominant hazard
  8: WeatherCondition.snow, // 有大雪
  9: WeatherCondition.snow, // 有雪珠
  10: WeatherCondition.snow, // 有冰珠
  11: WeatherCondition.rain, // 有陣雨
  12: WeatherCondition.snow, // 陣雨雪
  13: WeatherCondition.rain, // 有雹
  14: WeatherCondition.thunderstorm, // 有雷雨
  15: WeatherCondition.thunderstorm, // 有雷雪
  16: WeatherCondition.thunderstorm, // 有雷雹
  17: WeatherCondition.thunderstorm, // 大雷雨
  18: WeatherCondition.thunderstorm, // 大雷雹
  19: WeatherCondition.thunderstorm, // 有雷
};

/// Classifies a CWB [code] without depending on Flutter presentation types.
WeatherCondition weatherConditionForCode(int code) {
  if (code <= 0) return WeatherCondition.unknown;

  final phenomenon = _phenomenonCondition[code % 100];
  if (phenomenon != null) return phenomenon;

  return switch (code ~/ 100) {
    1 => WeatherCondition.clear,
    2 => WeatherCondition.cloudy,
    3 => WeatherCondition.overcast,
    _ => WeatherCondition.unknown,
  };
}
