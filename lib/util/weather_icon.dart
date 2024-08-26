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
    "ac_unit": Symbols.ac_unit,
    "rainy_snow": Symbols.weather_mix,
    "thunderstorm": Symbols.thunderstorm,
    "rainy_light": Symbols.grain,
    "rainy_heavy": Symbols.water,
    "snowing": Symbols.snowing,
  };

  static final Map<String, Map<String, dynamic>> weatherCodeMap = {
    "1000": {
      "icon": {"day": "sunny", "night": "nightlight"},
    },
    "1003": {
      "icon": {"day": "partly_cloudy_day", "night": "partly_cloudy_night"},
    },
    "1006": {
      "icon": {"day": "cloudy", "night": "cloudy"},
    },
    "1009": {
      "icon": {"day": "cloudy", "night": "cloudy"},
    },
    "1030": {
      "icon": {"day": "foggy", "night": "foggy"},
    },
    "1063": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1066": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1069": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1072": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1087": {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
    },
    "1114": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1117": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1135": {
      "icon": {"day": "foggy", "night": "foggy"},
    },
    "1147": {
      "icon": {"day": "foggy", "night": "foggy"},
    },
    "1150": {
      "icon": {"day": "rainy_light", "night": "rainy_light"},
    },
    "1153": {
      "icon": {"day": "rainy_light", "night": "rainy_light"},
    },
    "1168": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1171": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1180": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1183": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1186": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1189": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1192": {
      "icon": {"day": "rainy_heavy", "night": "rainy_heavy"},
    },
    "1195": {
      "icon": {"day": "rainy_heavy", "night": "rainy_heavy"},
    },
    "1198": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1201": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1204": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1207": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1210": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1213": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1216": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1219": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1222": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1225": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1237": {
      "icon": {"day": "snowing", "night": "snowing"},
    },
    "1240": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1243": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1246": {
      "icon": {"day": "rainy", "night": "rainy"},
    },
    "1249": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1252": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1255": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1258": {
      "icon": {"day": "ac_unit", "night": "ac_unit"},
    },
    "1261": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1264": {
      "icon": {"day": "rainy_snow", "night": "rainy_snow"},
    },
    "1273": {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
    },
    "1276": {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
    },
    "1279": {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
    },
    "1282": {
      "icon": {"day": "thunderstorm", "night": "thunderstorm"},
    },
  };

  static IconData getWeatherIcon(String code, int isDay) {
    final weatherInfo = weatherCodeMap[code];
    if (weatherInfo != null) {
      final iconName = isDay == 1 ? weatherInfo["icon"]["day"] : weatherInfo["icon"]["night"];
      return iconMap[iconName] ?? Symbols.error;
    }
    return Symbols.error;
  }

  static String getWeatherContent(BuildContext context, String code) {
    Map<String, String> iconLabel = {
      "1000": context.i18n.sunny,
      "1003": context.i18n.partly_cloudy,
      "1006": context.i18n.cloudy,
      "1009": context.i18n.overcast,
      "1030": context.i18n.foggy,
      "1063": context.i18n.patchy_rain_possible,
      "1066": context.i18n.patchy_snow_possible,
      "1069": context.i18n.patchy_sleet_possible,
      "1072": context.i18n.patchy_freezing_drizzle_possible,
      "1087": context.i18n.thundery_outbreaks_possible,
      "1114": context.i18n.blowing_snow,
      "1117": context.i18n.blizzard,
      "1135": context.i18n.fog,
      "1147": context.i18n.freezing_fog,
      "1150": context.i18n.patchy_light_drizzle,
      "1153": context.i18n.light_drizzle,
      "1168": context.i18n.freezing_drizzle,
      "1171": context.i18n.heavy_freezing_drizzle,
      "1180": context.i18n.patchy_light_rain,
      "1183": context.i18n.light_rain,
      "1186": context.i18n.moderate_rain_at_times,
      "1189": context.i18n.moderate_rain,
      "1192": context.i18n.heavy_rain_at_times,
      "1195": context.i18n.heavy_rain,
      "1198": context.i18n.light_freezing_rain,
      "1201": context.i18n.moderate_or_heavy_freezing_rain,
      "1204": context.i18n.light_sleet,
      "1207": context.i18n.moderate_or_heavy_sleet,
      "1210": context.i18n.patchy_light_snow,
      "1213": context.i18n.light_snow,
      "1216": context.i18n.patchy_moderate_snow,
      "1219": context.i18n.moderate_snow,
      "1222": context.i18n.patchy_heavy_snow,
      "1225": context.i18n.heavy_snow,
      "1237": context.i18n.ice_pellets,
      "1240": context.i18n.light_rain_shower,
      "1243": context.i18n.moderate_or_heavy_rain_shower,
      "1246": context.i18n.torrential_rain_shower,
      "1249": context.i18n.light_sleet_showers,
      "1252": context.i18n.moderate_or_heavy_sleet_showers,
      "1255": context.i18n.light_snow_showers,
      "1258": context.i18n.moderate_or_heavy_snow_showers,
      "1261": context.i18n.light_showers_of_ice_pellets,
      "1264": context.i18n.moderate_or_heavy_showers_of_ice_pellets,
      "1273": context.i18n.patchy_light_rain_with_thunder,
      "1276": context.i18n.moderate_or_heavy_rain_with_thunder,
      "1279": context.i18n.patchy_light_snow_with_thunder,
      "1282": context.i18n.moderate_or_heavy_snow_with_thunder,
    };

    return iconLabel[code] ?? "Unknown weather";
  }
}
