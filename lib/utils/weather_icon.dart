import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/core/i18n.dart';

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
      0: '取得天氣異常'.i18n,
      100: '晴'.i18n,
      101: '晴有霾'.i18n,
      102: '晴有靄'.i18n,
      103: '晴有閃電'.i18n,
      104: '晴天伴有雷'.i18n,
      105: '晴有霧'.i18n,
      106: '晴有雨'.i18n,
      107: '晴有雨雪'.i18n,
      108: '晴有大雪'.i18n,
      109: '晴有雪珠'.i18n,
      110: '晴有冰珠'.i18n,
      111: '晴有陣雪'.i18n,
      112: '晴陣雨雪'.i18n,
      113: '晴有雹'.i18n,
      114: '晴有雷雨'.i18n,
      115: '晴有雷雪'.i18n,
      116: '晴有雷雹'.i18n,
      117: '晴大雷雨'.i18n,
      118: '晴大雷雹'.i18n,
      119: '晴天伴有雷'.i18n,
      200: '多雲'.i18n,
      201: '多雲有霾'.i18n,
      202: '多雲有靄'.i18n,
      203: '多雲有閃電'.i18n,
      204: '多雲伴有雷'.i18n,
      205: '多雲有霧'.i18n,
      206: '多雲有雨'.i18n,
      207: '多雲有雨雪'.i18n,
      208: '多雲有大雪'.i18n,
      209: '多雲有雪珠'.i18n,
      210: '多雲有冰珠'.i18n,
      211: '多雲有陣雪'.i18n,
      212: '多雲陣雨雪'.i18n,
      213: '多雲有雹'.i18n,
      214: '多雲有雷雨'.i18n,
      215: '多雲有雷雪'.i18n,
      216: '多雲有雷雹'.i18n,
      217: '多雲大雷雨'.i18n,
      218: '多雲大雷雹'.i18n,
      219: '多雲伴有雷'.i18n,
      300: '陰'.i18n,
      301: '陰有霾'.i18n,
      302: '陰有靄'.i18n,
      303: '陰有閃電'.i18n,
      304: '陰天伴有雷'.i18n,
      305: '陰有霧'.i18n,
      306: '陰有雨'.i18n,
      307: '陰有雨雪'.i18n,
      308: '陰有大雪'.i18n,
      309: '陰有雪珠'.i18n,
      310: '陰有冰珠'.i18n,
      311: '陰有陣雪'.i18n,
      312: '陰陣雨雪'.i18n,
      313: '陰有雹'.i18n,
      314: '陰有雷雨'.i18n,
      315: '陰有雷雪'.i18n,
      316: '陰有雷雹'.i18n,
      317: '陰大雷雨'.i18n,
      318: '陰大雷雹'.i18n,
      319: '陰天伴有雷'.i18n,
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
