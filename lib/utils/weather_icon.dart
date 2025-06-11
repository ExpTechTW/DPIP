import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class WeatherIcons {
  WeatherIcons._();

  static const Map<String, IconData> iconMap = {
    'sunny': Symbols.sunny_rounded,
    'nightlight': Symbols.nightlight_rounded,
    'partly_cloudy_day': Symbols.partly_cloudy_day_rounded,
    'partly_cloudy_night': Symbols.partly_cloudy_night_rounded,
    'cloudy': Symbols.cloud_rounded,
    'foggy': Symbols.foggy_rounded,
    'rainy': Symbols.rainy_rounded,
    'snowy': Symbols.ac_unit_rounded,
    'rainy_snow': Symbols.weather_mix_rounded,
    'thunderstorm': Symbols.thunderstorm_rounded,
    'hail': Symbols.grain_rounded,
    'unknown': Symbols.error_rounded,
  };

  static final Map<int, Map<String, dynamic>> weatherCodeMap = {
    // Sunny (晴)
    100: {
      'icon': {'day': 'sunny', 'night': 'nightlight'},
      'key': 'sunny',
    },
    101: {
      'icon': {'day': 'sunny', 'night': 'nightlight'},
      'key': 'sunny_haze',
    },
    102: {
      'icon': {'day': 'sunny', 'night': 'nightlight'},
      'key': 'sunny_mist',
    },
    103: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_lightning',
    },
    104: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_thunder',
    },
    105: {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'key': 'sunny_fog',
    },
    106: {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'key': 'sunny_rain',
    },
    107: {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'key': 'sunny_rain_snow',
    },
    108: {
      'icon': {'day': 'snowy', 'night': 'snowy'},
      'key': 'sunny_heavy_snow',
    },
    109: {
      'icon': {'day': 'snowy', 'night': 'snowy'},
      'key': 'sunny_snow_pellets',
    },
    110: {
      'icon': {'day': 'hail', 'night': 'hail'},
      'key': 'sunny_ice_pellets',
    },
    111: {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'key': 'sunny_showers',
    },
    112: {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'key': 'sunny_rain_snow_showers',
    },
    113: {
      'icon': {'day': 'hail', 'night': 'hail'},
      'key': 'sunny_hail',
    },
    114: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_thunderstorm',
    },
    115: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_thunder_snow',
    },
    116: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_thunder_hail',
    },
    117: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_heavy_thunderstorm',
    },
    118: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_heavy_thunder_hail',
    },
    119: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'sunny_thunder',
    },

    // Cloudy (多雲)
    200: {
      'icon': {'day': 'partly_cloudy_day', 'night': 'partly_cloudy_night'},
      'key': 'cloudy',
    },
    201: {
      'icon': {'day': 'partly_cloudy_day', 'night': 'partly_cloudy_night'},
      'key': 'cloudy_haze',
    },
    202: {
      'icon': {'day': 'partly_cloudy_day', 'night': 'partly_cloudy_night'},
      'key': 'cloudy_mist',
    },
    203: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_lightning',
    },
    204: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_thunder',
    },
    205: {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'key': 'cloudy_fog',
    },
    206: {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'key': 'cloudy_rain',
    },
    207: {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'key': 'cloudy_rain_snow',
    },
    208: {
      'icon': {'day': 'snowy', 'night': 'snowy'},
      'key': 'cloudy_heavy_snow',
    },
    209: {
      'icon': {'day': 'snowy', 'night': 'snowy'},
      'key': 'cloudy_snow_pellets',
    },
    210: {
      'icon': {'day': 'hail', 'night': 'hail'},
      'key': 'cloudy_ice_pellets',
    },
    211: {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'key': 'cloudy_showers',
    },
    212: {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'key': 'cloudy_rain_snow_showers',
    },
    213: {
      'icon': {'day': 'hail', 'night': 'hail'},
      'key': 'cloudy_hail',
    },
    214: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_thunderstorm',
    },
    215: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_thunder_snow',
    },
    216: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_thunder_hail',
    },
    217: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_heavy_thunderstorm',
    },
    218: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_heavy_thunder_hail',
    },
    219: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'cloudy_thunder',
    },

    // Overcast (陰)
    300: {
      'icon': {'day': 'cloudy', 'night': 'cloudy'},
      'key': 'overcast',
    },
    301: {
      'icon': {'day': 'cloudy', 'night': 'cloudy'},
      'key': 'overcast_haze',
    },
    302: {
      'icon': {'day': 'cloudy', 'night': 'cloudy'},
      'key': 'overcast_mist',
    },
    303: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_lightning',
    },
    304: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_thunder',
    },
    305: {
      'icon': {'day': 'foggy', 'night': 'foggy'},
      'key': 'overcast_fog',
    },
    306: {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'key': 'overcast_rain',
    },
    307: {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'key': 'overcast_rain_snow',
    },
    308: {
      'icon': {'day': 'snowy', 'night': 'snowy'},
      'key': 'overcast_heavy_snow',
    },
    309: {
      'icon': {'day': 'snowy', 'night': 'snowy'},
      'key': 'overcast_snow_pellets',
    },
    310: {
      'icon': {'day': 'hail', 'night': 'hail'},
      'key': 'overcast_ice_pellets',
    },
    311: {
      'icon': {'day': 'rainy', 'night': 'rainy'},
      'key': 'overcast_showers',
    },
    312: {
      'icon': {'day': 'rainy_snow', 'night': 'rainy_snow'},
      'key': 'overcast_rain_snow_showers',
    },
    313: {
      'icon': {'day': 'hail', 'night': 'hail'},
      'key': 'overcast_hail',
    },
    314: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_thunderstorm',
    },
    315: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_thunder_snow',
    },
    316: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_thunder_hail',
    },
    317: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_heavy_thunderstorm',
    },
    318: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_heavy_thunder_hail',
    },
    319: {
      'icon': {'day': 'thunderstorm', 'night': 'thunderstorm'},
      'key': 'overcast_thunder',
    },
  };

  static IconData getWeatherIcon(int code, bool isDay) {
    final weatherInfo = weatherCodeMap[code];
    if (weatherInfo != null) {
      final iconName = isDay ? weatherInfo['icon']['day'] : weatherInfo['icon']['night'];
      return iconMap[iconName] ?? Symbols.error_rounded;
    }
    return Symbols.error_rounded;
  }

  static String getWeatherContent(BuildContext context, int code) {
    final Map<int, String> iconLabel = {
      0: '取得天氣異常',
      100: '晴',
      101: '晴有霾',
      102: '晴有靄',
      103: '晴有閃電',
      104: '晴天伴有雷',
      105: '晴有霧',
      106: '晴有雨',
      107: '晴有雨雪',
      108: '晴有大雪',
      109: '晴有雪珠',
      110: '晴有冰珠',
      111: '晴有陣雪',
      112: '晴陣雨雪',
      113: '晴有雹',
      114: '晴有雷雨',
      115: '晴有雷雪',
      116: '晴有雷雹',
      117: '晴大雷雨',
      118: '晴大雷雹',
      119: '晴天伴有雷',
      200: '多雲',
      201: '多雲有霾',
      202: '多雲有靄',
      203: '多雲有閃電',
      204: '多雲伴有雷',
      205: '多雲有霧',
      206: '多雲有雨',
      207: '多雲有雨雪',
      208: '多雲有大雪',
      209: '多雲有雪珠',
      210: '多雲有冰珠',
      211: '多雲有陣雪',
      212: '多雲陣雨雪',
      213: '多雲有雹',
      214: '多雲有雷雨',
      215: '多雲有雷雪',
      216: '多雲有雷雹',
      217: '多雲大雷雨',
      218: '多雲大雷雹',
      219: '多雲伴有雷',
      300: '陰',
      301: '陰有霾',
      302: '陰有靄',
      303: '陰有閃電',
      304: '陰天伴有雷',
      305: '陰有霧',
      306: '陰有雨',
      307: '陰有雨雪',
      308: '陰有大雪',
      309: '陰有雪珠',
      310: '陰有冰珠',
      311: '陰有陣雪',
      312: '陰陣雨雪',
      313: '陰有雹',
      314: '陰有雷雨',
      315: '陰有雷雪',
      316: '陰有雷雹',
      317: '陰大雷雨',
      318: '陰大雷雹',
      319: '陰天伴有雷',
      // 103: context.i18n.partly_cloudy,
      // 106: context.i18n.cloudy,
      // 109: context.i18n.overcast,
      // 130: context.i18n.foggy,
      // 163: context.i18n.patchy_rain_possible,
      // 166: context.i18n.patchy_snow_possible,
      // 169: context.i18n.patchy_sleet_possible,
      // 172: context.i18n.patchy_freezing_drizzle_possible,
      // 187: context.i18n.thundery_outbreaks_possible,
      // 114: context.i18n.blowing_snow,
      // 117: context.i18n.blizzard,
      // 135: context.i18n.fog,
      // 147: context.i18n.freezing_fog,
      // 150: context.i18n.patchy_light_drizzle,
      // 153: context.i18n.light_drizzle,
      // 168: context.i18n.freezing_drizzle,
      // 171: context.i18n.heavy_freezing_drizzle,
      // 180: context.i18n.patchy_light_rain,
      // 183: context.i18n.light_rain,
      // 186: context.i18n.moderate_rain_at_times,
      // 189: context.i18n.moderate_rain,
      // 192: context.i18n.heavy_rain_at_times,
      // 195: context.i18n.heavy_rain,
      // 198: context.i18n.light_freezing_rain,
      // 201: context.i18n.moderate_or_heavy_freezing_rain,
      // 204: context.i18n.light_sleet,
      // 207: context.i18n.moderate_or_heavy_sleet,
      // 210: context.i18n.patchy_light_snow,
      // 213: context.i18n.light_snow,
      // 216: context.i18n.patchy_moderate_snow,
      // 219: context.i18n.moderate_snow,
      // 222: context.i18n.patchy_heavy_snow,
      // 225: context.i18n.heavy_snow,
      // 237: context.i18n.ice_pellets,
      // 240: context.i18n.light_rain_shower,
      // 243: context.i18n.moderate_or_heavy_rain_shower,
      // 246: context.i18n.torrential_rain_shower,
      // 249: context.i18n.light_sleet_showers,
      // 252: context.i18n.moderate_or_heavy_sleet_showers,
      // 255: context.i18n.light_snow_showers,
      // 258: context.i18n.moderate_or_heavy_snow_showers,
      // 261: context.i18n.light_showers_of_ice_pellets,
      // 264: context.i18n.moderate_or_heavy_showers_of_ice_pellets,
      // 273: context.i18n.patchy_light_rain_with_thunder,
      // 276: context.i18n.moderate_or_heavy_rain_with_thunder,
      // 279: context.i18n.patchy_light_snow_with_thunder,
      // 282: context.i18n.moderate_or_heavy_snow_with_thunder,
    };

    return iconLabel[code] ?? 'Unknown weather';
  }

  static String mapNumberToWeather(int number) {
    final weatherInfo = weatherCodeMap[number];
    if (weatherInfo != null) {
      return weatherInfo['key'] as String;
    }
    return 'unknown_weather';
  }
}
