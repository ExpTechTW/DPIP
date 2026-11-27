/// How an [EventHazard] is drawn: its icon, its colour and its name.
///
/// The domain enum stays Material-free; everything visual about a hazard is
/// decided here, once, so the events list, the home sheet and the detail page
/// can never disagree about what a hazard looks like.
library;

import 'package:dpip/core/weather/weather_icons.dart' as weather;
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The colour family a hazard is drawn in, resolved against the theme's
/// [ColorScheme] so light and dark modes follow without a literal colour.
enum EventHazardTone {
  /// Earthquake and tsunami: the error container, the strongest tone.
  seismic,

  /// Rain, flooding, rivers, reservoirs and the sea: the primary container.
  water,

  /// Wind, thunderstorms and fog: the tertiary container.
  atmosphere,

  /// Debris flows, landslide dams and closed roads: the secondary container.
  ground,

  /// Announcements, closures, reserved and unknown codes: a neutral surface.
  notice;

  /// The badge fill for this tone.
  Color fill(ColorScheme colors) => switch (this) {
    EventHazardTone.seismic => colors.errorContainer,
    EventHazardTone.water => colors.primaryContainer,
    EventHazardTone.atmosphere => colors.tertiaryContainer,
    EventHazardTone.ground => colors.secondaryContainer,
    EventHazardTone.notice => colors.surfaceContainerHighest,
  };

  /// The icon ink drawn over [fill].
  Color ink(ColorScheme colors) => switch (this) {
    EventHazardTone.seismic => colors.onErrorContainer,
    EventHazardTone.water => colors.onPrimaryContainer,
    EventHazardTone.atmosphere => colors.onTertiaryContainer,
    EventHazardTone.ground => colors.onSecondaryContainer,
    EventHazardTone.notice => colors.onSurfaceVariant,
  };
}

/// The icon, tone and label of each [EventHazard].
///
/// Every switch here is exhaustive with no default case, so a hazard added to
/// the enum fails to compile until it is given a look. Reserved codes and
/// [EventHazard.unknown] share the generic notice mark and the "other" label:
/// a card of a type this build does not know is still listed, never dropped.
extension EventHazardStyle on EventHazard {
  /// The leading icon: one per hazard, so the badge alone says what
  /// happened.
  ///
  /// Material [Icons] where Flutter's bundled font has a fitting glyph, else
  /// the bundled Material Symbols subset (`core/weather/weather_icons.dart`):
  /// rain, wind, fog and thunderstorms, and the hazards the bundled font has
  /// no picture for — an earthquake, heat, a siren, a valve. Where hazards
  /// share a glyph it is because they are the same picture: a debris flow, a
  /// rockfall and a large landslide all come down a slope, and a storm surge
  /// is the sea over land, a flood.
  IconData get icon => switch (this) {
    EventHazard.earthquake => weather.earthquake,
    EventHazard.tsunami => Icons.tsunami_outlined,
    EventHazard.wind => weather.air,
    EventHazard.heavyRain => weather.rainy,
    EventHazard.flood => Icons.flood_outlined,
    EventHazard.riverRise => Icons.water_outlined,
    EventHazard.damRelease => weather.valve,
    EventHazard.swell => Icons.surfing_outlined,
    EventHazard.debrisFlow => Icons.landslide_outlined,
    EventHazard.landslideDam => Icons.landscape_outlined,
    EventHazard.thunderstorm => weather.thunderstorm,
    EventHazard.fog => weather.foggy,
    EventHazard.roadClosure => Icons.remove_road_outlined,
    EventHazard.announcement => Icons.campaign_outlined,
    EventHazard.closure => Icons.school_outlined,
    EventHazard.liquefaction => Icons.foundation_outlined,
    EventHazard.volcano => Icons.volcano_outlined,
    EventHazard.typhoon => weather.storm,
    EventHazard.stormSurge => Icons.flood_outlined,
    EventHazard.largeLandslide => Icons.landslide_outlined,
    EventHazard.rockfall => Icons.landslide_outlined,
    EventHazard.heat => weather.heat,
    EventHazard.cold => Icons.severe_cold_outlined,
    EventHazard.drought => weather.clearDay,
    EventHazard.fire => Icons.local_fire_department_outlined,
    EventHazard.wildfire => Icons.forest_outlined,
    EventHazard.hazmat => Icons.science_outlined,
    EventHazard.powerOutage => Icons.power_off_outlined,
    EventHazard.waterOutage => Icons.format_color_reset_outlined,
    EventHazard.trafficAccident => Icons.car_crash_outlined,
    EventHazard.airQuality => Icons.masks_outlined,
    EventHazard.radiation => Icons.dangerous_outlined,
    EventHazard.evacuation => Icons.directions_run_outlined,
    EventHazard.civilDefense => weather.siren,
    EventHazard.unknown => Icons.warning_amber_outlined,
  };

  /// The colour family of the badge.
  EventHazardTone get tone => switch (this) {
    EventHazard.earthquake || EventHazard.tsunami => EventHazardTone.seismic,
    EventHazard.heavyRain ||
    EventHazard.flood ||
    EventHazard.riverRise ||
    EventHazard.damRelease ||
    EventHazard.swell => EventHazardTone.water,
    EventHazard.wind ||
    EventHazard.thunderstorm ||
    EventHazard.fog => EventHazardTone.atmosphere,
    EventHazard.debrisFlow ||
    EventHazard.landslideDam ||
    EventHazard.roadClosure => EventHazardTone.ground,
    EventHazard.announcement ||
    EventHazard.closure ||
    EventHazard.liquefaction ||
    EventHazard.volcano ||
    EventHazard.typhoon ||
    EventHazard.stormSurge ||
    EventHazard.largeLandslide ||
    EventHazard.rockfall ||
    EventHazard.heat ||
    EventHazard.cold ||
    EventHazard.drought ||
    EventHazard.fire ||
    EventHazard.wildfire ||
    EventHazard.hazmat ||
    EventHazard.powerOutage ||
    EventHazard.waterOutage ||
    EventHazard.trafficAccident ||
    EventHazard.airQuality ||
    EventHazard.radiation ||
    EventHazard.evacuation ||
    EventHazard.civilDefense ||
    EventHazard.unknown => EventHazardTone.notice,
  };

  /// The hazard's name in the UI language.
  String label(AppLocalizations l10n) => switch (this) {
    EventHazard.earthquake => l10n.eventHazardEarthquake,
    EventHazard.tsunami => l10n.eventHazardTsunami,
    EventHazard.wind => l10n.eventHazardWind,
    EventHazard.heavyRain => l10n.eventHazardHeavyRain,
    EventHazard.flood => l10n.eventHazardFlood,
    EventHazard.riverRise => l10n.eventHazardRiverRise,
    EventHazard.damRelease => l10n.eventHazardDamRelease,
    EventHazard.swell => l10n.eventHazardSwell,
    EventHazard.debrisFlow => l10n.eventHazardDebrisFlow,
    EventHazard.landslideDam => l10n.eventHazardLandslideDam,
    EventHazard.thunderstorm => l10n.eventHazardThunderstorm,
    EventHazard.fog => l10n.eventHazardFog,
    EventHazard.roadClosure => l10n.eventHazardRoadClosure,
    EventHazard.announcement => l10n.eventHazardAnnouncement,
    EventHazard.closure => l10n.eventHazardClosure,
    EventHazard.liquefaction ||
    EventHazard.volcano ||
    EventHazard.typhoon ||
    EventHazard.stormSurge ||
    EventHazard.largeLandslide ||
    EventHazard.rockfall ||
    EventHazard.heat ||
    EventHazard.cold ||
    EventHazard.drought ||
    EventHazard.fire ||
    EventHazard.wildfire ||
    EventHazard.hazmat ||
    EventHazard.powerOutage ||
    EventHazard.waterOutage ||
    EventHazard.trafficAccident ||
    EventHazard.airQuality ||
    EventHazard.radiation ||
    EventHazard.evacuation ||
    EventHazard.civilDefense ||
    EventHazard.unknown => l10n.eventHazardOther,
  };
}

/// A round badge holding [hazard]'s icon in its tone — the leading mark of
/// every event row and of the detail page's header.
///
/// The fill is opaque, so a timeline rail drawn behind it is hidden where the
/// two cross.
class EventHazardBadge extends StatelessWidget {
  const EventHazardBadge({super.key, required this.hazard, this.size = 36});

  /// The hazard drawn.
  final EventHazard hazard;

  /// The badge's diameter; the icon is a little over half of it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = hazard.tone;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.fill(colors),
        shape: BoxShape.circle,
      ),
      child: Icon(
        hazard.icon,
        size: size * 0.56,
        color: tone.ink(colors),
        semanticLabel: hazard.label(AppLocalizations.of(context)),
      ),
    );
  }
}
