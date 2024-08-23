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
      '1000': context.i18n.sunny,
      '1003': context.i18n.partly_cloudy_day,
      '1006': context.i18n.cloudy,
      '1009': context.i18n.overcast,
      // '1030': context.i18n.foggy,
      // '1063': context.i18n.,
      // '1066': context.i18n.,
      // '1069': context.i18n.,
      // '1072': context.i18n.,
      // '1087': context.i18n.,
      // '1114': context.i18n.,
      // '1117': context.i18n.,
      // '1135': context.i18n.,
      // '1147': context.i18n.,
      // '1150': context.i18n.,
      // '1153': context.i18n.,
      // '1168': context.i18n.,
      // '1171': context.i18n.,
      // '1180': context.i18n.,
      // '1183': context.i18n.,
      // '1186': context.i18n.,
      // '1189': context.i18n.,
      // '1192': context.i18n.,
      // '1195': context.i18n.,
      // '1198': context.i18n.,
      // '1201': context.i18n.,
      // '1204': context.i18n.,
      // '1207': context.i18n.,
      // '1210': context.i18n.,
      // '1213': context.i18n.,
      // '1216': context.i18n.,
      // '1219': context.i18n.,
      // '1222': context.i18n.,
      // '1225': context.i18n.,
      // '1237': context.i18n.,
      // '1240': context.i18n.,
      // '1243': context.i18n.,
      // '1246': context.i18n.,
      // '1249': context.i18n.,
      // '1252': context.i18n.,
      // '1255': context.i18n.,
      // '1258': context.i18n.,
      // '1261': context.i18n.,
      // '1264': context.i18n.,
      // '1273': context.i18n.,
      // '1276': context.i18n.,
      // '1279': context.i18n.,
      // '1282': context.i18n.,
    };

    return iconLabel[code] ?? 'Unknown weather';
  }
}
