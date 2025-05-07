import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

class ListIcons {
  static const Map<String, IconData> iconMap = {
    'bolt_rounded': Symbols.bolt_rounded,
    'landslide_rounded': Symbols.landslide_rounded,
    'earthquake_rounded': Symbols.earthquake_rounded,
    'rainy_rounded': Symbols.rainy_rounded,
    'flood_rounded': Symbols.flood_rounded,
    'tsunami_rounded': Symbols.tsunami_rounded,
    'volcano_rounded': Symbols.volcano_rounded,
    'thermometer_add_rounded': Symbols.thermometer_add_rounded,
    'thermometer_minus_rounded': Symbols.thermometer_minus_rounded,
    'air_rounded': Symbols.air_rounded,
    'emergency_heat_rounded': Symbols.emergency_heat_rounded,
    'medical_mask_rounded': Symbols.medical_mask_rounded,
    'bomb_rounded': Symbols.bomb_rounded,
    'warning_rounded': Symbols.warning_rounded,
    'directions_run_rounded': Symbols.directions_run_rounded,
    'destruction_rounded': Symbols.destruction_rounded,
    'power_off_rounded': Symbols.power_off_rounded,
    'format_color_reset_rounded': Symbols.format_color_reset_rounded,
    'water_rounded': Symbols.water_rounded,
    'cyclone_rounded': Symbols.cyclone_rounded,
    'foggy': Symbols.foggy,
  };

  static IconData getListIcon(String name) {
    return iconMap[name] ?? Symbols.error;
  }
}
