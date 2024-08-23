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
      'content': {
        'zh': '晴',
        'en': 'Sunny',
      }
    },
    '1003': {
      'icon': {'day': 'partly_cloudy_day', 'night': 'partly_cloudy_night'},
      'content': {
        'zh': '多雲時晴',
        'en': 'Partly cloudy',
      }
    },
    '1006': {
      'icon': {'day': 'cloudy', 'night': 'cloudy'},
      'content': {
        'zh': '多雲',
        'en': 'Cloudy',
      }
    },
    '1009': {
      'icon': {'day': 'cloudy', 'night': 'cloudy'},
      'content': {
        'zh': '陰',
        'en': 'Overcast',
      }
    },
    '1030': {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'content': {
        'zh': '霧',
        'en': 'Mist',
      }
    },
    '1063': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '可能有局部降雨',
        'en': 'Patchy rain possible',
      }
    },
    '1066': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '可能有局部降雪',
        'en': 'Patchy snow possible',
      }
    },
    '1069': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '可能有局部雨夾雪',
        'en': 'Patchy sleet possible',
      }
    },
    '1072': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '可能有局部凍毛毛雨',
        'en': 'Patchy freezing drizzle possible',
      }
    },
    '1087': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': {
        'zh': '可能有局部雷雨',
        'en': 'Thundery outbreaks possible',
      }
    },
    '1114': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '高吹雪',
        'en': 'Blowing snow',
      }
    },
    '1117': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '暴風雪',
        'en': 'Blizzard',
      }
    },
    '1135': {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'content': {
        'zh': '霧',
        'en': 'Fog',
      }
    },
    '1147': {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'content': {
        'zh': '凍霧',
        'en': 'Freezing fog',
      }
    },
    '1150': {
      'icon': {'day': 'rainy_light', 'night': 'rainy_light'},
      'content': {
        'zh': '局部毛毛雨',
        'en': 'Patchy light drizzle',
      }
    },
    '1153': {
      'icon': {'day': 'rainy_light', 'night': 'rainy_light'},
      'content': {
        'zh': '毛毛雨',
        'en': 'Light drizzle',
      }
    },
    '1168': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '凍毛毛雨',
        'en': 'Freezing drizzle',
      }
    },
    '1171': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '大凍毛毛雨',
        'en': 'Heavy freezing drizzle',
      }
    },
    '1180': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '局部小雨',
        'en': 'Patchy light rain',
      }
    },
    '1183': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '小雨',
        'en': 'Light rain',
      }
    },
    '1186': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '間歇降雨',
        'en': 'Moderate rain at times',
      }
    },
    '1189': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '雨',
        'en': 'Moderate rain',
      }
    },
    '1192': {
      'icon': {'day': 'rainy_heavy', 'night': 'rainy_heavy'},
      'content': {
        'zh': '間歇大雨',
        'en': 'Heavy rain at times',
      }
    },
    '1195': {
      'icon': {'day': 'rainy_heavy', 'night': 'rainy_heavy'},
      'content': {
        'zh': '大雨',
        'en': 'Heavy rain',
      }
    },
    '1198': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '凍雨',
        'en': 'Light freezing rain',
      }
    },
    '1201': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '凍雨',
        'en': 'Moderate or heavy freezing rain',
      }
    },
    '1204': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '小雨夾雪',
        'en': 'Light sleet',
      }
    },
    '1207': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '雨夾雪',
        'en': 'Moderate or heavy sleet',
      }
    },
    '1210': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '局部小雪',
        'en': 'Patchy light snow',
      }
    },
    '1213': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '小雪',
        'en': 'Light snow',
      }
    },
    '1216': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '局部降雪',
        'en': 'Patchy moderate snow',
      }
    },
    '1219': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '雪',
        'en': 'Moderate snow',
      }
    },
    '1222': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '局部大雪',
        'en': 'Patchy heavy snow',
      }
    },
    '1225': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '大雪',
        'en': 'Heavy snow',
      }
    },
    '1237': {
      'icon': {'day': 'snowing', 'night': 'snowing'},
      'content': {
        'zh': '冰霰',
        'en': 'Ice pellets',
      }
    },
    '1240': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '小陣雨',
        'en': 'Light rain shower',
      }
    },
    '1243': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '陣雨',
        'en': 'Moderate or heavy rain shower',
      }
    },
    '1246': {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'content': {
        'zh': '大陣雨',
        'en': 'Torrential rain shower',
      }
    },
    '1249': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '小陣雨夾雪',
        'en': 'Light sleet showers',
      }
    },
    '1252': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '陣雨夾雪',
        'en': 'Moderate or heavy sleet showers',
      }
    },
    '1255': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '小陣雪',
        'en': 'Light snow showers',
      }
    },
    '1258': {
      'icon': {'day': 'ac_unit', 'night': 'ac_unit'},
      'content': {
        'zh': '陣雪',
        'en': 'Moderate or heavy snow showers',
      }
    },
    '1261': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '小陣雨伴隨冰霰',
        'en': 'Light showers of ice pellets',
      }
    },
    '1264': {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'content': {
        'zh': '陣雨伴隨冰霰',
        'en': 'Moderate or heavy showers of ice pellets',
      }
    },
    '1273': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': {
        'zh': '局部小雷雨',
        'en': 'Patchy light rain with thunder',
      }
    },
    '1276': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': {
        'zh': '雷雨',
        'en': 'Moderate or heavy rain with thunder',
      }
    },
    '1279': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': {
        'zh': '局部小雪伴雷',
        'en': 'Patchy light snow with thunder',
      }
    },
    '1282': {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'content': {
        'zh': '降雪伴雷',
        'en': 'Moderate or heavy snow with thunder',
      }
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

  static String getWeatherContent(String code, String languageCode) {
    final weatherInfo = weatherCodeMap[code];
    if (weatherInfo != null) {
      final content = weatherInfo['content'] as Map<String, String>;
      return content[languageCode] ?? content['en'] ?? 'Unknown weather';
    }
    return 'Unknown weather';
  }
}
