/// Resolves the Material icon for an event kind — the leading mark on event
/// timeline rows and home cards.
library;

import 'package:flutter/material.dart';

/// The icon for an event kind, keyed off `EventType.iconKey` so the domain
/// enum stays Material-free. Falls back to a generic notification mark for an
/// unknown key.
IconData eventTypeIcon(String key) => switch (key) {
  'earthquake' => Icons.crisis_alert,
  'report' => Icons.description_outlined,
  'intensity' => Icons.graphic_eq,
  'thunderstorm' => Icons.thunderstorm_outlined,
  'heavy_rain' => Icons.water_drop_outlined,
  'weather_warning' => Icons.warning_amber_rounded,
  'tsunami' => Icons.tsunami_outlined,
  _ => Icons.notifications_outlined,
};
