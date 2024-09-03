import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";

class WeatherIcons {
  static const Map<String, IconData> iconMap = {
    "sunny": Symbols.sunny,
    "nightlight": Symbols.nightlight,
    "partly_cloudy_day": Symbols.partly_cloudy_day,
    "partly_cloudy_night": Symbols.partly_cloudy_night,
    "cloudy": Symbols.cloud,
    "foggy": Symbols.foggy,
    "rainy": Symbols.rainy,
    "snowy": Symbols.ac_unit,
    "rainy_snow": Symbols.weather_mix,
    "thunderstorm": Symbols.thunderstorm,
    "hail": Symbols.grain,
    "unknown": Symbols.error,
  };

  static final Map<int, Map<String, dynamic>> weatherCodeMap = {
    // Sunny (晴)
    100: {
      "icon": {"day": "sunny", "night": "nightlight"},
      "key": "sunny"
    },
    101: {
      "icon": {"day": "sunny", "night": "nightlight"},
      "key": "sunny_haze"
    },
    102: {
      "icon": {"day": "sunny", "night": "nightlight"},
      "key": "sunny_mist"
    },
    103: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_lightning"
    },
    104: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_thunder"
    },
    105: {
      "icon": {"day": "foggy", "night": "foggy"},
      "key": "sunny_fog"
    },
    106: {
      "icon": {"day": "rainy", "night": "rainy"},
      "key": "sunny_rain"
    },
    107: {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
      "key": "sunny_rain_snow"
    },
    108: {
      "icon": {"day": "snowy", "night": "snowy"},
      "key": "sunny_heavy_snow"
    },
    109: {
      "icon": {"day": "snowy", "night": "snowy"},
      "key": "sunny_snow_pellets"
    },
    110: {
      "icon": {"day": "hail", "night": "hail"},
      "key": "sunny_ice_pellets"
    },
    111: {
      "icon": {"day": "rainy", "night": "rainy"},
      "key": "sunny_showers"
    },
    112: {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
      "key": "sunny_rain_snow_showers"
    },
    113: {
      "icon": {"day": "hail", "night": "hail"},
      "key": "sunny_hail"
    },
    114: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_thunderstorm"
    },
    115: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_thunder_snow"
    },
    116: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_thunder_hail"
    },
    117: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_heavy_thunderstorm"
    },
    118: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_heavy_thunder_hail"
    },
    119: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "sunny_thunder"
    },

    // Cloudy (多雲)
    200: {
      "icon": {"day": "partly_cloudy_day", "night": "partly_cloudy_night"},
      "key": "cloudy"
    },
    201: {
      "icon": {"day": "partly_cloudy_day", "night": "partly_cloudy_night"},
      "key": "cloudy_haze"
    },
    202: {
      "icon": {"day": "partly_cloudy_day", "night": "partly_cloudy_night"},
      "key": "cloudy_mist"
    },
    203: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_lightning"
    },
    204: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_thunder"
    },
    205: {
      "icon": {"day": "foggy", "night": "foggy"},
      "key": "cloudy_fog"
    },
    206: {
      "icon": {"day": "rainy", "night": "rainy"},
      "key": "cloudy_rain"
    },
    207: {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
      "key": "cloudy_rain_snow"
    },
    208: {
      "icon": {"day": "snowy", "night": "snowy"},
      "key": "cloudy_heavy_snow"
    },
    209: {
      "icon": {"day": "snowy", "night": "snowy"},
      "key": "cloudy_snow_pellets"
    },
    210: {
      "icon": {"day": "hail", "night": "hail"},
      "key": "cloudy_ice_pellets"
    },
    211: {
      "icon": {"day": "rainy", "night": "rainy"},
      "key": "cloudy_showers"
    },
    212: {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
      "key": "cloudy_rain_snow_showers"
    },
    213: {
      "icon": {"day": "hail", "night": "hail"},
      "key": "cloudy_hail"
    },
    214: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_thunderstorm"
    },
    215: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_thunder_snow"
    },
    216: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_thunder_hail"
    },
    217: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_heavy_thunderstorm"
    },
    218: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_heavy_thunder_hail"
    },
    219: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "cloudy_thunder"
    },

    // Overcast (陰)
    300: {
      "icon": {"day": "cloudy", "night": "cloudy"},
      "key": "overcast"
    },
    301: {
      "icon": {"day": "cloudy", "night": "cloudy"},
      "key": "overcast_haze"
    },
    302: {
      "icon": {"day": "cloudy", "night": "cloudy"},
      "key": "overcast_mist"
    },
    303: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_lightning"
    },
    304: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_thunder"
    },
    305: {
      "icon": {"day": "foggy", "night": "foggy"},
      "key": "overcast_fog"
    },
    306: {
      "icon": {"day": "rainy", "night": "rainy"},
      "key": "overcast_rain"
    },
    307: {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
      "key": "overcast_rain_snow"
    },
    308: {
      "icon": {"day": "snowy", "night": "snowy"},
      "key": "overcast_heavy_snow"
    },
    309: {
      "icon": {"day": "snowy", "night": "snowy"},
      "key": "overcast_snow_pellets"
    },
    310: {
      "icon": {"day": "hail", "night": "hail"},
      "key": "overcast_ice_pellets"
    },
    311: {
      "icon": {"day": "rainy", "night": "rainy"},
      "key": "overcast_showers"
    },
    312: {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
      "key": "overcast_rain_snow_showers"
    },
    313: {
      "icon": {"day": "hail", "night": "hail"},
      "key": "overcast_hail"
    },
    314: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_thunderstorm"
    },
    315: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_thunder_snow"
    },
    316: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_thunder_hail"
    },
    317: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_heavy_thunderstorm"
    },
    318: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_heavy_thunder_hail"
    },
    319: {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
      "key": "overcast_thunder"
    },
  };

  static IconData getWeatherIcon(int code, int isDay) {
    final weatherInfo = weatherCodeMap[code];
    if (weatherInfo != null) {
      final iconName = isDay == 1 ? weatherInfo["icon"]["day"] : weatherInfo["icon"]["night"];
      return iconMap[iconName] ?? Symbols.error;
    }
    return Symbols.error;
  }

  static String getWeatherContent(BuildContext context, String code) {
    Map<String, String> iconLabel = {
      "0": context.i18n.weather_system_abnormal,
      "100": context.i18n.sunny,
      "101": context.i18n.sunny_with_haze,
      "102": context.i18n.sunny_with_mist,
      "103": context.i18n.sunny_with_lightning,
      "104": context.i18n.sunny_with_thunder,
      "105": context.i18n.sunny_with_fog,
      "106": context.i18n.sunny_with_rain,
      "107": context.i18n.sunny_with_sleet,
      "108": context.i18n.sunny_with_heavy_snow,
      "109": context.i18n.sunny_with_snow_pellets,
      "110": context.i18n.sunny_with_ice_pellets,
      "111": context.i18n.sunny_with_snow_showers,
      "112": context.i18n.sunny_with_sleet_showers,
      "113": context.i18n.sunny_with_hail,
      "114": context.i18n.sunny_with_thunderstorm,
      "115": context.i18n.sunny_with_thundersnow,
      "116": context.i18n.sunny_with_thunderhail,
      "117": context.i18n.sunny_with_severe_thunderstorm,
      "118": context.i18n.sunny_with_severe_thunderhail,
      "119": context.i18n.sunny_with_thunder,
      "200": context.i18n.partly__cloudy,
      "201": context.i18n.partly_cloudy_with_haze,
      "202": context.i18n.partly_cloudy_with_mist,
      "203": context.i18n.partly_cloudy_with_lightning,
      "204": context.i18n.partly_cloudy_with_thunder,
      "205": context.i18n.partly_cloudy_with_fog,
      "206": context.i18n.partly_cloudy_with_rain,
      "207": context.i18n.partly_cloudy_with_sleet,
      "208": context.i18n.partly_cloudy_with_heavy_snow,
      "209": context.i18n.partly_cloudy_with_snow_pellets,
      "210": context.i18n.partly_cloudy_with_ice_pellets,
      "211": context.i18n.partly_cloudy_with_snow_showers,
      "212": context.i18n.partly_cloudy_with_sleet_showers,
      "213": context.i18n.partly_cloudy_with_hail,
      "214": context.i18n.partly_cloudy_with_thunderstorm,
      "215": context.i18n.partly_cloudy_with_thundersnow,
      "216": context.i18n.partly_cloudy_with_thunderhail,
      "217": context.i18n.partly_cloudy_with_severe_thunderstorm,
      "218": context.i18n.partly_cloudy_with_severe_thunderhail,
      "219": context.i18n.partly_cloudy_with_thunder,
      "300": context.i18n.overcast,
      "301": context.i18n.overcast_with_haze,
      "302": context.i18n.overcast_with_mist,
      "303": context.i18n.overcast_with_lightning,
      "304": context.i18n.overcast_with_thunder,
      "305": context.i18n.overcast_with_fog,
      "306": context.i18n.overcast_with_rain,
      "307": context.i18n.overcast_with_sleet,
      "308": context.i18n.overcast_with_heavy_snow,
      "309": context.i18n.overcast_with_snow_pellets,
      "310": context.i18n.overcast_with_ice_pellets,
      "311": context.i18n.overcast_with_snow_showers,
      "312": context.i18n.overcast_with_sleet_showers,
      "313": context.i18n.overcast_with_hail,
      "314": context.i18n.overcast_with_thunderstorm,
      "315": context.i18n.overcast_with_thundersnow,
      "316": context.i18n.overcast_with_thunderhail,
      "317": context.i18n.overcast_with_severe_thunderstorm,
      "318": context.i18n.overcast_with_severe_thunderhail,
      "319": context.i18n.overcast_with_thunder,
      // "103": context.i18n.partly_cloudy,
      // "106": context.i18n.cloudy,
      // "109": context.i18n.overcast,
      // "130": context.i18n.foggy,
      // "163": context.i18n.patchy_rain_possible,
      // "166": context.i18n.patchy_snow_possible,
      // "169": context.i18n.patchy_sleet_possible,
      // "172": context.i18n.patchy_freezing_drizzle_possible,
      // "187": context.i18n.thundery_outbreaks_possible,
      // "114": context.i18n.blowing_snow,
      // "117": context.i18n.blizzard,
      // "135": context.i18n.fog,
      // "147": context.i18n.freezing_fog,
      // "150": context.i18n.patchy_light_drizzle,
      // "153": context.i18n.light_drizzle,
      // "168": context.i18n.freezing_drizzle,
      // "171": context.i18n.heavy_freezing_drizzle,
      // "180": context.i18n.patchy_light_rain,
      // "183": context.i18n.light_rain,
      // "186": context.i18n.moderate_rain_at_times,
      // "189": context.i18n.moderate_rain,
      // "192": context.i18n.heavy_rain_at_times,
      // "195": context.i18n.heavy_rain,
      // "198": context.i18n.light_freezing_rain,
      // "201": context.i18n.moderate_or_heavy_freezing_rain,
      // "204": context.i18n.light_sleet,
      // "207": context.i18n.moderate_or_heavy_sleet,
      // "210": context.i18n.patchy_light_snow,
      // "213": context.i18n.light_snow,
      // "216": context.i18n.patchy_moderate_snow,
      // "219": context.i18n.moderate_snow,
      // "222": context.i18n.patchy_heavy_snow,
      // "225": context.i18n.heavy_snow,
      // "237": context.i18n.ice_pellets,
      // "240": context.i18n.light_rain_shower,
      // "243": context.i18n.moderate_or_heavy_rain_shower,
      // "246": context.i18n.torrential_rain_shower,
      // "249": context.i18n.light_sleet_showers,
      // "252": context.i18n.moderate_or_heavy_sleet_showers,
      // "255": context.i18n.light_snow_showers,
      // "258": context.i18n.moderate_or_heavy_snow_showers,
      // "261": context.i18n.light_showers_of_ice_pellets,
      // "264": context.i18n.moderate_or_heavy_showers_of_ice_pellets,
      // "273": context.i18n.patchy_light_rain_with_thunder,
      // "276": context.i18n.moderate_or_heavy_rain_with_thunder,
      // "279": context.i18n.patchy_light_snow_with_thunder,
      // "282": context.i18n.moderate_or_heavy_snow_with_thunder,
    };

    return iconLabel[code] ?? "Unknown weather";
  }

  static String mapNumberToWeather(int number) {
    final weatherInfo = weatherCodeMap[number];
    if (weatherInfo != null) {
      return weatherInfo["key"];
    }
    return "unknown_weather";
  }
}
