import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_facts.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every distinct `type` + `addition` in the examples of dpip-server-go
/// `api.md` §5, copied as is.
List<({String id, String type, Map<String, dynamic> addition})> _examples() {
  final raw = File('test/fixtures/events_v2/facts/additions.json')
      .readAsStringSync();
  return [
    for (final e
        in (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>())
      (
        id: e['id'] as String,
        type: e['type'] as String,
        addition: e['addition'] as Map<String, dynamic>,
      ),
  ];
}

EventFact _f(EventFactKind kind, String display) => EventFact(kind, display);

EventFact _mi(int level, String label) =>
    EventFact(EventFactKind.maxIntensity, label, intensityLevel: level);

const _m = EventFactKind.magnitude;
const _depth = EventFactKind.depth;
const _loc = EventFactKind.epicenter;

final _eewFacts = [
  _f(_m, 'M 4.5'),
  _mi(4, '4'),
  _f(_depth, '10 km'),
  _f(_loc, '連江縣南竿鄉'),
];

final _tsunamiQuake = [_f(_m, 'M 7.2'), _f(_loc, '臺灣東部海域')];

/// The expected facts of each example, by its fixture id.
final _expected = <String, List<EventFact>>{
  'earthquake#1': [],
  'tsunami_note#1': [],
  'intensity#1': [_mi(5, '5⁻'), _f(EventFactKind.serial, '#1')],
  'intensity#2': [_mi(5, '5⁻'), _f(EventFactKind.serial, '#2')],
  'earthquake.eew#1': _eewFacts,
  'earthquake.eew#2': _eewFacts,
  'earthquake.eew#3': _eewFacts,
  'earthquake.eew.alert#1': [
    _f(_m, 'M 5.0'),
    _mi(4, '4'),
    _f(_depth, '10 km'),
    _f(_loc, '連江縣南竿鄉'),
  ],
  // Where shaking was detected, not an estimate: nothing to show, even from
  // an addition that still carries the `eq` the server has since dropped.
  'earthquake.detection#1': [],
  'earthquake.detection#2': [],
  'earthquake.station_missing#1': [_f(_m, 'M 5.2'), _f(_depth, '15 km')],
  // Estimates: 100 / 50 cm, arriving 20:56 / 21:16 Taipei.
  'tsunami.warning#1': [
    _f(EventFactKind.waveHeight, '100 cm'),
    _f(EventFactKind.arrivalTime, '20:56'),
    ..._tsunamiQuake,
  ],
  'tsunami.warning#2': [
    _f(EventFactKind.waveHeight, '100 cm'),
    _f(EventFactKind.arrivalTime, '20:56'),
    ..._tsunamiQuake,
  ],
  // A `forecast` with no data.
  'tsunami.warning#3': _tsunamiQuake,
  // Lifted: the estimates are no longer shown.
  'tsunami.warning#4': _tsunamiQuake,
  // Lifted with observations: 25 cm at the earliest 20:41.
  'tsunami.warning#5': [
    _f(EventFactKind.waveHeight, '25 cm'),
    _f(EventFactKind.arrivalTime, '20:41'),
    ..._tsunamiQuake,
  ],
  'tsunami.info#1': [_f(EventFactKind.originTime, '11:50')],
  'tsunami.info#2': [_f(EventFactKind.originTime, '11:50')],
  'heavy-rain#1': [],
  'heavy-rain#2': [],
  'heavy-rain#3': [],
  'extremely-heavy-rain#1': [],
  'extremely-torrential-rain#1': [],
  'debrisFlowLandSlide#1': [],
  'roadClose#1': [
    _f(EventFactKind.road, '台灣大道線'),
    _f(EventFactKind.location, '中清路口'),
  ],
  // The station and water level are empty strings.
  'floodSensor#1': [_f(EventFactKind.location, '臺南市安南區')],
  'heavy_rain.short#1': [_f(EventFactKind.rainfall, '50.5 mm')],
  'heavy_rain.short_extreme#1': [_f(EventFactKind.rainfall, '85 mm')],
  'wind.strong#1': [
    _f(EventFactKind.windSpeed, '21 m/s'),
    _f(EventFactKind.gust, '5 m/s'),
  ],
  // Mean wind from 梧棲, gust from 蘭嶼.
  'wind.damaging#1': [
    _f(EventFactKind.windSpeed, '33 m/s'),
    _f(EventFactKind.gust, '42 m/s'),
  ],
  // 20 + 20 + 160.
  'thunderstorm.lightning#1': [_f(EventFactKind.lightningStrikes, '200')],
  'river_rise.watch#1': [
    _f(EventFactKind.waterLevel, '7 m'),
    _f(EventFactKind.warningLevel, '6 m'),
  ],
  // The first station, 高屏溪里嶺, at stage l1up.
  'river_rise.warning#1': [
    _f(EventFactKind.waterLevel, '4.5 m'),
    _f(EventFactKind.warningLevel, '4 m'),
  ],
  'fog.visibility#1': [_f(EventFactKind.visibility, '< 1 km')],
  'announcement#1': [],
};

/// Every type api.md §5 lists with an `addition`.
const _typesWithAddition = [
  'earthquake',
  'tsunami_note',
  'intensity',
  'earthquake.eew',
  'earthquake.eew.alert',
  'earthquake.detection',
  'earthquake.station_missing',
  'tsunami.warning',
  'tsunami.info',
  'heavy-rain',
  'extremely-heavy-rain',
  'torrential-rain',
  'extremely-torrential-rain',
  'debrisFlowLandSlide',
  'roadClose',
  'floodSensor',
  'heavy_rain.short',
  'heavy_rain.short_extreme',
  'wind.strong',
  'wind.damaging',
  'thunderstorm.lightning',
  'river_rise.watch',
  'river_rise.warning',
  'fog.visibility',
  'announcement',
];

/// Deep copy of a decoded JSON object, to mutate in a test.
Map<String, dynamic> _copy(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

void main() {
  final examples = _examples();
  Map<String, dynamic> example(String id) =>
      _copy(examples.firstWhere((e) => e.id == id).addition);

  group('api.md §5 examples', () {
    test('every example has an expectation and vice versa', () {
      expect(examples.map((e) => e.id).toSet(), _expected.keys.toSet());
    });

    for (final e in _examples()) {
      test(e.id, () {
        expect(eventFactsFor(e.type, e.addition), _expected[e.id]);
      });
    }

    test('no type gives more than four facts', () {
      for (final e in examples) {
        expect(eventFactsFor(e.type, e.addition).length, lessThanOrEqualTo(4));
      }
    });
  });

  group('never throws on a bad addition', () {
    for (final type in [..._typesWithAddition, 'thunderstorm', 'seawave']) {
      test(type, () {
        expect(eventFactsFor(type, null), isEmpty);
        expect(eventFactsFor(type, {}), isEmpty);
        expect(
          eventFactsFor(type, {'eq': 'x', 'stations': 'x', 'info': 1}),
          isEmpty,
        );
        expect(
          eventFactsFor(type, {
            'eq': [1, 2],
            'stations': [1, 'x', null, <String, dynamic>{}],
            'info': {'type': 'estimate', 'data': 'x'},
            'max': 'x',
            'serial': 1.5,
            'roadName': 3,
            'areaDesc': '   ',
          }),
          isEmpty,
        );
      });
    }

    test('an unknown type gives nothing for any addition', () {
      for (final e in examples) {
        expect(eventFactsFor('unknown.${e.type}', e.addition), isEmpty);
      }
    });
  });

  group('one bad field drops only its own fact', () {
    test('earthquake: mistyped magnitude, out-of-range intensity', () {
      final a = example('earthquake.eew#1');
      (a['eq'] as Map<String, dynamic>)
        ..['mag'] = '4.5'
        ..['max'] = 10;
      expect(eventFactsFor('earthquake.eew', a), [
        _f(_depth, '10 km'),
        _f(_loc, '連江縣南竿鄉'),
      ]);
    });

    test('a whole number written as a double still reads', () {
      final a = example('intensity#1')..['max'] = 7.0;
      expect(eventFactsFor('intensity', a).first, _mi(7, '6⁻'));
    });

    test('tsunami: a mistyped row is skipped, the rest still counts', () {
      final a = example('tsunami.warning#1');
      final rows =
          ((a['info'] as Map<String, dynamic>)['data'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      rows.first
        ..['wave_height'] = 'high'
        ..['arrival_time'] = null;
      expect(eventFactsFor('tsunami.warning', a), [
        _f(EventFactKind.waveHeight, '50 cm'),
        _f(EventFactKind.arrivalTime, '21:16'),
        ..._tsunamiQuake,
      ]);
    });

    test('tsunami.info reads every optional eq field', () {
      final a = example('tsunami.info#1');
      (a['eq'] as Map<String, dynamic>)
        ..['mag'] = 6.84
        ..['depth'] = 12.5
        ..['loc'] = '花蓮縣近海';
      expect(eventFactsFor('tsunami.info', a), [
        _f(_m, 'M 6.8'),
        _f(_depth, '12.5 km'),
        _f(_loc, '花蓮縣近海'),
        _f(EventFactKind.originTime, '11:50'),
      ]);
    });

    test('meteor: -99 is no reading', () {
      final rain = example('heavy_rain.short#1');
      final station =
          (rain['stations'] as List<dynamic>).first as Map<String, dynamic>;
      (station['rain'] as Map<String, dynamic>)['1h'] = -99;
      expect(eventFactsFor('heavy_rain.short', rain), isEmpty);

      final wind = example('wind.damaging#1');
      final first =
          (wind['stations'] as List<dynamic>).first as Map<String, dynamic>;
      (first['wind'] as Map<String, dynamic>)['speed'] = -99;
      expect(eventFactsFor('wind.damaging', wind), [
        _f(EventFactKind.windSpeed, '5 m/s'),
        _f(EventFactKind.gust, '42 m/s'),
      ]);
    });

    test('river: a station without a level is passed over', () {
      final a = example('river_rise.warning#1');
      final first =
          (a['stations'] as List<dynamic>).first as Map<String, dynamic>;
      first['waterLevel'] = -99;
      expect(eventFactsFor('river_rise.warning', a), [
        _f(EventFactKind.waterLevel, '2.6 m'),
        _f(EventFactKind.warningLevel, '-1 m'),
      ]);
    });

    test('river: a null warning level leaves the water level', () {
      final a = example('river_rise.watch#1');
      final first =
          (a['stations'] as List<dynamic>).first as Map<String, dynamic>;
      first['warningLevel2'] = null;
      expect(eventFactsFor('river_rise.watch', a), [
        _f(EventFactKind.waterLevel, '7 m'),
      ]);
    });

    test('fog: the lowest station, by its text or its number', () {
      final a = example('fog.visibility#1');
      final stations = (a['stations'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      stations.last
        ..['visibility'] = 0.2
        ..['visibilityText'] = '＜0.4';
      expect(eventFactsFor('fog.visibility', a), [
        _f(EventFactKind.visibility, '< 0.4 km'),
      ]);
      stations.last.remove('visibilityText');
      expect(eventFactsFor('fog.visibility', a), [
        _f(EventFactKind.visibility, '0.2 km'),
      ]);
    });

    test('times out of DateTime range are left out', () {
      final a = example('tsunami.info#1');
      (a['eq'] as Map<String, dynamic>)['time'] = 9007199254740991;
      expect(eventFactsFor('tsunami.info', a), isEmpty);
    });
  });

  test('eventFactsOfReport reads the report type and addition', () {
    final report = EventReport(
      id: 1,
      serial: 1,
      kind: EventReportKind.issue,
      type: 'heavy_rain.short_extreme',
      hazard: EventHazard.heavyRain,
      hazardCode: 'heavy_rain',
      status: 1,
      author: 'cwa',
      lang: 'zh-TW',
      title: '',
      subtitle: '',
      send: DateTime.utc(2026),
      expires: null,
      hasPolygon: true,
      addition: example('heavy_rain.short_extreme#1'),
    );
    expect(eventFactsOfReport(report), [_f(EventFactKind.rainfall, '85 mm')]);
  });
}
