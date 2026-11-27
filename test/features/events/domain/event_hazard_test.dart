/// The App API v2 hazard codes, against the table and the reserved list in
/// the server's api.md section 2.
library;

import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every code api.md section 2 lists: the ones cards carry today, then the
/// reserved ones.
const _codes = {
  'earthquake': EventHazard.earthquake,
  'tsunami': EventHazard.tsunami,
  'wind': EventHazard.wind,
  'heavy_rain': EventHazard.heavyRain,
  'flood': EventHazard.flood,
  'river_rise': EventHazard.riverRise,
  'dam_release': EventHazard.damRelease,
  'swell': EventHazard.swell,
  'debris_flow': EventHazard.debrisFlow,
  'landslide_dam': EventHazard.landslideDam,
  'thunderstorm': EventHazard.thunderstorm,
  'fog': EventHazard.fog,
  'road_closure': EventHazard.roadClosure,
  'announcement': EventHazard.announcement,
  'closure': EventHazard.closure,
  'liquefaction': EventHazard.liquefaction,
  'volcano': EventHazard.volcano,
  'typhoon': EventHazard.typhoon,
  'storm_surge': EventHazard.stormSurge,
  'large_landslide': EventHazard.largeLandslide,
  'rockfall': EventHazard.rockfall,
  'heat': EventHazard.heat,
  'cold': EventHazard.cold,
  'drought': EventHazard.drought,
  'fire': EventHazard.fire,
  'wildfire': EventHazard.wildfire,
  'hazmat': EventHazard.hazmat,
  'power_outage': EventHazard.powerOutage,
  'water_outage': EventHazard.waterOutage,
  'traffic_accident': EventHazard.trafficAccident,
  'air_quality': EventHazard.airQuality,
  'radiation': EventHazard.radiation,
  'evacuation': EventHazard.evacuation,
  'civil_defense': EventHazard.civilDefense,
};

void main() {
  test('every listed code maps to its hazard and back', () {
    for (final MapEntry(key: code, value: hazard) in _codes.entries) {
      expect(EventHazard.fromCode(code), hazard, reason: code);
      expect(hazard.code, code);
    }
  });

  test('every hazard but unknown is a listed code', () {
    expect(EventHazard.values.toSet(), {..._codes.values, EventHazard.unknown});
    expect(EventHazard.unknown.code, 'unknown');
  });

  test('codes are unique', () {
    final codes = [for (final h in EventHazard.values) h.code];
    expect(codes.toSet(), hasLength(codes.length));
  });

  test('null, empty and unrecognised codes are unknown', () {
    for (final code in [
      null,
      '',
      'heavyRain',
      'Heavy_Rain',
      'heavy-rain',
      ' earthquake',
      'meteor_strike',
    ]) {
      expect(EventHazard.fromCode(code), EventHazard.unknown, reason: code);
    }
  });
}
