import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ListIcons {
  static const Map<String, IconData> iconMap = {
    'thunderstorm': Symbols.bolt_rounded,
  };

  static IconData getListIcon(String name) {
    return iconMap[name] ?? Symbols.error;
  }
}
