import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input_v3.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtures = 'test/features/earthquake/domain/fixtures/share_input_v3';
const _id = '115000-2026-0422-111524';

Uint8List _raw(String id) => File('$_fixtures/raw/$id.json').readAsBytesSync();

Map<String, dynamic> _object(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

CoreEarthquakeReportSnapshot _snapshot(String source, {String id = _id}) =>
    CoreEarthquakeReportSnapshot.decode(
      utf8.encode(source),
      requestedReportId: id,
    );

EarthquakeShareInputV3 _adapt(String source) =>
    adaptEarthquakeShareSnapshotV3(_snapshot(source));

Matcher _sourceError(EarthquakeReportSourceError code, String path) => throwsA(
  isA<EarthquakeReportSourceException>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.path, 'path', path),
);

String _detail({
  String list = '{}',
  String epicenter = '"lat":23.09,"lon":121.4',
  String measurements = '"mag":3.9,"depth":43.5',
  String time = '1776827724000',
}) =>
    '{"id":"$_id","time":$time,$epicenter,"loc":"臺東近海","trem":0,'
    '$measurements,"list":$list}';

// Independent comparison with the renderer's canonical equivalence rules.
Object? _sortedKeys(Object? value) => switch (value) {
  Map<String, dynamic>() => {
    for (final key in value.keys.toList()..sort()) key: _sortedKeys(value[key]),
  },
  List<dynamic>() => value.map(_sortedKeys).toList(),
  _ => value,
};

String _fixtureCanonical(Map<String, dynamic> fixture) {
  final source = fixture['source'] as Map<String, dynamic>;
  final report = fixture['report'] as Map<String, dynamic>;
  for (final key in ['depth_m', 'magnitude', 'published_max_intensity']) {
    report.putIfAbsent(key, () => null);
  }
  (report['location'] as Map<String, dynamic>).putIfAbsent('en-US', () => null);
  for (final (collection, id) in [
    ('areas', 'region_id'),
    ('observations', 'station_id'),
  ]) {
    final rows = (report[collection] as List).cast<Map<String, dynamic>>();
    int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
      final lhs = utf8.encode(a['id'] as String);
      final rhs = utf8.encode(b['id'] as String);
      for (var i = 0; i < lhs.length && i < rhs.length; i++) {
        if (lhs[i] != rhs[i]) return lhs[i] - rhs[i];
      }
      return lhs.length - rhs.length;
    }

    rows.sort(compare);
    for (final row in rows) {
      row.putIfAbsent('intensity', () => null);
      row.putIfAbsent(id, () => null);
      (row['name'] as Map<String, dynamic>).putIfAbsent('en-US', () => null);
    }
  }
  return jsonEncode(
    _sortedKeys({
      'schema_version': fixture['schema_version'],
      'source': {
        for (final key in ['namespace', 'report_id', 'snapshot'])
          key: source[key],
      },
      'report': report,
    }),
  );
}

void main() {
  final cases = (jsonDecode(
    File('$_fixtures/corpus.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();

  for (final entry in cases) {
    final id = entry['report_id'] as String;
    test('archived Core detail $id matches its v3 eligibility and fixture', () {
      final snapshot = CoreEarthquakeReportSnapshot.decode(
        _raw(id),
        requestedReportId: id,
      );
      expect(snapshot.bodySha256, entry['body_sha256']);
      expect(snapshot.body, _raw(id));
      expect(snapshot.report.id, id);
      if (entry['eligible'] != true) {
        expect(
          () => adaptEarthquakeShareSnapshotV3(snapshot),
          _sourceError(EarthquakeReportSourceError.unsupportedProfile, '/time'),
        );
        return;
      }
      final input = adaptEarthquakeShareSnapshotV3(snapshot);
      final expected = _object(
        File('$_fixtures/$id.v3.json').readAsStringSync(),
      );
      expect(utf8.decode(input.canonicalContent), _fixtureCanonical(expected));
      final wire = _object(utf8.decode(input.bytes));
      final report = wire['report'] as Map<String, dynamic>;
      expect((report['areas'] as List), hasLength(entry['areas'] as int));
      expect(
        (report['observations'] as List),
        hasLength(entry['observations'] as int),
      );
      expect(
        (wire['source'] as Map)['scale_evidence'],
        (expected['source'] as Map)['scale_evidence'],
      );
      expect(wire['locale'], 'zh-Hant');
      expect(adaptEarthquakeShareSnapshotV3(snapshot).bytes, input.bytes);
    });
  }

  test('the full returned ID and its Taipei timestamp must match', () {
    expect(
      () => _snapshot(_detail(), id: '115000-2026-0422-111525'),
      _sourceError(EarthquakeReportSourceError.identityMismatch, '/id'),
    );
    expect(
      () => _snapshot(_detail(), id: '115000'),
      _sourceError(EarthquakeReportSourceError.identityMismatch, '/id'),
    );
    expect(
      () => _snapshot(_detail(time: '1776827725000')),
      _sourceError(EarthquakeReportSourceError.identityMismatch, '/time'),
    );
    expect(
      () => _snapshot(_detail(time: '1776827724000.0')),
      _sourceError(EarthquakeReportSourceError.invalidField, '/time'),
    );
    expect(
      _snapshot(_detail(time: '1776827724123')).report.time,
      1776827724123,
    );
  });

  test('body bytes are immutable and same-ID revisions stay distinct', () {
    final body = _raw(_id);
    final original = CoreEarthquakeReportSnapshot.decode(
      body,
      requestedReportId: _id,
    );
    final revised = _snapshot('${utf8.decode(body)}\n');
    body[0] = 0;
    expect(() => original.body[0] = 0, throwsUnsupportedError);
    expect(original.report, revised.report);
    expect(original.bodySha256, isNot(revised.bodySha256));
    expect(
      adaptEarthquakeShareSnapshotV3(original).contentSha256,
      isNot(adaptEarthquakeShareSnapshotV3(revised).contentSha256),
    );
  });

  test('rejects ambiguous JSON before decoding loses the evidence', () {
    for (final (source, path) in [
      (r'{"~x":[{"a/b":1,"a\/b":2}]}', '/~0x/0/a~1b'),
      (r'{"a":1,"\u0061":2}', '/a'),
      (r'{"𐀀":1,"\uD800\uDC00":2}', '/𐀀'),
    ]) {
      expect(
        () => _snapshot(source),
        _sourceError(EarthquakeReportSourceError.duplicateKey, path),
      );
    }
    for (final (source, path) in [
      ('\ufeff${_detail()}', ''),
      (r'{"extra":"\ud800"}', '/extra'),
      ('{"bad":01}', '/bad'),
      ('[]', ''),
    ]) {
      expect(
        () => _snapshot(source),
        _sourceError(EarthquakeReportSourceError.malformedJson, path),
      );
    }
    expect(
      () => CoreEarthquakeReportSnapshot.decode(
        Uint8List.fromList([0x22, 0xff, 0x22]),
        requestedReportId: _id,
      ),
      _sourceError(EarthquakeReportSourceError.malformedJson, ''),
    );
  });

  test('pointers preserve exact decoded keys, parent, and UTF-8 order', () {
    final input = _adapt(
      _detail(
        list: r'''{
      "甲\/乙":{"int":0,"town":{"測~站":{"lat":0,"lon":0,"int":0}}},
      "e\u0301":{"town":{}}, "é":{"town":{}}, "𐀀":{"town":{}}, "Ａ":{"town":{}}
    }''',
      ),
    );
    final report = _object(utf8.decode(input.bytes))['report'] as Map;
    final areas = (report['areas'] as List).cast<Map<String, dynamic>>();
    expect(areas.map((area) => area['id']), [
      '/list/e\u0301',
      '/list/é',
      '/list/甲~1乙',
      '/list/Ａ',
      '/list/𐀀',
    ]);
    final observation = (report['observations'] as List).single as Map;
    expect(observation['id'], '/list/甲~1乙/town/測~0站');
    expect(observation['area_id'], '/list/甲~1乙');
    expect(observation['name'], {'zh-Hant': '測~站', 'en-US': null});
    expect(observation['position'], {'lat_e6': 0, 'lon_e6': 0});
  });

  test('keeps unknown intensity and missing locations separate from zero', () {
    final input = _adapt(
      _detail(
        list: '''{
      "臺東縣":{"int":0,"town":{"無詳情":{},"零":{"lat":0,"lon":0,"int":0}}},
      "花蓮縣":{"town":{"缺經度":{"lat":0,"int":null}}}
    }''',
      ),
    );
    final report = _object(utf8.decode(input.bytes))['report'] as Map;
    final observations = {
      for (final row in report['observations'] as List) row['id']: row,
    };
    expect(observations['/list/臺東縣/town/無詳情']['intensity'], isNull);
    expect(observations['/list/臺東縣/town/無詳情']['position'], isNull);
    expect(observations['/list/臺東縣/town/零']['intensity'], 0);
    expect(observations['/list/花蓮縣/town/缺經度']['position'], isNull);
    expect(report['published_max_intensity'], isNull);
    expect(
      () => _adapt(_detail(epicenter: '"lat":0')),
      _sourceError(EarthquakeReportSourceError.missingEvidence, '/lon'),
    );
    final optional = _adapt(_detail(measurements: '"mag":null'));
    expect(
      (_object(utf8.decode(optional.bytes))['report'] as Map)['magnitude'],
      isNull,
    );
  });

  test('checks exact ranges and half ties before fixed-point conversion', () {
    final input = _adapt(
      _detail(
        epicenter: '"lat":-0.0000005,"lon":123456785e-6',
        measurements: '"mag":-1.235,"depth":0.0005',
      ),
    );
    final report = _object(utf8.decode(input.bytes))['report'] as Map;
    expect(report['epicenter'], {'lat_e6': -1, 'lon_e6': 123456785});
    expect(report['magnitude'], {'centi': -124, 'kind': 'ml'});
    expect(report['depth_m'], 1);
    for (final invalid in [
      '90.000000000000000000001',
      '1e2147483647',
      '"23.09"',
      '-0.0e99',
    ]) {
      expect(
        () => _adapt(_detail(epicenter: '"lat":$invalid,"lon":121')),
        _sourceError(EarthquakeReportSourceError.invalidField, '/lat'),
      );
    }
    expect(
      () => _adapt(_detail(list: '{"甲":{"int":2.0,"town":{}}}')),
      _sourceError(EarthquakeReportSourceError.invalidField, '/list/甲/int'),
    );
    expect(
      () => _adapt(_detail(list: '{"甲":{"int":10,"town":{}}}')),
      _sourceError(EarthquakeReportSourceError.invalidField, '/list/甲/int'),
    );
  });

  test('requires a consistent area maximum for known observations', () {
    for (final (town, path) in [
      ('{"A":{"int":1}}', '/list/甲/int'),
      ('{"A":{"int":3},"B":{"int":null}}', '/list/甲/town/A/int'),
    ]) {
      expect(
        () => _adapt(_detail(list: '{"甲":{"int":2,"town":$town}}')),
        _sourceError(EarthquakeReportSourceError.conflictingIntensity, path),
      );
    }
    for (final town in ['{}', '{"A":{"int":1},"B":{}}']) {
      expect(
        _adapt(_detail(list: '{"甲":{"int":2,"town":$town}}')).bytes,
        isNotEmpty,
      );
    }
  });

  test(
    'dense source accepts 256 areas and 2048 observations, rejects excess',
    () {
      String dense(int areaCount, int extra) => jsonEncode({
        for (var area = 0; area < areaCount; area++)
          '區$area': {
            'int': 1,
            'town': {
              for (
                var station = 0;
                station < 8 + (area == 0 ? extra : 0);
                station++
              )
                '站$station': {'lat': 0, 'lon': 0, 'int': 1},
            },
          },
      });
      final result = _adapt(_detail(list: dense(256, 0)));
      expect(
        (_object(utf8.decode(result.bytes))['report'] as Map)['observations'],
        hasLength(2048),
      );
      expect(
        () => _adapt(_detail(list: dense(257, 0))),
        _sourceError(EarthquakeReportSourceError.inputLimit, '/list'),
      );
      expect(
        () => _adapt(_detail(list: dense(256, 1))),
        throwsA(
          isA<EarthquakeReportSourceException>().having(
            (error) => error.code,
            'code',
            EarthquakeReportSourceError.inputLimit,
          ),
        ),
      );
    },
  );

  test('modern eligibility begins at midnight Taipei on 2020-01-01', () {
    final modern = _detail(time: '1577808000000')
        .replaceFirst(_id, '109000-2020-0101-000000');
    expect(
      adaptEarthquakeShareSnapshotV3(
        _snapshot(modern, id: '109000-2020-0101-000000'),
      ).bytes,
      isNotEmpty,
    );
    final historical = _detail(time: '1577807999999')
        .replaceFirst(_id, '108000-2019-1231-235959');
    expect(
      () => adaptEarthquakeShareSnapshotV3(
        _snapshot(historical, id: '108000-2019-1231-235959'),
      ),
      _sourceError(EarthquakeReportSourceError.unsupportedProfile, '/time'),
    );
  });

  test(
    'locale changes the wire envelope but leaves canonical content unchanged',
    () {
      final snapshot = _snapshot(_detail(epicenter: '"lat":90,"lon":-180'));
      final zh = adaptEarthquakeShareSnapshotV3(snapshot);
      final en = adaptEarthquakeShareSnapshotV3(
        snapshot,
        locale: EarthquakeShareLocale.enUs,
      );
      expect(zh.canonicalContent, en.canonicalContent);
      expect(zh.contentSha256, en.contentSha256);
      expect(utf8.decode(zh.bytes), isNot(utf8.decode(en.bytes)));
      expect((_object(utf8.decode(en.bytes))['report'] as Map)['epicenter'], {
        'lat_e6': 90000000,
        'lon_e6': -180000000,
      });
      expect(() => en.bytes[0] = 0, throwsUnsupportedError);
      expect(() => en.canonicalContent[0] = 0, throwsUnsupportedError);
    },
  );

  test('bounds raw bytes, nesting, node count and scanner pointer size', () {
    for (final source in [
      ' ' * (2 * 1024 * 1024 + 1),
      '{"extra":${'[' * 40}0${']' * 40}}',
      '{"extra":[${'null,' * 49999}null]}',
      '{"${'甲' * 342}":null}',
    ]) {
      expect(
        () => _snapshot(source),
        throwsA(
          isA<EarthquakeReportSourceException>().having(
            (e) => e.code,
            'code',
            EarthquakeReportSourceError.inputLimit,
          ),
        ),
      );
    }
  });

  test('uses UTF-8 byte limits for escaped pointers and localized text', () {
    final prefix = '甲' * 168;
    // 168 CJK scalars and one escaped "~" plus the /list/ prefix = 512 bytes.
    expect(_adapt(_detail(list: '{"$prefix~":{"town":{}}}')).bytes, isNotEmpty);
    expect(
      () => _adapt(_detail(list: '{"$prefix~a":{"town":{}}}')),
      _sourceError(EarthquakeReportSourceError.inputLimit, '/list/$prefix~0a'),
    );

    final text = '${'甲' * 170}ab';
    expect(_adapt(_detail().replaceFirst('臺東近海', text)).bytes, isNotEmpty);
    expect(
      () => _adapt(_detail().replaceFirst('臺東近海', '${text}c')),
      _sourceError(EarthquakeReportSourceError.invalidField, '/loc'),
    );
  });

  test('rejects an oversized envelope even within source and row limits', () {
    final town = <String, Object?>{
      for (var i = 0; i < 2048; i++) '${'甲' * 100}$i': {'int': 0},
    };
    final raw = _detail(
      list: jsonEncode({
        '甲': {'int': 0, 'town': town},
      }),
    );
    expect(utf8.encode(raw).length, lessThan(2 * 1024 * 1024));
    expect(
      () => _adapt(raw),
      _sourceError(EarthquakeReportSourceError.inputLimit, ''),
    );
  });
}
