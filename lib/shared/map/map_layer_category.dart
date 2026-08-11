/// Broad groupings for the map overlay list — shared by the settings picker
/// and the in-map layer switcher so both list layers under the same headers.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';

/// The six groups the overlays fall into, in display order.
enum MapLayerCategory {
  /// Seismic-monitor events (RTS).
  earthquake,

  /// Ground-radar imagery + short-term precipitation estimate.
  radar,

  /// Typhoon tracks.
  typhoon,

  /// Continuous meteorological fields + convective phenomena (temperature,
  /// humidity, pressure, wind, rain stations, lightning).
  weather,

  /// Geostationary-satellite imagery (Himawari infrared).
  satellite,

  /// Everyday-life facilities (disaster-prevention map).
  life,
}

/// The group [layerId] belongs to.
///
/// A switch (not a lookup table) so an id added after this function — a future
/// layer — still resolves deterministically to [MapLayerCategory.weather]
/// instead of throwing. The satellite split namespaced the single IR layer
/// into `satellite-<channel>` ids, so those match by prefix off the historical
/// `satellite` id.
MapLayerCategory categoryOf(String layerId) {
  if (layerId == 'satellite' || layerId.startsWith('satellite-')) {
    return MapLayerCategory.satellite;
  }
  return switch (layerId) {
    'monitor' => MapLayerCategory.earthquake,
    'typhoon' => MapLayerCategory.typhoon,
    'temperature' ||
    'humidity' ||
    'pressure' ||
    'wind' ||
    'rain' ||
    'lightning' => MapLayerCategory.weather,
    'radar' || 'qpesums' => MapLayerCategory.radar,
    'dpm' => MapLayerCategory.life,
    _ => MapLayerCategory.weather,
  };
}

/// Localised header for a group.
String categoryLabel(MapLayerCategory category, AppLocalizations l10n) =>
    switch (category) {
      MapLayerCategory.earthquake => l10n.mapLayerCategoryEarthquake,
      MapLayerCategory.typhoon => l10n.mapLayerCategoryTyphoon,
      MapLayerCategory.weather => l10n.mapLayerCategoryWeather,
      MapLayerCategory.satellite => l10n.mapLayerCategorySatellite,
      MapLayerCategory.radar => l10n.mapLayerCategoryRadar,
      MapLayerCategory.life => l10n.mapLayerCategoryLife,
    };
