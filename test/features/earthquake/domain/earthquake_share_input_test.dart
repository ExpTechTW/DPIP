import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtureDir = 'test/features/earthquake/domain/fixtures/share_input';
const _requestId = '115000-2026-0422-111524';
const _decimals = {
  '/lat': '23.09',
  '/lon': '121.4',
  '/mag': '3.9',
  '/depth': '43.5',
  '/list/臺東縣/town/成功/lat': '23.1',
  '/list/臺東縣/town/成功/lon': '121.37',
  '/list/臺東縣/town/長濱/lat': '23.32',
  '/list/臺東縣/town/長濱/lon': '121.45',
  '/list/臺東縣/town/池上/lat': '23.1',
  '/list/臺東縣/town/池上/lon': '121.22',
  '/list/臺東縣/town/東河/lat': '22.97',
  '/list/臺東縣/town/東河/lon': '121.3',
  '/list/花蓮縣/town/紅葉/lat': '23.5',
  '/list/花蓮縣/town/紅葉/lon': '121.33',
};
const _counties = {'臺東縣': '10014', '花蓮縣': '10015'};
const _stations = {
  ('臺東縣', '成功'): 'CHK',
  ('臺東縣', '長濱'): 'ECB',
  ('臺東縣', '池上'): 'ECS',
  ('臺東縣', '東河'): 'EDH',
  ('花蓮縣', '紅葉'): 'EHY',
};

Map<String, dynamic> _readSource(String name) =>
    jsonDecode(File('$_fixtureDir/exptech-$name.json').readAsStringSync())
        as Map<String, dynamic>;

ExpTechReportEvidence _evidence(
  EarthquakeReport snapshot, {
  String requestedId = _requestId,
  Map<String, String> decimals = _decimals,
  Map<String, String> counties = _counties,
  Map<(String, String), String> stations = _stations,
  ReportIntensityScale? scale = ReportIntensityScale.cwa2020,
  bool magnitudeIsMl = true,
}) => ExpTechReportEvidence(
  snapshot: snapshot,
  requestedReportId: requestedId,
  sourceDecimals: decimals,
  countyCodes: counties,
  stationCodes: stations,
  scale: scale,
  magnitudeIsMl: magnitudeIsMl,
);

EarthquakeShareInputV2 _convert(EarthquakeReport report) =>
    adaptEarthquakeShareInput(report, evidence: _evidence(report))
        as EarthquakeShareInputV2;

Map<String, dynamic> _decode(EarthquakeShareInputV2 input) =>
    jsonDecode(utf8.decode(input.bytes)) as Map<String, dynamic>;

void _expectFailure(
  EarthquakeShareInput result,
  EarthquakeShareInputError code,
  String path,
) {
  expect(
    result,
    isA<UnsupportedEarthquakeShareInput>()
        .having((failure) => failure.code, 'code', code)
        .having((failure) => failure.path, 'source JSON Pointer', path)
        .having((failure) => failure.detail, 'detail', isNotEmpty),
  );
}

void main() {
  final modern = EarthquakeReport.fromJson(_readSource('modern'));

  test(
    'full modern detail matches the independent Rust-validated envelope',
    () {
      final result = _convert(modern);
      expect(
        result.bytes,
        File('$_fixtureDir/exptech-modern.v2.json').readAsBytesSync(),
      );
      final envelope = _decode(result);
      final source = envelope['source'] as Map<String, dynamic>;
      final report = envelope['report'] as Map<String, dynamic>;
      expect(source['report_id'], _requestId);
      expect(source['revision'], isNull);
      expect(source['event_id'], isNull);
      expect(source['publication'], isNull);
      expect(
        report['origin_time_unix_ms'],
        DateTime.parse('2026-04-22T11:15:24+08:00').millisecondsSinceEpoch,
      );
      expect(report['epicenter'], {'lat_e6': 23090000, 'lon_e6': 121400000});
      expect(report['location'], {'en-US': null, 'zh-Hant': modern.location});
      expect(report['magnitude'], {'centi': 390, 'kind': 'ml'});
      expect(report['depth_m'], 43500);
      expect(report['published_max_intensity'], isNull);
      expect(modern.maxIntensity, 2);
      final canonicalContent = utf8.encode(
        jsonEncode({'report': report, 'schema_version': 2}),
      );
      expect(
        sha256.convert(canonicalContent).toString(),
        '6eac3077aae8b992e8c752c2c71a137a5601ad94e52c8d8952e7261b179c9e95',
      );
    },
  );

  test(
    'retains the regional maximum independently of station and publication',
    () {
      final report = modern.copyWith(
        list: {
          '臺東縣': modern.list['臺東縣']!.copyWith(intensity: 3),
          '花蓮縣': modern.list['花蓮縣']!,
        },
      );
      final input = _decode(_convert(report))['report'] as Map<String, dynamic>;
      expect(input['published_max_intensity'], isNull);
      final areas = (input['areas'] as List).cast<Map<String, dynamic>>();
      expect(areas.first['intensity'], 3);
      expect(report.maxIntensity, 2);
    },
  );

  test(
    'keeps explicit observed zero and leaves an empty observation set empty',
    () {
      final zero = modern.copyWith(
        list: {
          '花蓮縣': AreaIntensity(
            intensity: 0,
            town: {
              '紅葉': modern.list['花蓮縣']!.town['紅葉']!.copyWith(intensity: 0),
            },
          ),
        },
      );
      final zeroReport =
          _decode(_convert(zero))['report'] as Map<String, dynamic>;
      final area = (zeroReport['areas'] as List).single as Map<String, dynamic>;
      final obs =
          (zeroReport['observations'] as List).single as Map<String, dynamic>;
      expect(area['intensity'], 0);
      expect(obs['intensity'], 0);
      expect(zeroReport['published_max_intensity'], isNull);

      final empty = modern.copyWith(list: {});
      expect(empty.maxIntensity, 0);
      final emptyReport =
          _decode(_convert(empty))['report'] as Map<String, dynamic>;
      expect(emptyReport['areas'], isEmpty);
      expect(emptyReport['observations'], isEmpty);
      expect(emptyReport['published_max_intensity'], isNull);
    },
  );

  test(
    'orders by evidence IDs and emits identical immutable bytes repeatedly',
    () {
      final reordered = modern.copyWith(
        list: {
          for (final entry in modern.list.entries.toList().reversed)
            entry.key: entry.value.copyWith(
              town: Map.fromEntries(entry.value.town.entries.toList().reversed),
            ),
        },
      );
      final first = _convert(modern);
      final second = adaptEarthquakeShareInput(
        reordered,
        evidence: _evidence(modern),
      ) as EarthquakeShareInputV2;
      expect(second.bytes, first.bytes);
      expect(_convert(modern).bytes, first.bytes);
      expect(() => first.bytes[0] = 0, throwsUnsupportedError);

      final report = _decode(first)['report'] as Map<String, dynamic>;
      final areas = (report['areas'] as List).cast<Map<String, dynamic>>();
      final observations = (report['observations'] as List)
          .cast<Map<String, dynamic>>();
      expect(areas.map((area) => area['id']), ['10014', '10015']);
      expect(observations.map((obs) => obs['id']), [
        'cwa:CHK',
        'cwa:ECB',
        'cwa:ECS',
        'cwa:EDH',
        'cwa:EHY',
      ]);
    },
  );

  test('missing coordinate evidence identifies the specific source axis', () {
    final decimals = Map.of(_decimals)..remove('/list/花蓮縣/town/紅葉/lon');
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(modern, decimals: decimals),
      ),
      EarthquakeShareInputError.missingCoordinates,
      '/list/花蓮縣/town/紅葉/lon',
    );

    // Actual omissions fail the existing non-nullable model decode upstream.
    final raw = _readSource('modern')..remove('lat');
    expect(() => EarthquakeReport.fromJson(raw), throwsA(isA<TypeError>()));
  });

  test('validates a supplied axis even when its partner is missing', () {
    final decimals = Map.of(_decimals)
      ..remove('/lat')
      ..['/lon'] = 'invalid';
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(modern, decimals: decimals),
      ),
      EarthquakeShareInputError.malformedSource,
      '/lon',
    );
  });

  test('rejects missing and duplicate station identities', () {
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(modern, stations: {}),
      ),
      EarthquakeShareInputError.missingStationIdentity,
      '/list/臺東縣/town/成功',
    );
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(
          modern,
          stations: {..._stations, ('花蓮縣', '紅葉'): 'CHK'},
        ),
      ),
      EarthquakeShareInputError.duplicateIdentity,
      '/list/花蓮縣/town/紅葉',
    );
  });

  test('rejects unknown magnitude kind and missing exact measurement', () {
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(modern, magnitudeIsMl: false),
      ),
      EarthquakeShareInputError.unknownMagnitudeType,
      '/mag',
    );
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(
          modern,
          decimals: Map.of(_decimals)..remove('/mag'),
        ),
      ),
      EarthquakeShareInputError.missingSourceDecimal,
      '/mag',
    );
  });

  test('rejects an unproven or legacy scale and needs historical identity evidence', () {
    final historical = EarthquakeReport.fromJson(_readSource('historical'));
    expect(historical.list['臺南市']!.intensity, 9);
    for (final scale in [null, ReportIntensityScale.legacy]) {
      _expectFailure(
        adaptEarthquakeShareInput(
          historical,
          evidence: _evidence(
            historical,
            requestedId: historical.id,
            scale: scale,
          ),
        ),
        EarthquakeShareInputError.unsupportedIntensityScale,
        '/list',
      );
    }
    _expectFailure(
      adaptEarthquakeShareInput(
        historical,
        evidence: _evidence(
          historical,
          requestedId: historical.id,
          decimals: {
            '/lat': '22.92',
            '/lon': '120.54',
            '/mag': '6.6',
            '/depth': '14.6',
          },
          counties: {},
        ),
      ),
      EarthquakeShareInputError.missingAreaIdentity,
      '/list/南投縣',
    );
  });

  test('requires a matching full request ID and snapshot', () {
    _expectFailure(
      adaptEarthquakeShareInput(modern),
      EarthquakeShareInputError.missingSourceIdentity,
      '/id',
    );
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(modern, requestedId: modern.serial),
      ),
      EarthquakeShareInputError.missingSourceIdentity,
      '/id',
    );
    _expectFailure(
      adaptEarthquakeShareInput(
        modern.copyWith(id: modern.serial),
        evidence: _evidence(modern, requestedId: modern.serial),
      ),
      EarthquakeShareInputError.missingSourceIdentity,
      '/id',
    );
    _expectFailure(
      adaptEarthquakeShareInput(
        modern.copyWith(time: modern.time + 1),
        evidence: _evidence(modern),
      ),
      EarthquakeShareInputError.snapshotMismatch,
      '',
    );
  });

  test('snapshot evidence owns the nested model maps and source lookups', () {
    final area = modern.list['臺東縣']!;
    final town = Map.of(area.town);
    final list = {...modern.list, '臺東縣': area.copyWith(town: town)};
    final model = modern.copyWith(list: list);
    final decimals = Map.of(_decimals);
    final counties = Map.of(_counties);
    final stations = Map.of(_stations);
    final evidence = _evidence(
      model,
      decimals: decimals,
      counties: counties,
      stations: stations,
    );
    decimals.clear();
    counties.clear();
    stations.clear();
    final input = adaptEarthquakeShareInput(
      model,
      evidence: evidence,
    ) as EarthquakeShareInputV2;
    expect(input.bytes, _convert(modern).bytes);

    town.clear();
    _expectFailure(
      adaptEarthquakeShareInput(model, evidence: evidence),
      EarthquakeShareInputError.snapshotMismatch,
      '',
    );
    town.addAll(area.town);
    list.clear();
    _expectFailure(
      adaptEarthquakeShareInput(model, evidence: evidence),
      EarthquakeShareInputError.snapshotMismatch,
      '',
    );
  });

  test('exact decimal conversion rounds both signs away from zero at ties', () {
    final report = modern.copyWith(
      latitude: 23.0900005,
      longitude: -121.4000005,
    );
    final bytes = adaptEarthquakeShareInput(
      report,
      evidence: _evidence(
        report,
        decimals: {..._decimals, '/lat': '23.0900005', '/lon': '-121.4000005'},
      ),
    ) as EarthquakeShareInputV2;
    final content = _decode(bytes)['report'] as Map<String, dynamic>;
    expect(content['epicenter'], {'lat_e6': 23090001, 'lon_e6': -121400001});
  });

  test('rejects malformed decimal source values before rounding', () {
    final boundary = modern.copyWith(latitude: 90);
    _expectFailure(
      adaptEarthquakeShareInput(
        boundary,
        evidence: _evidence(
          boundary,
          decimals: {..._decimals, '/lat': '90.0000000000000001'},
        ),
      ),
      EarthquakeShareInputError.malformedSource,
      '/lat',
    );
    final nonFinite = modern.copyWith(latitude: double.infinity);
    _expectFailure(
      adaptEarthquakeShareInput(nonFinite, evidence: _evidence(nonFinite)),
      EarthquakeShareInputError.malformedSource,
      '/lat',
    );
    final negativeZero = modern.copyWith(latitude: -0.0);
    _expectFailure(
      adaptEarthquakeShareInput(
        negativeZero,
        evidence: _evidence(
          negativeZero,
          decimals: {..._decimals, '/lat': '-0.00'},
        ),
      ),
      EarthquakeShareInputError.malformedSource,
      '/lat',
    );
  });

  test('rejects an observation that exceeds its source regional maximum', () {
    final report = modern.copyWith(
      list: {...modern.list, '臺東縣': modern.list['臺東縣']!.copyWith(intensity: 0)},
    );
    _expectFailure(
      adaptEarthquakeShareInput(report, evidence: _evidence(report)),
      EarthquakeShareInputError.conflictingIntensity,
      '/list/臺東縣/town/成功/int',
    );
  });

  test('rejects out-of-range timestamps and invalid source labels', () {
    for (final time in [-62135625600001, 253402272000000]) {
      final report = modern.copyWith(time: time);
      _expectFailure(
        adaptEarthquakeShareInput(report, evidence: _evidence(report)),
        EarthquakeShareInputError.malformedSource,
        '/time',
      );
    }
    for (final location in ['   ', '臺東\n近海', '震' * 171]) {
      final report = modern.copyWith(location: location);
      _expectFailure(
        adaptEarthquakeShareInput(report, evidence: _evidence(report)),
        EarthquakeShareInputError.malformedSource,
        '/loc',
      );
    }
  });

  test('rejects duplicated county identity at the second source area', () {
    _expectFailure(
      adaptEarthquakeShareInput(
        modern,
        evidence: _evidence(modern, counties: {..._counties, '花蓮縣': '10014'}),
      ),
      EarthquakeShareInputError.duplicateIdentity,
      '/list/花蓮縣',
    );
  });

  test('rejects invalid intensity and escapes source JSON Pointer tokens', () {
    const county = '縣/~';
    const station = '站~/';
    final reading = modern.list['臺東縣']!.town['成功']!;
    final report = modern.copyWith(
      list: {
        county: AreaIntensity(
          intensity: 9,
          town: {station: reading.copyWith(intensity: 10)},
        ),
      },
    );
    _expectFailure(
      adaptEarthquakeShareInput(
        report,
        evidence: _evidence(
          report,
          counties: {county: '10014'},
          stations: {(county, station): 'CHK'},
        ),
      ),
      EarthquakeShareInputError.malformedSource,
      '/list/縣~1~0/town/站~0~1/int',
    );
  });

  test('rejects more than 256 source areas', () {
    final report = modern.copyWith(
      list: {for (var i = 0; i < 257; i++) 'Area $i': modern.list['臺東縣']!},
    );
    _expectFailure(
      adaptEarthquakeShareInput(report, evidence: _evidence(report)),
      EarthquakeShareInputError.inputLimit,
      '/list',
    );
  });

  test(
    'enforces observation count and serialized UTF-8 size independently',
    () {
      final area = modern.list['臺東縣']!;
      final station = area.town['成功']!;

      void expectLimit(int count, String suffix, String errorPath) {
        final names = [
          for (var i = 0; i < count; i++)
            '${i.toString().padLeft(4, '0')}$suffix',
        ];
        final report = modern.copyWith(
          list: {
            '臺東縣': area.copyWith(
              town: {for (final name in names) name: station},
            ),
          },
        );
        _expectFailure(
          adaptEarthquakeShareInput(
            report,
            evidence: _evidence(
              report,
              decimals: {
                ..._decimals,
                for (final name in names) ...{
                  '/list/臺東縣/town/$name/lat': '23.1',
                  '/list/臺東縣/town/$name/lon': '121.37',
                },
              },
              stations: {
                for (var i = 0; i < count; i++) ('臺東縣', names[i]): 'S$i',
              },
            ),
          ),
          EarthquakeShareInputError.inputLimit,
          errorPath,
        );
      }

      expectLimit(2049, '', '/list/臺東縣/town/2048');
      expectLimit(1800, '震' * 169, '');
    },
  );
}
