/// The headline numbers of an App API v2 report, read from its `addition`.
///
/// `addition` is the source's raw data, passed through untranslated, and its
/// shape depends on the card `type`. [eventFactsFor] picks the few values a
/// reader wants at a glance — magnitude, depth, the peak rainfall — and formats
/// each one into a locale-independent string. Reading is defensive: a missing
/// or mistyped field drops that one fact, never the others, and nothing here
/// throws.
library;

import 'package:dpip/features/events/domain/event_addition.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/shared/seismic/intensity.dart';

/// What an [EventFact] measures. Each one is labelled by a single short word
/// in the interface; the examples are its [EventFact.display].
enum EventFactKind {
  /// Earthquake magnitude, `M 6.4`.
  magnitude,

  /// Hypocentre depth, `10 km`.
  depth,

  /// Maximum seismic intensity, `5⁺`; carries [EventFact.intensityLevel].
  maxIntensity,

  /// Epicentre place name as the source wrote it, `花蓮縣近海`.
  epicenter,

  /// Earthquake origin time, Taipei `HH:mm`.
  originTime,

  /// The source's sequence number of this report, `#2`.
  serial,

  /// Tsunami wave height (the highest across the listed places), `100 cm`.
  waveHeight,

  /// Tsunami arrival time (the earliest across the listed places), Taipei
  /// `HH:mm`.
  arrivalTime,

  /// One-hour rainfall (the highest across the card's stations), `85 mm`.
  rainfall,

  /// Mean wind speed (the highest across the card's stations), `25.3 m/s`.
  windSpeed,

  /// Gust speed (the highest across the card's stations), `33 m/s`.
  gust,

  /// Visibility (the lowest across the card's stations), `< 1 km`.
  visibility,

  /// River stage at the card's first station, `4.5 m`.
  waterLevel,

  /// The alert stage the [waterLevel] station has crossed, `4 m`.
  warningLevel,

  /// Lightning strikes across the card's clusters, `200`.
  lightningStrikes,

  /// Road name as the source wrote it, `台灣大道線`.
  road,

  /// Place as the source wrote it, `中清路口`.
  location,

  /// Sensor station name as the source wrote it.
  station,
}

/// One headline value of a report.
final class EventFact {
  const EventFact(this.kind, this.display, {this.intensityLevel});

  final EventFactKind kind;

  /// The value, formatted and locale-independent: `M 6.4`, `10 km`, `85 mm`.
  final String display;

  /// The CWA 0–9 level for [EventFactKind.maxIntensity], to colour it by;
  /// null for every other kind.
  final int? intensityLevel;

  @override
  bool operator ==(Object other) =>
      other is EventFact &&
      other.kind == kind &&
      other.display == display &&
      other.intensityLevel == intensityLevel;

  @override
  int get hashCode => Object.hash(kind, display, intensityLevel);

  @override
  String toString() => intensityLevel == null
      ? 'EventFact(${kind.name}, $display)'
      : 'EventFact(${kind.name}, $display, level $intensityLevel)';
}

/// The headline facts of a report of card [type] whose `addition` is
/// [addition], in reading order and at most four.
///
/// An unknown [type], a null [addition] or one of the wrong shape gives an
/// empty list. Types whose `addition` holds nothing worth showing also give an
/// empty list: `earthquake` and `tsunami_note` (only the report number), the
/// four rain alerts (issue bookkeeping), `debrisFlowLandSlide` (the light is
/// already in the title) and `announcement` (an internal code).
List<EventFact> eventFactsFor(String type, Map<String, dynamic>? addition) {
  if (addition == null) return const [];
  return switch (type) {
    'intensity' => _intensityReport(addition),
    'earthquake.eew' ||
    'earthquake.eew.alert' ||
    'earthquake.station_missing' => _earthquake(additionMap(addition['eq'])),
    // Not an earthquake estimate: where the shaking was detected. It has no
    // epicentre, depth, magnitude or intensity to show, and showing any would
    // claim one; the place is in the subtitle and the description.
    'earthquake.detection' => const [],
    'tsunami.warning' => _tsunamiWarning(addition),
    'tsunami.info' => _tsunamiInfo(addition),
    'roadClose' => _present([
      _text(EventFactKind.road, addition['roadName']),
      _text(EventFactKind.location, addition['location']),
    ]),
    'floodSensor' => _present([
      _text(EventFactKind.location, addition['areaDesc']),
      _text(EventFactKind.station, addition['waterLevelStation']),
    ]),
    'heavy_rain.short' || 'heavy_rain.short_extreme' => _rain(addition),
    'wind.strong' || 'wind.damaging' => _wind(addition),
    'thunderstorm.lightning' => _lightning(addition),
    'river_rise.watch' || 'river_rise.warning' => _river(addition),
    'fog.visibility' => _fog(addition),
    _ => const [],
  };
}

/// [eventFactsFor] of [report]'s own type and `addition`.
List<EventFact> eventFactsOfReport(EventReport report) =>
    eventFactsFor(report.type, report.addition);

// ── Per type ────────────────────────────────────────────────────────────────

/// TREM intensity report: `{max, serial, …}`.
List<EventFact> _intensityReport(Map<Object?, Object?> a) {
  final serial = additionInt(a['serial']);
  return _present([
    _maxIntensity(a['max']),
    if (serial != null && serial >= 0)
      EventFact(EventFactKind.serial, '#$serial'),
  ]);
}

/// The `eq` object of the earthquake cards: `{mag, max, depth, loc, …}`. A
/// TREM detection has no `mag` and may have a null `max`; a missing-station
/// report has no `max` or `loc`.
List<EventFact> _earthquake(Map<Object?, Object?>? eq) {
  if (eq == null) return const [];
  return _present([
    _magnitude(eq['mag']),
    _maxIntensity(eq['max']),
    _depth(eq['depth']),
    _text(EventFactKind.epicenter, eq['loc']),
  ]);
}

/// `{status, eq, info: {type, data: [{wave_height, arrival_time, …}]}}`.
///
/// Observed data (`actual`) is always read. Estimates are read until the
/// warning is lifted (`status` 2), so a lifted warning does not show an
/// arrival that is no longer expected.
List<EventFact> _tsunamiWarning(Map<Object?, Object?> a) {
  final eq = additionMap(a['eq']);
  final info = additionMap(a['info']);
  final infoType = info?['type'];
  final rows =
      infoType == 'actual' ||
          (infoType == 'estimate' && additionInt(a['status']) != 2)
      ? additionMaps(info?['data'])
      : const <Map<Object?, Object?>>[];

  double? highest;
  int? earliest;
  for (final row in rows) {
    final height = additionAmount(row['wave_height']);
    if (height != null && (highest == null || height > highest)) {
      highest = height;
    }
    final arrival = additionEpochMs(row['arrival_time']);
    if (arrival != null && (earliest == null || arrival < earliest)) {
      earliest = arrival;
    }
  }

  return _present([
    if (highest != null)
      EventFact(EventFactKind.waveHeight, '${eventDecimal(highest, 1)} cm'),
    if (earliest != null)
      EventFact(EventFactKind.arrivalTime, eventClock(earliest)),
    if (eq != null) _magnitude(eq['mag']),
    if (eq != null) _text(EventFactKind.epicenter, eq['loc']),
  ]);
}

/// CWA tsunami message: `{eq: {time, mag, depth, loc, …}, …}`, every field
/// optional.
List<EventFact> _tsunamiInfo(Map<Object?, Object?> a) {
  final eq = additionMap(a['eq']);
  if (eq == null) return const [];
  final time = additionEpochMs(eq['time']);
  return _present([
    _magnitude(eq['mag']),
    _depth(eq['depth']),
    _text(EventFactKind.epicenter, eq['loc']),
    if (time != null) EventFact(EventFactKind.originTime, eventClock(time)),
  ]);
}

/// Stations `{rain: {1h, …}}`: the highest one-hour rainfall.
List<EventFact> _rain(Map<Object?, Object?> a) {
  final peak = _highest(
    additionMaps(a['stations'])
        .map((s) => additionAmount(additionMap(s['rain'])?['1h'])),
  );
  return [
    if (peak != null)
      EventFact(EventFactKind.rainfall, '${eventDecimal(peak, 1)} mm'),
  ];
}

/// Stations `{wind: {speed}, gust: {speed}}`: the highest of each, which may
/// come from different stations.
List<EventFact> _wind(Map<Object?, Object?> a) {
  final stations = additionMaps(a['stations']);
  final wind = _highest(
    stations.map((s) => additionAmount(additionMap(s['wind'])?['speed'])),
  );
  final gust = _highest(
    stations.map((s) => additionAmount(additionMap(s['gust'])?['speed'])),
  );
  return [
    if (wind != null)
      EventFact(EventFactKind.windSpeed, '${eventDecimal(wind, 1)} m/s'),
    if (gust != null)
      EventFact(EventFactKind.gust, '${eventDecimal(gust, 1)} m/s'),
  ];
}

/// Clusters `{count}`: the strikes across all of them.
List<EventFact> _lightning(Map<Object?, Object?> a) {
  int? total;
  for (final cluster in additionMaps(a['stations'])) {
    final count = additionInt(cluster['count']);
    if (count != null && count >= 0) total = (total ?? 0) + count;
  }
  return [
    if (total != null) EventFact(EventFactKind.lightningStrikes, '$total'),
  ];
}

/// Stations `{stage, waterLevel, warningLevel1, warningLevel2}`.
///
/// Stages of different rivers are not comparable, so this reads the first
/// station with a water level — the one the card's subtitle names — and the
/// alert stage it has crossed: `warningLevel1` for stage `l1`/`l1up`,
/// `warningLevel2` for `l2`/`l2up`.
List<EventFact> _river(Map<Object?, Object?> a) {
  for (final station in additionMaps(a['stations'])) {
    final level = additionStage(station['waterLevel']);
    if (level == null) continue;
    final line = additionStage(switch (station['stage']) {
      'l1' || 'l1up' => station['warningLevel1'],
      'l2' || 'l2up' => station['warningLevel2'],
      _ => null,
    });
    return [
      EventFact(EventFactKind.waterLevel, '${eventDecimal(level, 2)} m'),
      if (line != null)
        EventFact(EventFactKind.warningLevel, '${eventDecimal(line, 2)} m'),
    ];
  }
  return const [];
}

/// Stations `{visibility, visibilityText}` in km: the lowest visibility.
///
/// The source's text wins over the number when it has one, because a bound
/// such as `<1` is stored as half of it (`0.5`) and only the text says so.
List<EventFact> _fog(Map<Object?, Object?> a) {
  Map<Object?, Object?>? lowest;
  double? lowestKm;
  for (final station in additionMaps(a['stations'])) {
    final km = additionAmount(station['visibility']);
    if (km != null && (lowestKm == null || km < lowestKm)) {
      lowest = station;
      lowestKm = km;
    }
  }
  if (lowest == null || lowestKm == null) return const [];
  final text = additionVisibilityText(lowest['visibilityText']);
  return [
    EventFact(
      EventFactKind.visibility,
      '${text ?? eventDecimal(lowestKm, 1)} km',
    ),
  ];
}

// ── Single facts ────────────────────────────────────────────────────────────

EventFact? _magnitude(Object? v) {
  final m = additionAmount(v);
  return m == null
      ? null
      : EventFact(EventFactKind.magnitude, 'M ${m.toStringAsFixed(1)}');
}

EventFact? _depth(Object? v) {
  final km = additionAmount(v);
  return km == null
      ? null
      : EventFact(EventFactKind.depth, '${eventDecimal(km, 1)} km');
}

EventFact? _maxIntensity(Object? v) {
  final level = additionInt(v);
  if (level == null || level < 0 || level > 9) return null;
  return EventFact(
    EventFactKind.maxIntensity,
    Intensity.label(level),
    intensityLevel: level,
  );
}

EventFact? _text(EventFactKind kind, Object? v) => switch (additionText(v)) {
  final text? => EventFact(kind, text),
  null => null,
};

// ── Reading ─────────────────────────────────────────────────────────────────

List<EventFact> _present(List<EventFact?> facts) => facts.nonNulls.toList();

double? _highest(Iterable<double?> values) {
  double? best;
  for (final v in values) {
    if (v != null && (best == null || v > best)) best = v;
  }
  return best;
}
