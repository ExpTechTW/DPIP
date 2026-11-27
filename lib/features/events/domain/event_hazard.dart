/// The hazard category of an App API v2 event card.
///
/// The server derives a `hazard` code from each card's `type` and sends it
/// with the card; the App groups and picks icons by it and never derives it
/// from `type` itself.
library;

/// A hazard code from the App API v2 `hazard` field.
///
/// The first group is every code a card is produced with today; the second is
/// every code the server reserves from the DPIP Taiwan hazard classification
/// for types that do not exist yet, so a card of a new type still lands in a
/// named category. [unknown] stands for an empty, missing or unrecognised
/// code.
enum EventHazard {
  earthquake('earthquake'),
  tsunami('tsunami'),
  wind('wind'),
  heavyRain('heavy_rain'),
  flood('flood'),
  riverRise('river_rise'),
  damRelease('dam_release'),
  swell('swell'),
  debrisFlow('debris_flow'),
  landslideDam('landslide_dam'),
  thunderstorm('thunderstorm'),
  fog('fog'),
  roadClosure('road_closure'),

  /// Not a hazard: a manual announcement.
  announcement('announcement'),

  /// Not a hazard: a work and school closure.
  closure('closure'),

  // Reserved: no card carries these yet.
  liquefaction('liquefaction'),
  volcano('volcano'),
  typhoon('typhoon'),
  stormSurge('storm_surge'),
  largeLandslide('large_landslide'),
  rockfall('rockfall'),
  heat('heat'),
  cold('cold'),
  drought('drought'),
  fire('fire'),
  wildfire('wildfire'),
  hazmat('hazmat'),
  powerOutage('power_outage'),
  waterOutage('water_outage'),
  trafficAccident('traffic_accident'),
  airQuality('air_quality'),
  radiation('radiation'),
  evacuation('evacuation'),
  civilDefense('civil_defense'),

  /// An empty, missing or unrecognised code.
  unknown('unknown');

  const EventHazard(this.code);

  /// The code as it appears on the wire, e.g. `heavy_rain`.
  final String code;

  static final Map<String, EventHazard> _byCode = {
    for (final hazard in values) hazard.code: hazard,
  };

  /// The hazard whose wire code is exactly [code]; [unknown] for `null`, an
  /// empty string or any code not listed here. Never throws.
  static EventHazard fromCode(String? code) =>
      _byCode[code] ?? EventHazard.unknown;
}
