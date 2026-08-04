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

  /// Short bottom-nav / settings-picker label (not the long layer-switcher name).
  String label(AppLocalizations l10n) => switch (this) {
    DefaultMapLayer.radar => l10n.mapNavRadar,
    DefaultMapLayer.satellite => l10n.mapNavSatellite,
    DefaultMapLayer.lightning => l10n.mapNavLightning,
    DefaultMapLayer.typhoon => l10n.mapNavTyphoon,
    DefaultMapLayer.monitor => l10n.mapNavEarthquake,
    DefaultMapLayer.temperature => l10n.mapNavTemperature,
    DefaultMapLayer.humidity => l10n.mapNavHumidity,
    DefaultMapLayer.pressure => l10n.mapNavPressure,
    DefaultMapLayer.wind => l10n.mapNavWind,
    DefaultMapLayer.rain => l10n.mapNavRain,
    DefaultMapLayer.dpm => l10n.mapNavDisaster,
  };
}
