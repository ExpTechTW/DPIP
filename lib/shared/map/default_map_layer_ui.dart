/// UI helpers for [DefaultMapLayer] — nav icons + localised labels.
library;

import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Icons / labels shared by the bottom-nav Map tab and the settings picker.
///
/// Lives in `shared/` so `app/shell` and `features/settings` don't each hardcode
/// the 11-way switch (and so `core` stays Flutter-l10n free beyond ChangeNotifier).
extension DefaultMapLayerUi on DefaultMapLayer {
  /// Outlined icon for inactive bottom-nav / list leading.
  IconData get icon => switch (this) {
    DefaultMapLayer.radar => Icons.radar_outlined,
    DefaultMapLayer.satellite => Icons.satellite_alt_outlined,
    DefaultMapLayer.lightning => Icons.bolt_outlined,
    DefaultMapLayer.typhoon => Icons.cyclone_outlined,
    DefaultMapLayer.monitor => Icons.sensors_outlined,
    DefaultMapLayer.temperature => Icons.thermostat_outlined,
    DefaultMapLayer.humidity => Icons.water_drop_outlined,
    DefaultMapLayer.pressure => Icons.compress,
    DefaultMapLayer.wind => Icons.air,
    DefaultMapLayer.rain => Icons.umbrella_outlined,
    DefaultMapLayer.dpm => Icons.health_and_safety_outlined,
  };

  /// Filled icon for the selected bottom-nav destination.
  IconData get selectedIcon => switch (this) {
    DefaultMapLayer.radar => Icons.radar,
    DefaultMapLayer.satellite => Icons.satellite_alt,
    DefaultMapLayer.lightning => Icons.bolt,
    DefaultMapLayer.typhoon => Icons.cyclone,
    DefaultMapLayer.monitor => Icons.sensors,
    DefaultMapLayer.temperature => Icons.thermostat,
    DefaultMapLayer.humidity => Icons.water_drop,
    DefaultMapLayer.pressure => Icons.compress,
    DefaultMapLayer.wind => Icons.air,
    DefaultMapLayer.rain => Icons.umbrella,
    DefaultMapLayer.dpm => Icons.health_and_safety,
  };

  /// Bottom-nav label + settings row title (reuses map-layer l10n).
  String label(AppLocalizations l10n) => switch (this) {
    DefaultMapLayer.radar => l10n.mapLayerRadar,
    DefaultMapLayer.satellite => l10n.mapLayerSatellite,
    DefaultMapLayer.lightning => l10n.mapLayerLightning,
    DefaultMapLayer.typhoon => l10n.mapLayerTyphoon,
    DefaultMapLayer.monitor => l10n.mapLayerMonitor,
    DefaultMapLayer.temperature => l10n.mapLayerTemperature,
    DefaultMapLayer.humidity => l10n.mapLayerHumidity,
    DefaultMapLayer.pressure => l10n.mapLayerPressure,
    DefaultMapLayer.wind => l10n.mapLayerWind,
    DefaultMapLayer.rain => l10n.mapLayerRain,
    DefaultMapLayer.dpm => l10n.mapLayerDisasterMap,
  };
}
