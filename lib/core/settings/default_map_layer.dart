/// Default map overlay when opening the Map tab (`MapLayer.id` wire values).
library;

/// Persisted choice for which overlay the map tab opens on. Enum [name] equals
/// the matching `MapLayer.id` (`radar`, `monitor`, `dpm`, …).
enum DefaultMapLayer {
  radar,
  satellite,
  lightning,
  typhoon,
  monitor,
  temperature,
  humidity,
  pressure,
  wind,
  rain,
  dpm;

  /// Wire / [MapLayer.id] string (same as [name]).
  String get id => name;
}
