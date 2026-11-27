/// App API v2 card parsing, against every example in the server's api.md
/// (`test/fixtures/events_v2/`, copied verbatim) and against malformed input.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtureDir = 'test/fixtures/events_v2';

Object? _fixture(String name) =>
    jsonDecode(File('$_fixtureDir/$name.json').readAsStringSync());

/// Every fixture, with its top-level `lang` and one row per card:
///
///     id serial kind type hazard lang send expires polygon [area=N] [description] [original]
///
/// `kind` and `hazard` are enum names; `expires` is the wire value, or `open`
/// for [kEventExpiresOpenMs]; `polygon` is `polygon` or `-`. A detail row
/// adds the area length and which optional fields the report carries.
/// Generated from the api.md examples, not from the parser.
const _fixtures = <String, (String, List<String>)>{
  'announcement_detail': (
    'zh-TW',
    [
      '1795737600 1 issue announcement announcement zh-TW 1795737600000 1795824000000 - area=12 description',
      '1795737600 2 cancel announcement announcement zh-TW 1795741200000 1795741200000 - area=12 description',
    ],
  ),
  'announcement_list': (
    'zh-TW',
    [
      '1795737600 1 issue announcement announcement zh-TW 1795737600000 1795824000000 -',
    ],
  ),
  'barrierLake_detail': (
    'zh-TW',
    [
      '1717214400 1 issue barrierLake landslideDam zh-TW 1717213800000 1717236000000 polygon area=0 description',
    ],
  ),
  'barrierLake_list': (
    'zh-TW',
    [
      '1717214400 1 issue barrierLake landslideDam zh-TW 1717213800000 1717236000000 polygon',
    ],
  ),
  'debrisFlowLandSlide_detail': (
    'zh-TW',
    [
      '1717214400 1 issue debrisFlowLandSlide debrisFlow zh-TW 1717213800000 1717236000000 polygon area=0 description',
    ],
  ),
  'debrisFlowLandSlide_list': (
    'zh-TW',
    [
      '1717214400 1 issue debrisFlowLandSlide debrisFlow zh-TW 1717213800000 1717236000000 polygon',
    ],
  ),
  'earthquake_detail': (
    'zh-TW',
    [
      '1785069451 1 issue earthquake earthquake zh-TW 1785069391000 1785155791000 - area=4 description',
    ],
  ),
  'earthquake_detection_detail': (
    'zh-TW',
    [
      '1785069442 1 issue earthquake.detection earthquake zh-TW 1785069441000 1785155841000 - area=3 description',
      '1785069442 2 update earthquake.detection earthquake zh-TW 1785069441000 1785155841000 - area=3 description',
    ],
  ),
  'earthquake_detection_list': (
    'zh-TW',
    [
      '1785069442 2 update earthquake.detection earthquake zh-TW 1785069441000 1785155841000 -',
    ],
  ),
  'earthquake_eew_alert_detail': (
    'zh-TW',
    [
      '1785069401 1 issue earthquake.eew earthquake zh-TW 1785069401000 1785155801000 - area=5 description',
      '1785069401 2 update earthquake.eew.alert earthquake zh-TW 1785069406000 1785155806000 - area=15 description',
    ],
  ),
  'earthquake_eew_alert_list': (
    'zh-TW',
    [
      '1785069401 2 update earthquake.eew.alert earthquake zh-TW 1785069406000 1785155806000 -',
    ],
  ),
  'earthquake_eew_detail': (
    'zh-TW',
    [
      '1785069401 1 issue earthquake.eew earthquake zh-TW 1785069401000 1785155801000 - area=5 description',
      '1785069401 2 update earthquake.eew earthquake zh-TW 1785069406000 1785155806000 - area=5 description',
    ],
  ),
  'earthquake_eew_list': (
    'zh-TW',
    [
      '1785069401 2 update earthquake.eew earthquake zh-TW 1785069406000 1785155806000 -',
    ],
  ),
  'earthquake_list': (
    'zh-TW',
    [
      '1785069451 1 issue earthquake earthquake zh-TW 1785069391000 1785155791000 -',
      '1785069452 1 issue tsunami_note tsunami zh-TW 1785069391000 1785155791000 -',
    ],
  ),
  'earthquake_station_missing_detail': (
    'zh-TW',
    [
      '1717214400 1 issue earthquake.station_missing earthquake zh-TW 1717213500000 1717299900000 - area=3 description',
    ],
  ),
  'earthquake_station_missing_list': (
    'zh-TW',
    [
      '1717214400 1 issue earthquake.station_missing earthquake zh-TW 1717213500000 1717299900000 -',
    ],
  ),
  'extremely-heavy-rain_detail': (
    'zh-TW',
    [
      '1717214430 1 issue extremely-heavy-rain heavyRain zh-TW 1717214400000 1717254000000 - area=1 description',
    ],
  ),
  'extremely-heavy-rain_list': (
    'zh-TW',
    [
      '1717214430 1 issue extremely-heavy-rain heavyRain zh-TW 1717214400000 1717254000000 -',
    ],
  ),
  'extremely-torrential-rain_detail': (
    'zh-TW',
    [
      '1717214400 1 issue extremely-torrential-rain heavyRain zh-TW 1717213800000 1717254000000 - area=1 description',
    ],
  ),
  'extremely-torrential-rain_list': (
    'zh-TW',
    [
      '1717214400 1 issue extremely-torrential-rain heavyRain zh-TW 1717213800000 1717254000000 -',
    ],
  ),
  'floodSensor_detail': (
    'zh-TW',
    [
      '1717214400 1 issue floodSensor flood zh-TW 1717213800000 1717236000000 polygon area=0 description',
    ],
  ),
  'floodSensor_list': (
    'zh-TW',
    [
      '1717214400 1 issue floodSensor flood zh-TW 1717213800000 1717236000000 polygon',
    ],
  ),
  'fog_visibility_detail': (
    'zh-TW',
    [
      '1794997800 1 issue fog.visibility fog zh-TW 1794997800000 1795019400000 polygon area=9 description',
    ],
  ),
  'fog_visibility_list': (
    'zh-TW',
    [
      '1794997800 1 issue fog.visibility fog zh-TW 1794997800000 1795019400000 polygon',
    ],
  ),
  'heavy-rain_detail': (
    'zh-TW',
    [
      '1717214400 1 issue heavy-rain heavyRain zh-TW 1717213800000 1717254000000 - area=1 description',
      '1717214400 2 cancel heavy-rain heavyRain zh-TW 1717214460000 1717214460000 - area=1 description',
    ],
  ),
  'heavy-rain_list': (
    'zh-TW',
    [
      '1717214400 1 issue heavy-rain heavyRain zh-TW 1717213800000 1717254000000 -',
    ],
  ),
  'heavy-rain_upgrade-detail': (
    'zh-TW',
    [
      '1717214400 1 issue heavy-rain heavyRain zh-TW 1717213800000 1717254000000 - area=1 description',
      '1717214400 2 update heavy-rain heavyRain zh-TW 1717214400000 1717214400000 - area=0 description',
    ],
  ),
  'heavy_rain_short_detail': (
    'zh-TW',
    [
      '1794976200 1 issue heavy_rain.short heavyRain zh-TW 1794974400000 1794978000000 polygon area=11 description',
    ],
  ),
  'heavy_rain_short_extreme_detail': (
    'zh-TW',
    [
      '1794977700 1 issue heavy_rain.short_extreme heavyRain zh-TW 1794976800000 1794980400000 polygon area=11 description',
    ],
  ),
  'heavy_rain_short_list': (
    'zh-TW',
    [
      '1794976200 1 issue heavy_rain.short heavyRain zh-TW 1794974400000 1794978000000 polygon',
      '1794977700 1 issue heavy_rain.short_extreme heavyRain zh-TW 1794976800000 1794980400000 polygon',
    ],
  ),
  'intensity_detail-preview': (
    'zh-TW',
    [
      '1785070411 1 issue intensity earthquake zh-TW 1785070411000 1785156801000 - area=3 description',
    ],
  ),
  'intensity_detail': (
    'zh-TW',
    [
      '1785070411 1 issue intensity earthquake zh-TW 1785070411000 1785156801000 - area=3 description',
      '1785070411 2 update intensity earthquake zh-TW 1785070411000 1785156801000 - area=3 description',
    ],
  ),
  'intensity_list': (
    'zh-TW',
    [
      '1785070411 2 update intensity earthquake zh-TW 1785070411000 1785156801000 -',
    ],
  ),
  'overview_addition_detail': (
    'en',
    ['42 1 issue earthquake earthquake zh-TW 1000 2000 - area=0 description'],
  ),
  'overview_history_list': (
    'zh-TW',
    [
      '1800000000 3 cancel heavy-rain heavyRain zh-TW 1799999400000 1799999400000 -',
      '1800000001 2 update heavy-rain heavyRain zh-TW 1799913600000 1800086400000 -',
      '1800000002 2 cancel heavy-rain heavyRain zh-TW 1799913600000 1799913600000 -',
    ],
  ),
  'overview_list': (
    'en',
    [
      '1001 1 issue thunderstorm thunderstorm en 1699996400000 1700003600000 -',
      '1002 1 issue heavy-rain heavyRain en 1699992800000 1700007200000 polygon',
      '1003 1 issue earthquake earthquake zh-TW 1699998800000 1700010800000 polygon',
      '1008 1 issue tsunami tsunami zh-TW 1699999520000 1700021600000 -',
    ],
  ),
  'overview_translated_detail': (
    'en',
    [
      '1800000000 1 issue heavy-rain heavyRain en 1799992800000 1800010800000 - area=1 description original',
      '1800000000 2 update heavy-rain heavyRain zh-TW 1799996400000 1800021600000 - area=2 description',
      '1800000000 3 cancel heavy-rain heavyRain zh-TW 1799999400000 1799999400000 - area=2 description',
    ],
  ),
  'river_rise_list': (
    'zh-TW',
    [
      '1718434800 1 issue river_rise.watch riverRise zh-TW 1718434800000 1718445600000 polygon',
      '1718434801 1 issue river_rise.warning riverRise zh-TW 1718434800000 1718445600000 polygon',
    ],
  ),
  'river_rise_warning_detail': (
    'zh-TW',
    [
      '1718434801 1 issue river_rise.warning riverRise zh-TW 1718434800000 1718445600000 polygon area=5 description',
    ],
  ),
  'river_rise_watch_detail': (
    'zh-TW',
    [
      '1718434800 1 issue river_rise.watch riverRise zh-TW 1718434800000 1718445600000 polygon area=2 description',
    ],
  ),
  'roadClose_detail': (
    'zh-TW',
    [
      '1717214400 1 issue roadClose roadClosure zh-TW 1717213800000 1717236000000 polygon area=0 description',
    ],
  ),
  'roadClose_list': (
    'zh-TW',
    [
      '1717214400 1 issue roadClose roadClosure zh-TW 1717213800000 1717236000000 polygon',
    ],
  ),
  'seawave_detail': (
    'zh-TW',
    [
      '1717214400 1 issue seawave swell zh-TW 1717214400000 1717225200000 polygon area=0 description',
      '1717214400 2 update seawave swell zh-TW 1717225200000 1717236000000 polygon area=0 description',
    ],
  ),
  'seawave_list': (
    'zh-TW',
    [
      '1717214400 1 issue seawave swell zh-TW 1717214400000 1717225200000 polygon',
    ],
  ),
  'thunderstorm_detail': (
    'zh-TW',
    [
      '1717214400 1 issue thunderstorm thunderstorm zh-TW 1717213800000 1717217400000 polygon area=0 description',
    ],
  ),
  'thunderstorm_lightning_detail': (
    'zh-TW',
    [
      '1794998700 1 issue thunderstorm.lightning thunderstorm zh-TW 1794997800000 1795008600000 polygon area=15 description',
    ],
  ),
  'thunderstorm_lightning_list': (
    'zh-TW',
    [
      '1794998700 1 issue thunderstorm.lightning thunderstorm zh-TW 1794997800000 1795008600000 polygon',
    ],
  ),
  'thunderstorm_list': (
    'zh-TW',
    [
      '1717214400 1 issue thunderstorm thunderstorm zh-TW 1717213800000 1717217400000 polygon',
      '1717214401 1 issue thunderstorm thunderstorm zh-TW 1717213800000 1717217400000 polygon',
    ],
  ),
  'thunderstorm_tornado-detail': (
    'zh-TW',
    [
      '1717214401 1 issue thunderstorm thunderstorm zh-TW 1717213800000 1717217400000 polygon area=0 description',
    ],
  ),
  'torrential-rain_detail': (
    'zh-TW',
    [
      '1700000000 1 issue torrential-rain heavyRain zh-TW 1699999700000 1700007200000 - area=1 description',
    ],
  ),
  'torrential-rain_list': (
    'zh-TW',
    [
      '1700000000 1 issue torrential-rain heavyRain zh-TW 1699999700000 1700007200000 -',
    ],
  ),
  'tsunami_info_detail': (
    'zh-TW',
    [
      '1717214400 1 issue tsunami.info tsunami zh-TW 1717214400000 1717300800000 - area=110 description',
      '1717214400 2 update tsunami.info tsunami zh-TW 1717214415000 1717300815000 - area=110 description',
    ],
  ),
  'tsunami_info_list': (
    'zh-TW',
    [
      '1717214400 2 update tsunami.info tsunami zh-TW 1717214415000 1717300815000 -',
    ],
  ),
  'tsunami_note_detail': (
    'zh-TW',
    [
      '1785069452 1 issue tsunami_note tsunami zh-TW 1785069391000 1785155791000 - area=110 description',
    ],
  ),
  'tsunami_note_list': (
    'zh-TW',
    [
      '1785069452 1 issue tsunami_note tsunami zh-TW 1785069391000 1785155791000 -',
    ],
  ),
  'tsunami_warning_detail': (
    'zh-TW',
    [
      '1785069392 1 issue tsunami.warning tsunami zh-TW 1785069392350 open - area=110 description',
      '1785069392 2 update tsunami.warning tsunami zh-TW 1785069992350 open - area=110 description',
      '1785069392 3 update tsunami.warning tsunami zh-TW 1785070592350 open - area=110 description',
      '1785069392 4 update tsunami.warning tsunami zh-TW 1785071192350 1785157592350 - area=110 description',
      '1785069392 5 update tsunami.warning tsunami zh-TW 1785071792350 1785158192350 - area=110 description',
    ],
  ),
  'tsunami_warning_list': (
    'zh-TW',
    ['1785069392 3 update tsunami.warning tsunami zh-TW 1785070592350 open -'],
  ),
  'wind_damaging_detail': (
    'zh-TW',
    [
      '1717200001 1 issue wind.damaging wind zh-TW 1717200000000 1717209000000 polygon area=13 description',
    ],
  ),
  'wind_list': (
    'zh-TW',
    [
      '1717200000 1 issue wind.strong wind zh-TW 1717200000000 1717209000000 polygon',
      '1717200001 1 issue wind.damaging wind zh-TW 1717200000000 1717209000000 polygon',
    ],
  ),
  'wind_strong_detail': (
    'zh-TW',
    [
      '1717200000 1 issue wind.strong wind zh-TW 1717200000000 1717209000000 polygon area=11 description',
    ],
  ),
  'workSchlClos_detail': (
    'zh-TW',
    [
      '1717214400 1 issue workSchlClos closure zh-TW 1717213800000 1717236000000 - area=3 description',
    ],
  ),
  'workSchlClos_list': (
    'zh-TW',
    [
      '1717214400 1 issue workSchlClos closure zh-TW 1717213800000 1717236000000 -',
    ],
  ),
};

/// A minimal valid list card, for the malformed-input cases to break.
Map<String, dynamic> _card({int id = 1001, int serial = 1}) => {
  'id': id,
  'serial': serial,
  'kind': 'issue',
  'type': 'thunderstorm',
  'hazard': 'thunderstorm',
  'status': 1,
  'author': 'test',
  'lang': 'zh-TW',
  'title': '大雷雨即時訊息',
  'subtitle': '臺北市',
  'send': 1699996400000,
  'expires': 1700003600000,
  'hasPolygon': false,
};

/// [_card] with the fields only a detail report has.
Map<String, dynamic> _report({int id = 1001, int serial = 1}) => {
  ..._card(id: id, serial: serial),
  'area': [100, 101],
  'description': '說明',
};

DateTime _utc(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

void _expectRow(EventCard card, String row, {required String where}) {
  final f = row.split(' ');
  final reason = '$where: $row';
  expect(card.id, int.parse(f[0]), reason: reason);
  expect(card.serial, int.parse(f[1]), reason: reason);
  expect(card.kind, EventReportKind.values.byName(f[2]), reason: reason);
  expect(card.type, f[3], reason: reason);
  final hazard = EventHazard.values.byName(f[4]);
  expect(card.hazard, hazard, reason: reason);
  expect(card.hazardCode, hazard.code, reason: reason);
  expect(card.lang, f[5], reason: reason);
  expect(card.send, _utc(int.parse(f[6])), reason: reason);
  expect(card.send.isUtc, isTrue, reason: reason);
  switch (f[7]) {
    case 'open':
      expect(card.expires, isNull, reason: reason);
      expect(card.expiresOpen, isTrue, reason: reason);
    case '0':
      expect(card.expires, isNull, reason: reason);
      expect(card.expiresOpen, isFalse, reason: reason);
    case final ms:
      expect(card.expires, _utc(int.parse(ms)), reason: reason);
      expect(card.expires!.isUtc, isTrue, reason: reason);
      expect(card.expiresOpen, isFalse, reason: reason);
  }
  expect(card.hasPolygon, f[8] == 'polygon', reason: reason);
}

void main() {
  group('api.md examples', () {
    test('every fixture on disk has expectations', () {
      final onDisk = Directory(_fixtureDir)
          .listSync()
          .map((entry) => entry.uri.pathSegments.last)
          .where((name) => name.endsWith('.json'))
          .map((name) => name.substring(0, name.length - '.json'.length))
          .toSet();
      expect(onDisk, _fixtures.keys.toSet());
    });

    for (final MapEntry(key: name, value: (lang, rows)) in _fixtures.entries) {
      if (name.contains('detail')) {
        test('$name parses as a detail', () {
          final json = _fixture(name);
          final detail = EventCardDetail.fromJson(json);
          expect(detail.lang, lang);
          expect(detail.reports, hasLength(rows.length));

          final raw =
              ((json! as Map<String, dynamic>)['cards'] as List<dynamic>)
                  .cast<Map<String, dynamic>>();
          for (final (i, report) in detail.reports.indexed) {
            final row = rows[i];
            _expectRow(report, row, where: name);
            final extras = row.split(' ').skip(9).toSet();
            final areaLength = int.parse(
              extras.firstWhere((t) => t.startsWith('area=')).substring(5),
            );
            expect(report.area, hasLength(areaLength), reason: row);
            expect(report.area, raw[i]['area'], reason: row);
            expect(report.description != null, extras.contains('description'));
            expect(report.description, raw[i]['description'], reason: row);
            expect(report.addition, raw[i]['addition'], reason: row);
            expect(report.polygon, raw[i]['polygon'], reason: row);
            expect(report.polygon != null, report.hasPolygon, reason: row);
            expect(report.original != null, extras.contains('original'));
          }
          final serials = [for (final r in detail.reports) r.serial];
          expect(serials, [...serials]..sort());
        });
      } else {
        test('$name parses as a list', () {
          final list = EventCardList.fromJson(_fixture(name));
          expect(list.lang, lang);
          expect(list.cards, hasLength(rows.length));
          for (final (i, card) in list.cards.indexed) {
            _expectRow(card, rows[i], where: name);
          }
        });
      }
    }

    test('a translated report carries its original text', () {
      final detail = EventCardDetail.fromJson(
        _fixture('overview_translated_detail'),
      );
      final [first, second, third] = detail.reports;
      expect(first.lang, 'en');
      expect(first.title, 'Heavy rain advisory');
      expect(first.original?.title, '大雨特報');
      expect(first.original?.subtitle, '臺北市');
      expect(first.original?.description, '臺北市有大雨');
      expect(second.original, isNull);
      expect(third.original, isNull);
      expect(detail.latest.kind, EventReportKind.cancel);
    });

    test('addition is kept as sent', () {
      final detail = EventCardDetail.fromJson(
        _fixture('overview_addition_detail'),
      );
      expect(detail.latest.addition, {
        'max': 4,
        'area': ['臺北市'],
      });
      expect(detail.latest.area, isEmpty);
    });

    test('the eew card changes type when it is upgraded', () {
      final detail = EventCardDetail.fromJson(
        _fixture('earthquake_eew_alert_detail'),
      );
      expect(
        [for (final r in detail.reports) r.type],
        ['earthquake.eew', 'earthquake.eew.alert'],
      );
      expect(detail.latest.hazard, EventHazard.earthquake);
    });

    test('an open-ended tsunami warning is active until it is lifted', () {
      final list = EventCardList.fromJson(_fixture('tsunami_warning_list'));
      final card = list.cards.single;
      expect(card.expiresOpen, isTrue);
      expect(card.isActiveAt(_utc(kEventExpiresOpenMs + 1)), isTrue);

      final detail = EventCardDetail.fromJson(
        _fixture('tsunami_warning_detail'),
      );
      final lifted = detail.latest;
      expect(lifted.expiresOpen, isFalse);
      expect(lifted.isActiveAt(lifted.send), isTrue);
      expect(lifted.isActiveAt(lifted.expires!), isFalse);
    });
  });

  group('degrades instead of throwing', () {
    test('an unknown type is kept and the hazard comes from the server', () {
      final card = EventCard.tryParse({
        ..._card(),
        'type': 'volcano.eruption',
        'hazard': 'volcano',
      })!;
      expect(card.type, 'volcano.eruption');
      expect(card.hazard, EventHazard.volcano);
    });

    test('an unknown hazard is unknown, with the code kept', () {
      final card = EventCard.tryParse({..._card(), 'hazard': 'meteor_strike'})!;
      expect(card.hazard, EventHazard.unknown);
      expect(card.hazardCode, 'meteor_strike');
    });

    test('the hazard is never derived from the type', () {
      for (final hazard in <Object?>[null, '', 42]) {
        final json = {..._card(), 'type': 'heavy-rain', 'hazard': hazard};
        final card = EventCard.tryParse(json)!;
        expect(card.hazard, EventHazard.unknown, reason: '$hazard');
        expect(card.hazardCode, '', reason: '$hazard');
      }
      final missing = _card()..remove('hazard');
      expect(EventCard.tryParse(missing)!.hazard, EventHazard.unknown);
    });

    test('an unknown, missing or mistyped kind is unknown', () {
      for (final kind in <Object?>['retract', 'ISSUE', '', null, 1]) {
        final card = EventCard.tryParse({..._card(), 'kind': kind})!;
        expect(card.kind, EventReportKind.unknown, reason: '$kind');
      }
    });

    test('a missing or mistyped hasPolygon is false', () {
      expect(
        EventCard.tryParse(_card()..remove('hasPolygon'))!.hasPolygon,
        isFalse,
      );
      expect(
        EventCard.tryParse({..._card(), 'hasPolygon': 1})!.hasPolygon,
        isFalse,
      );
    });
  });

  group('expires', () {
    test('0 means no end time', () {
      final card = EventCard.tryParse({..._card(), 'expires': 0})!;
      expect(card.expires, isNull);
      expect(card.expiresOpen, isFalse);
      expect(card.isActiveAt(_utc(0)), isFalse);
    });

    test('a missing or mistyped value means no end time', () {
      for (final expires in <Object?>[null, '1700003600000', true]) {
        final card = EventCard.tryParse({..._card(), 'expires': expires})!;
        expect(card.expires, isNull, reason: '$expires');
        expect(card.expiresOpen, isFalse, reason: '$expires');
      }
      expect(EventCard.tryParse(_card()..remove('expires'))!.expires, isNull);
    });

    test('253402300799000 is open-ended, not a date', () {
      final card = EventCard.tryParse({
        ..._card(),
        'expires': 253402300799000,
      })!;
      expect(card.expires, isNull);
      expect(card.expiresOpen, isTrue);
      expect(card.isActiveAt(_utc(253402300799000)), isTrue);
    });

    test('isActiveAt is strictly before the end time', () {
      final card = EventCard.tryParse(_card())!;
      expect(card.isActiveAt(_utc(1700003599999)), isTrue);
      expect(card.isActiveAt(_utc(1700003600000)), isFalse);
      expect(card.isActiveAt(_utc(1700003600001)), isFalse);
      // A local-zone instant compares by instant, not by wall clock.
      expect(card.isActiveAt(_utc(1700003599999).toLocal()), isTrue);
    });
  });

  group('numbers', () {
    test('a whole double is accepted wherever an int is', () {
      final card = EventCard.tryParse({
        ..._card(),
        'id': 1001.0,
        'serial': 2.0,
        'status': 1.0,
        'send': 1699996400000.0,
        'expires': 1700003600000.0,
      })!;
      expect(card.id, 1001);
      expect(card.serial, 2);
      expect(card.send, _utc(1699996400000));
      expect(card.expires, _utc(1700003600000));
    });

    test('a decimal string id is accepted', () {
      expect(EventCard.tryParse({..._card(), 'id': '1001'})!.id, 1001);
    });

    test('any other id shape drops the card', () {
      for (final id in <Object?>[
        ' 1001',
        '1001 ',
        '+1001',
        '0x10',
        '1.5',
        '1e3',
        '',
        1001.5,
        null,
        true,
        [1001],
      ]) {
        expect(
          EventCard.tryParse({..._card(), 'id': id}),
          isNull,
          reason: '$id',
        );
      }
    });

    test('a fractional or out-of-range number drops the card', () {
      expect(EventCard.tryParse({..._card(), 'serial': 1.5}), isNull);
      expect(EventCard.tryParse({..._card(), 'send': double.nan}), isNull);
      expect(EventCard.tryParse({..._card(), 'send': 1e300}), isNull);
      expect(
        EventCard.tryParse({..._card(), 'send': 8640000000000001}),
        isNull,
      );
    });
  });

  group('malformed cards', () {
    test('a non-object is null', () {
      for (final json in <Object?>[null, 42, 'card', <Object?>[], true]) {
        expect(EventCard.tryParse(json), isNull, reason: '$json');
        expect(EventReport.tryParse(json), isNull, reason: '$json');
      }
    });

    test('a missing or mistyped required field drops the card', () {
      for (final key in [
        'id',
        'serial',
        'type',
        'status',
        'author',
        'lang',
        'title',
        'subtitle',
        'send',
      ]) {
        expect(EventCard.tryParse(_card()..remove(key)), isNull, reason: key);
        expect(
          EventCard.tryParse({..._card(), key: <String, dynamic>{}}),
          isNull,
          reason: key,
        );
      }
    });

    test('a list skips the cards it cannot read', () {
      final list = EventCardList.fromJson({
        'lang': 'zh-TW',
        'cards': [
          _card(id: 1),
          {..._card(), 'send': 'yesterday'},
          'not a card',
          null,
          _card()..remove('title'),
          _card(id: 2),
        ],
      });
      expect([for (final c in list.cards) c.id], [1, 2]);
    });

    test('an empty list is a list', () {
      final list = EventCardList.fromJson({'lang': 'en', 'cards': <Object?>[]});
      expect(list.lang, 'en');
      expect(list.cards, isEmpty);
    });

    test('a list body of the wrong shape throws FormatException', () {
      for (final json in <Object?>[
        null,
        <Object?>[],
        'cards',
        {'cards': <Object?>[]},
        {'lang': 'zh-TW'},
        {'lang': 1, 'cards': <Object?>[]},
        {'lang': 'zh-TW', 'cards': <String, dynamic>{}},
      ]) {
        expect(
          () => EventCardList.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });
  });

  group('detail', () {
    test('reports are ordered by serial and the latest is the last', () {
      final detail = EventCardDetail.fromJson({
        'lang': 'zh-TW',
        'cards': [
          _report(serial: 3),
          _report(serial: 1),
          {..._report(serial: 2), 'kind': 'update'},
        ],
      });
      expect([for (final r in detail.reports) r.serial], [1, 2, 3]);
      expect(detail.latest.serial, 3);
    });

    test('a report it cannot read is skipped', () {
      final detail = EventCardDetail.fromJson({
        'lang': 'zh-TW',
        'cards': [_report(serial: 1), _report(serial: 2)..remove('send')],
      });
      expect(detail.reports, hasLength(1));
      expect(detail.latest.serial, 1);
    });

    test('no readable report throws FormatException', () {
      for (final cards in [
        <Object?>[],
        [null, _report()..remove('id')],
      ]) {
        expect(
          () => EventCardDetail.fromJson({'lang': 'zh-TW', 'cards': cards}),
          throwsFormatException,
        );
      }
    });

    test('a detail body of the wrong shape throws FormatException', () {
      for (final json in <Object?>[
        null,
        42,
        {
          'lang': 'zh-TW',
          'reports': [_report()],
        },
        {
          'cards': [_report()],
        },
      ]) {
        expect(
          () => EventCardDetail.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('optional report fields fall back to empty', () {
      final bare = _card();
      final report = EventReport.tryParse(bare)!;
      expect(report.area, isEmpty);
      expect(report.addition, isNull);
      expect(report.description, isNull);
      expect(report.polygon, isNull);
      expect(report.original, isNull);

      final mistyped = EventReport.tryParse({
        ..._report(),
        'area': 'all',
        'addition': ['not', 'an', 'object'],
        'description': 7,
        'polygon': 'FeatureCollection',
        'original': {'title': '只有標題'},
      })!;
      expect(mistyped.area, isEmpty);
      expect(mistyped.addition, isNull);
      expect(mistyped.description, isNull);
      expect(mistyped.polygon, isNull);
      expect(mistyped.original, isNull);
    });

    test('an area keeps only its integer codes', () {
      final report = EventReport.tryParse({
        ..._report(),
        'area': [100, '101', 102.0, null, 103.5],
      })!;
      expect(report.area, [100, 102]);
    });

    test('a JSON null addition is no addition', () {
      final report = EventReport.tryParse({..._report(), 'addition': null})!;
      expect(report.addition, isNull);
    });
  });

  group('EventReportKind.fromWire', () {
    test('maps every wire kind', () {
      expect(EventReportKind.fromWire('issue'), EventReportKind.issue);
      expect(EventReportKind.fromWire('update'), EventReportKind.update);
      expect(EventReportKind.fromWire('correct'), EventReportKind.correct);
      expect(EventReportKind.fromWire('cancel'), EventReportKind.cancel);
    });

    test('anything else is unknown', () {
      for (final value in [null, '', 'Cancel', 'unknown', 'withdraw']) {
        expect(EventReportKind.fromWire(value), EventReportKind.unknown);
      }
    });
  });
}
