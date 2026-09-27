/// The CAP typhoon-warning bulletin behind the alert banner and the
/// warning-detail sheet. [WarningFix] renames four wire keys (`t`, `lat`,
/// `lon`, `pres`) to readable Dart names via `@JsonKey`; a typo in any one of
/// those mappings would still compile, and would just silently read the wrong
/// wire field (or null) on every live bulletin — the round trip below pins
/// each wire spelling to the getter that must read it.
///
/// [TyphoonWarning.tdNo] and [TyphoonWarning.typhoon] are deliberately
/// nullable: a `Cancel` bulletin can arrive for a storm that has already aged
/// out of the active-cyclone index, so it can no longer be matched to a
/// `tdNo` or a track — the UI still has to render that bulletin.
/// [WarningPayload.decode] shares the same lenient-payload helper as the
/// other typhoon datasets, so one malformed `cyclones` entry is skipped
/// instead of failing the whole bulletin fetch.
library;

import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fully-populated fix — every optional field given a real value, so a
/// `toJson` comparison against the original map can't be fooled by a field
/// that happens to default to null on both sides.
Map<String, dynamic> _fixJson({int t = 1758000000, double lat = 23.5}) => {
  't': t,
  'lat': lat,
  'lon': 121.8,
  'wind': 45.5,
  'gust': 58.0,
  'pres': 955.0,
  'r15': 220.0,
  'scale': ['中度颱風', 'moderate typhoon'],
};

void main() {
  group('WarningFix', () {
    test('fromJson reads t/lat/lon/pres, toJson restores the wire keys', () {
      final json = _fixJson();

      final fix = WarningFix.fromJson(json);

      expect(fix.time, 1758000000);
      expect(fix.latitude, 23.5);
      expect(fix.longitude, 121.8);
      expect(fix.wind, 45.5);
      expect(fix.gust, 58.0);
      expect(fix.pressure, 955.0);
      expect(fix.r15, 220.0);
      expect(fix.scale, ['中度颱風', 'moderate typhoon']);
      expect(fix.toJson(), json);
    });

    test('an unclassified fix has a null scale, not an empty pair', () {
      final fix = WarningFix.fromJson(const {
        't': 1758000000,
        'lat': 23.5,
        'lon': 121.8,
      });

      expect(fix.scale, isNull);
      expect(fix.wind, isNull);
    });
  });

  group('WarningTyphoon', () {
    test('fromJson/toJson round-trips the identity and both fixes', () {
      final json = <String, dynamic>{
        'no': '202516',
        'name': 'HAISHEN',
        'cwaName': '海神',
        'reportNo': '003',
        'category': null,
        'analysis': _fixJson(),
        'prediction': _fixJson(t: 1758010800, lat: 23.8),
      };

      final typhoon = WarningTyphoon.fromJson(json);

      expect(typhoon.no, '202516');
      expect(typhoon.name, 'HAISHEN');
      expect(typhoon.cwaName, '海神');
      expect(typhoon.analysis.latitude, 23.5);
      expect(typhoon.prediction?.latitude, 23.8);
      expect(typhoon.toJson(), json);
    });

    test('a bulletin with no forecast fix leaves prediction null', () {
      final typhoon = WarningTyphoon.fromJson({
        'no': '202516',
        'name': 'HAISHEN',
        'cwaName': null,
        'reportNo': null,
        'category': null,
        'analysis': _fixJson(),
        'prediction': null,
      });

      expect(typhoon.prediction, isNull);
    });
  });

  group('WarningSection and WarningArea', () {
    test('fromJson/toJson round-trip', () {
      final section = WarningSection.fromJson(const {
        'title': '警戒事項',
        'text': '注意強風豪雨',
      });
      expect(section.title, '警戒事項');
      expect(section.text, '注意強風豪雨');
      expect(section.toJson(), const {'title': '警戒事項', 'text': '注意強風豪雨'});

      final area = WarningArea.fromJson(const {'name': '花蓮縣', 'code': '10015'});
      expect(area.name, '花蓮縣');
      expect(area.code, '10015');
      expect(area.toJson(), const {'name': '花蓮縣', 'code': '10015'});
    });
  });

  group('TyphoonWarning', () {
    Map<String, dynamic> bulletinJson({
      String msgType = 'Alert',
      String? tdNo = '15',
      Map<String, dynamic>? typhoon,
    }) => {
      'tdNo': tdNo,
      'active': true,
      'id': 'CWA-TY-2026-15-003',
      'sent': 1758000000,
      'status': 'Actual',
      'msgType': msgType,
      'scope': 'Public',
      'event': '颱風警報',
      'urgency': 'Immediate',
      'severity': 'Severe',
      'certainty': 'Observed',
      'effective': 1758000000,
      'onset': 1758000000,
      'expires': 1758086400,
      'headline': '海神颱風警報',
      'senderName': 'CWA',
      'typhoon': typhoon,
      'sections': [
        {'title': '警戒事項', 'text': '注意強風豪雨'},
      ],
      'areas': [
        {'name': '花蓮縣', 'code': '10015'},
      ],
    };

    test('fromJson/toJson round-trips a full bulletin', () {
      final json = bulletinJson(
        typhoon: {
          'no': '202516',
          'name': 'HAISHEN',
          'cwaName': '海神',
          'reportNo': '003',
          'category': null,
          'analysis': _fixJson(),
          'prediction': null,
        },
      );

      final warning = TyphoonWarning.fromJson(json);

      expect(warning.tdNo, '15');
      expect(warning.active, isTrue);
      expect(warning.msgType, 'Alert');
      expect(warning.typhoon?.name, 'HAISHEN');
      expect(warning.sections.single.title, '警戒事項');
      expect(warning.areas.single.code, '10015');
      expect(warning.toJson(), json);
    });

    test('tdNo and typhoon are null for an unmatched Cancel bulletin', () {
      final warning = TyphoonWarning.fromJson(
        bulletinJson(msgType: 'Cancel', tdNo: null, typhoon: null),
      );

      expect(warning.tdNo, isNull);
      expect(warning.typhoon, isNull);
      expect(warning.msgType, 'Cancel');
    });
  });

  group('WarningPayload.decode', () {
    test('decodes each bulletin through TyphoonWarning.fromJson', () {
      final payload = WarningPayload.decode({
        'updated': 1758000000,
        'cyclones': [
          {
            'tdNo': null,
            'active': true,
            'id': 'a',
            'sent': 1,
            'status': 'Actual',
            'msgType': 'Alert',
            'scope': 'Public',
            'event': 'Typhoon',
            'urgency': 'Immediate',
            'severity': 'Severe',
            'certainty': 'Observed',
            'effective': 1,
            'onset': 1,
            'expires': 2,
            'headline': 'h',
            'senderName': 'CWA',
            'typhoon': null,
            'sections': <Map<String, dynamic>>[],
            'areas': <Map<String, dynamic>>[],
          },
          'not-a-bulletin',
        ],
      });

      expect(payload.updated, 1758000000);
      expect(payload.cyclones, hasLength(1));
      expect(payload.cyclones.single.id, 'a');
    });

    test('an absent cyclones list decodes to zero bulletins', () {
      final payload = WarningPayload.decode(const {'updated': 1});
      expect(payload.cyclones, isEmpty);
    });
  });
}
