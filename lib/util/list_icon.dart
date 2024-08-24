import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ListIcons {
  static const Map<String, IconData> iconMap = {
    'thunderstorm': Symbols.bolt_rounded,
    'landslide': Symbols.landslide_rounded,
    'earthquake': Symbols.earthquake_rounded,
    'rain': Symbols.rainy_rounded,
    'flood': Symbols.flood_rounded,
    'tsunami': Symbols.tsunami_rounded,
    'volcano': Symbols.volcano_rounded,
    'heat': Symbols.thermometer_add_rounded,
    'cold': Symbols.thermometer_minus_rounded,
    'wind': Symbols.air_rounded,
    'fire': Symbols.emergency_heat_rounded,
    "airQuality": Symbols.medical_mask_rounded,
    "airDefense": Symbols.bomb_rounded,
    "nuke": Symbols.warning_rounded,
    "evacuate": Symbols.directions_run_rounded,
    "explode": Symbols.destruction_rounded,
    "powerOutage": Symbols.power_off_rounded,
    "waterOutage": Symbols.format_color_reset_rounded,
    "reservoirDischarge": Symbols.water_rounded,
  };

  static IconData getListIcon(String name) {
    return iconMap[name] ?? Symbols.error;
  }
}
