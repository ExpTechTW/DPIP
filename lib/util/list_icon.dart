import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class WeatherIcons {
  static const Map<String, IconData> iconMap = {
    'sunny': Symbols.sunny,
    'nightlight': Symbols.nightlight,
    'partly_cloudy_day': Symbols.partly_cloudy_day,
    'partly_cloudy_night': Symbols.partly_cloudy_night,
    'cloudy': Symbols.cloud,
    'foggy': Symbols.foggy,
    'rainy': Symbols.rainy,
    'ac_unit': Symbols.ac_unit,
    'rainy_snow': Symbols.weather_mix,
    'thunderstorm': Symbols.thunderstorm,
    'rainy_light': Symbols.grain,
    'rainy_heavy': Symbols.water,
    'snowing': Symbols.snowing,
  };

  static IconData getListIcon(String name) {
    final weatherInfo = weatherCodeMap[code];
    if (weatherInfo != null) {
      final iconName = isDay == 1 ? weatherInfo['icon']['day'] : weatherInfo['icon']['night'];
      return iconMap[iconName] ?? Symbols.error;
    }
    return Symbols.error;
  }
}
