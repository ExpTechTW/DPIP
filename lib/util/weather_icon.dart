import 'package:dpip/util/extension/build_context.dart';
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

  static final Map<String, Map<String, dynamic>> weatherCodeMap = {
    '1000': {
      'icon': {'day': 'sunny', 'night': 'nightlight'},
    },
    '1003': {
      'icon': {'day': 'partly_cloudy_day', 'night': 'partly_cloudy_night'},
      'content': 'Partly cloudy',
    },
    '1006': {
      'icon': {'day': 'cloudy', 'night': 'cloudy'},
      'content': 'Cloudy',
    },
    '1009': {
      'icon': {'day': 'cloudy', 'night': 'cloudy'},
      'content': 'Overcast',
    },
    '1030': {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'content': 'Mist',
    },
    '1063': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Patchy rain possible',
    },
    '1066': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Patchy snow possible',
    },
    '1069': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Patchy sleet possible',
    },
    '1072': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Patchy freezing drizzle possible',
    },
    '1087': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': 'Thundery outbreaks possible',
    },
    '1114': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Blowing snow',
    },
    '1117': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Blizzard',
    },
    '1135': {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'content': 'Fog',
    },
    '1147': {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'content': 'Freezing fog',
    },
    '1150': {
      'icon': {'day': 'rainy_light', 'night': 'rainy_light'},
      'content': 'Patchy light drizzle',
    },
    '1153': {
      'icon': {'day': 'rainy_light', 'night': 'rainy_light'},
      'content': 'Light drizzle',
    },
    '1168': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Freezing drizzle',
    },
    '1171': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Heavy freezing drizzle',
    },
    '1180': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Patchy light rain',
    },
    '1183': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Light rain',
    },
    '1186': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Moderate rain at times',
    },
    '1189': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Moderate rain',
    },
    '1192': {
      'icon': {'day': 'rainy_heavy', 'night': 'rainy_heavy'},
      'content': 'Heavy rain at times',
    },
    '1195': {
      'icon': {'day': 'rainy_heavy', 'night': 'rainy_heavy'},
      'content': 'Heavy rain',
    },
    '1198': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Light freezing rain',
    },
    '1201': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Moderate or heavy freezing rain',
    },
    '1204': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Light sleet',
    },
    '1207': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Moderate or heavy sleet',
    },
    '1210': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Patchy light snow',
    },
    '1213': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Light snow',
    },
    '1216': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Patchy moderate snow',
    },
    '1219': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Moderate snow',
    },
    '1222': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Patchy heavy snow',
    },
    '1225': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Heavy snow',
    },
    '1237': {
      'icon': {'day': 'snowing', 'night': 'snowing'},
      'content': 'Ice pellets',
    },
    '1240': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Light rain shower',
    },
    '1243': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Moderate or heavy rain shower',
    },
    '1246': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': 'Torrential rain shower',
    },
    '1249': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Light sleet showers',
    },
    '1252': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Moderate or heavy sleet showers',
    },
    '1255': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Light snow showers',
    },
    '1258': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': 'Moderate or heavy snow showers',
    },
    '1261': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Light showers of ice pellets',
    },
    '1264': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': 'Moderate or heavy showers of ice pellets',
    },
    '1273': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': 'Patchy light rain with thunder',
    },
    '1276': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': 'Moderate or heavy rain with thunder',
    },
    '1279': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': 'Patchy light snow with thunder',
    },
    '1282': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': 'Moderate or heavy snow with thunder',
    },
  };

  static IconData getWeatherIcon(String code, int isDay) {
    final weatherInfo = weatherCodeMap[code];
    if (weatherInfo != null) {
      final iconName = isDay == 1 ? weatherInfo['icon']['day'] : weatherInfo['icon']['night'];
      return iconMap[iconName] ?? Symbols.error;
    }
    return Symbols.error;
  }

  static String getWeatherContent(BuildContext context, String code) {
    Map<String, String> iconLabel = {
      '1000': context.i18n.weather_sunny,
      'nightlight': context.i18n.weather_nightlight,
      'partly_cloudy_day': context.i18n.weather_partly_cloudy_day,
      'partly_cloudy_night': context.i18n.weather_partly_cloudy_night,
      'cloudy': context.i18n.weather_cloud,
      'foggy': context.i18n.weather_foggy,
      'rainy': context.i18n.weather_rainy,
      'ac_unit': context.i18n.weather_ac_unit,
      'rainy_snow': context.i18n.weather_weather_mix,
      'thunderstorm': context.i18n.weather_thunderstorm,
      'rainy_light': context.i18n.weather_grain,
      'rainy_heavy': context.i18n.weather_water,
      'snowing': context.i18n.weather_snowing,
    };

    return iconLabel[code] ?? 'Unknown weather';
  }
}
