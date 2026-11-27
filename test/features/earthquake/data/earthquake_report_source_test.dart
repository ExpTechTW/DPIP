import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/report_repository_impl.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input_v3.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/storage/memory_db.dart';

const _modernId = '115000-2026-0422-111524';
const _historicalId = '105006-2016-0206-035726';
const _primary = 'api.core-tnn1.exptech.dev';
const _backup = 'api.core-tyo1.exptech.dev';
const _reportUrl = 'https://$_primary/api/v2/eq/report/$_modernId';
const _modernHash =
    'e6761038a7eea6b8afa58c936693f35d663bd5ca1ecdb2ad4613b72e2d46e4c1';

Uint8List _fixture(String name) => File(
  'test/features/earthquake/domain/fixtures/share_input/exptech-$name.json',
).readAsBytesSync();

class _Origin implements HttpClientAdapter {
  _Origin(this.respond);

  final Future<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

EarthquakeApi _api(
  _Origin origin, {
  EtagCacheStore? cache,
  EndpointHealthMonitor? health,
}) {
  final dio = createDio(etagCache: cache)..httpClientAdapter = origin;
  addTearDown(dio.close);
  return EarthquakeApi(
    ApiClient(dio, RegionSelection(SettingsStore.inMemory({})), health),
  );
}

ReportRepositoryImpl _repository(_Origin origin, {EtagCacheStore? cache}) =>
    ReportRepositoryImpl(_api(origin, cache: cache));

class _RecordingCache extends EtagCacheStore {
  _RecordingCache(super.db);

  final writes = <String>[];

  @override
  Future<void> writeBytes(
    String url, {
    required String etag,
    required Uint8List bytes,
    String? contentType,
    int size = 0,
  }) {
    writes.add(url);
    return super.writeBytes(
      url,
      etag: etag,
      bytes: bytes,
      contentType: contentType,
      size: size,
    );
  }
}

ResponseBody _response(Uint8List bytes, {String? etag}) =>
    ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (etag != null) 'etag': [etag],
      },
    );

class _LoopbackApiClient extends ApiClient {
  _LoopbackApiClient(Dio dio, this.url)
    : super(dio, RegionSelection(SettingsStore.inMemory({})));

  final String url;

  @override
  List<String> hostsFor(ApiTier tier) => [url];
}

void main() {
  late Uint8List modern;
  late String modernText;

  setUp(() {
    modern = _fixture('modern');
    modernText = utf8.decode(modern);
  });

  test(
    'delivers the verified modern model and evidence from one response',
    () async {
      final origin = _Origin((_) async => _response(modern));
      final result = await _repository(origin).getSnapshot(_modernId);
      final snapshot = result.valueOrNull!;
      final report = snapshot.report;

      expect(origin.requests.single.uri.path, '/api/v2/eq/report/$_modernId');
      expect(origin.requests.single.responseType, ResponseType.bytes);
      expect(report.id, _modernId);
      expect(snapshot.requestedReportId, _modernId);
      expect(snapshot.hasMatchingReportId, isTrue);
      expect(snapshot.bodySha256, _modernHash);
      expect(snapshot.etag, isNull);
      expect(report.location, contains('臺東縣近海'));
      expect(report.magnitude, 3.9);
      expect(report.depth, 43.5);
      expect(report.list.keys, unorderedEquals(['臺東縣', '花蓮縣']));
      expect(report.list['臺東縣']!.intensity, 2);
      expect(report.list['花蓮縣']!.intensity, 1);
      expect(
        report.list.values.expand((area) => area.town.keys),
        unorderedEquals(['成功', '長濱', '池上', '東河', '紅葉']),
      );
      expect(snapshot.sourceNumbers['/list/臺東縣/town/成功/lat'], '23.1');
      expect(snapshot.sourceNumbers['/list/花蓮縣/town/紅葉/lon'], '121.33');
    },
  );

  test('binds numeric spelling and identity to the exact snapshot', () {
    final changed = utf8.encode(
      modernText.replaceFirst('"mag":3.9', '"mag":3.900e0'),
    );
    final original = EarthquakeReportSnapshot.decode(
      modern,
      requestedReportId: _modernId,
    );
    final revised = EarthquakeReportSnapshot.decode(
      changed,
      requestedReportId: _modernId,
    );
    expect(revised.report, original.report);
    expect(revised.bodySha256, isNot(original.bodySha256));
    expect(revised.sourceNumbers['/mag'], '3.900e0');
    expect(() => revised.sourceNumbers['/mag'] = '3.9', throwsUnsupportedError);

    for (final request in ['', '115000', _historicalId]) {
      final unverified = EarthquakeReportSnapshot.decode(
        modern,
        requestedReportId: request,
      );
      expect(unverified.report.id, _modernId);
      expect(unverified.hasMatchingReportId, isFalse);
    }
  });

  test(
    'v3 binds the same detail instance and original bytes from one fetch',
    () async {
      final origin = _Origin((_) async => _response(modern, etag: '"exact"'));
      final result = await _repository(origin).getDetailWithSource(_modernId);
      final detail = result.valueOrNull!;
      final snapshot = detail.source.valueOrNull!;
      final input = adaptEarthquakeShareSnapshotV3(snapshot);

      expect(snapshot.report, same(detail.report));
      expect(input.snapshot, same(snapshot));
      expect(snapshot.body, modern);
      expect(snapshot.bodySha256, _modernHash);
      expect(snapshot.endpoint, Uri.parse(_reportUrl));
      expect(snapshot.confirmedAt, isNotNull);
      expect(snapshot.etag, '"exact"');
      expect(snapshot.revalidated, isFalse);
      expect(origin.requests, hasLength(1));
      expect(origin.requests.single.followRedirects, isFalse);
    },
  );

  test(
    'gzip content decoding and 304 reuse preserve the same source bytes',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final db = openMemoryDb();
      addTearDown(db.close);
      await EtagCacheStore.createSchema(db);
      final cache = EtagCacheStore(db);
      final base = 'http://127.0.0.1:${server.port}';
      final url = '$base/api/v2/eq/report/$_modernId';
      final zipped = gzip.encode(modern);
      final requests = <String?>[];
      const etag = '"gzipped"';
      server.listen((request) async {
        final tag = request.headers.value('if-none-match');
        requests.add(tag);
        final response = request.response;
        response.headers.set('etag', etag);
        if (tag == etag) {
          response.statusCode = 304;
        } else {
          response.headers.contentType = ContentType.json;
          response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
          response.add(zipped);
        }
        await response.close();
      });
      final dio = createDio(etagCache: cache)
        ..httpClientAdapter = IOHttpClientAdapter();
      addTearDown(dio.close);
      final repository = ReportRepositoryImpl(
        EarthquakeApi(_LoopbackApiClient(dio, base)),
      );
      final fresh = (await repository.getSourceSnapshot(_modernId))
          .valueOrNull!;
      for (
        var attempt = 0;
        attempt < 40 && await cache.readEtag(url, binary: true) == null;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      final reused = (await repository.getSourceSnapshot(_modernId))
          .valueOrNull!;
      expect(requests, [null, etag]);
      expect(fresh.body, modern);
      expect(reused.body, modern);
      expect(reused.bodySha256, _modernHash);
      expect(reused.endpoint, Uri.parse(url));
      expect(reused.revalidated, isTrue);
      expect(
        adaptEarthquakeShareSnapshotV3(reused).bytes,
        adaptEarthquakeShareSnapshotV3(fresh).bytes,
      );
    },
  );

  test('retains the documented Core v2 encoding on historical detail', () {
    final snapshot = EarthquakeReportSnapshot.decode(
      _fixture('historical'),
      requestedReportId: _historicalId,
    );
    expect(snapshot.hasMatchingReportId, isTrue);
    expect(snapshot.sourceNumbers['/list/臺南市/int'], '9');
    expect(snapshot.sourceNumbers['/list/臺南市/town/新化/int'], '9');
  });

  test('production share source emits v2 only for the verified body', () async {
    var body = modern;
    final repository = _repository(_Origin((_) async => _response(body)));
    final report = (await repository.get(_modernId)).valueOrNull!;
    final input = (await repository.getShareInput(report)).valueOrNull!;
    expect((input as EarthquakeShareInputV2).bytes, _fixture('modern.v2'));

    // The same display model from a revised source needs new evidence.
    body = utf8.encode(modernText.replaceFirst('"mag":3.9', '"mag":3.90'));
    final revised = (await repository.getShareInput(report)).valueOrNull;
    expect(
      revised,
      isA<UnsupportedEarthquakeShareInput>().having(
        (value) => value.code,
        'code',
        EarthquakeShareInputError.snapshotMismatch,
      ),
    );

    body = _fixture('historical');
    final historical = (await repository.get(_historicalId)).valueOrNull!;
    expect(
      (await repository.getShareInput(historical)).valueOrNull,
      isA<UnsupportedEarthquakeShareInput>(),
    );
  });

  test(
    'returns a typed duplicate-key diagnostic through the repository',
    () async {
      final body = utf8.encode(
        modernText.replaceFirst('"lat":23.1', r'"lat":23.1,"\u006cat":23.2'),
      );
      final origin = _Origin((_) async => _response(body));
      final repository = _repository(origin);
      final detail = await repository.get(_modernId);
      expect(detail.valueOrNull!.id, _modernId);
      expect(origin.requests, hasLength(1));
      final result = await repository.getSnapshot(_modernId);
      final cause =
          (result.failureOrNull as DecodeFailure).cause!
              as EarthquakeReportSourceException;
      expect(cause.code, EarthquakeReportSourceError.duplicateKey);
      expect(cause.path, '/list/臺東縣/town/成功/lat');
      expect(origin.requests, hasLength(2));
    },
  );

  group('invalid report response failover', () {
    late _RecordingCache cache;
    late EndpointHealthMonitor health;

    setUp(() async {
      final db = openMemoryDb();
      addTearDown(db.close);
      await EtagCacheStore.createSchema(db);
      cache = _RecordingCache(db);
      health = EndpointHealthMonitor();
      addTearDown(health.dispose);
    });

    for (final (label, invalid, seedValid) in [
      ('malformed JSON', utf8.encode('{"report":'), false),
      ('invalid UTF-8', Uint8List.fromList([0x22, 0xff, 0x22]), true),
    ]) {
      test('a 200 with $label and ETag fails over before caching', () async {
        if (seedValid) {
          await cache.writeBytes(_reportUrl, etag: '"valid"', bytes: modern);
          cache.writes.clear();
        }
        final origin = _Origin((request) async {
          if (request.uri.host == _primary) {
            return _response(invalid, etag: '"invalid"');
          }
          return _response(modern);
        });
        final repository = ReportRepositoryImpl(
          _api(origin, cache: cache, health: health),
        );
        final result = await repository.get(_modernId);

        expect(origin.requests.map((r) => r.uri.host), [_primary, _backup]);
        // Dio can turn a failure inside the adapter into a regional retry.
        expect(
          origin.requests.first.headers['if-none-match'],
          seedValid ? '"valid"' : null,
        );
        expect(result.valueOrNull!.id, _modernId);
        final primary = health.of(
          EndpointService.report,
          ApiTier.coreApi,
          _primary,
        );
        expect(primary!.lastSuccess, isNull);
        expect(primary.consecutiveFailures, 1);
        expect(
          health.of(EndpointService.report, ApiTier.coreApi, _backup)!.state,
          EndpointState.healthy,
        );
        expect(cache.writes, isEmpty);
        final cached = await cache.readBytes(_reportUrl);
        expect(cached?.etag, seedValid ? '"valid"' : null);
        expect(cached?.bytes, seedValid ? modern : null);
      });
    }

    for (final (label, code, canBuildSnapshot) in [
      ('duplicate', EarthquakeReportSourceError.duplicateKey, false),
      ('decimal', EarthquakeReportSourceError.invalidField, true),
    ]) {
      test('display can use a fresh 200 rejected for v3 with $code', () async {
        final badBody = switch (label) {
          'duplicate' => modernText.replaceFirst(
            '"lat":23.1',
            r'"lat":23.1,"\u006cat":23.1',
          ),
          _ => modernText.replaceFirst(
            '"mag":3.9',
            '"mag":10.0000000000000000001',
          ),
        };
        final origin = _Origin(
          (_) async => _response(utf8.encode(badBody), etag: '"bad"'),
        );
        final repository = _repository(origin, cache: cache);
        final detail = (await repository.getDetailWithSource(_modernId))
            .valueOrNull!;
        expect(detail.report.location, contains('臺東縣近海'));
        expect(origin.requests, hasLength(1));
        expect(cache.writes, isEmpty);
        expect(await cache.readBytes(_reportUrl), isNull);
        if (canBuildSnapshot) {
          expect(
            () => adaptEarthquakeShareSnapshotV3(detail.source.valueOrNull!),
            throwsA(
              isA<EarthquakeReportSourceException>().having(
                (e) => e.code,
                'code',
                code,
              ),
            ),
          );
        } else {
          final error =
              (detail.source.failureOrNull as DecodeFailure).cause
                  as EarthquakeReportSourceException;
          expect(error.code, code);
        }
      });
    }

    test(
      'a 304 never swaps the pinned bytes for another row with the same ETag',
      () async {
        const tag = '"identical-validator"';
        await cache.writeBytes(_reportUrl, etag: tag, bytes: modern);
        final replacement = utf8.encode('$modernText\n');
        final origin = _Origin((request) async {
          await cache.writeBytes(_reportUrl, etag: tag, bytes: replacement);
          return ResponseBody.fromString('', 304);
        });
        final snapshot = (await _repository(
          origin,
          cache: cache,
        ).getSourceSnapshot(_modernId)).valueOrNull!;
        expect(origin.requests.single.headers['if-none-match'], tag);
        expect(snapshot.body, modern);
        expect(snapshot.bodySha256, _modernHash);
        expect((await cache.readBytes(_reportUrl))!.bytes, replacement);
      },
    );

    test('a 304 with a different response ETag fails over', () async {
      await cache.writeBytes(_reportUrl, etag: '"original"', bytes: modern);
      final origin = _Origin((request) async {
        if (request.uri.host == _primary) {
          return ResponseBody.fromString(
            '',
            304,
            headers: {
              'etag': ['"other"'],
            },
          );
        }
        return _response(modern);
      });
      final snapshot = (await _repository(
        origin,
        cache: cache,
      ).getSourceSnapshot(_modernId)).valueOrNull!;
      expect(origin.requests.first.headers['if-none-match'], '"original"');
      expect(origin.requests, hasLength(2));
      expect(snapshot.endpoint!.host, _backup);
      expect(snapshot.revalidated, isFalse);
    });

    test(
      'a different report ID cannot become the current detail or enter cache',
      () async {
        final wrong = utf8.encode(
          modernText.replaceFirst(_modernId, '115999-2026-0422-111524'),
        );
        final repository = _repository(
          _Origin((_) async => _response(wrong, etag: '"wrong"')),
          cache: cache,
        );
        expect(
          (await repository.get(_modernId)).failureOrNull,
          isA<DecodeFailure>(),
        );
        final source = await repository.getSourceSnapshot(_modernId);
        expect(
          (source.failureOrNull as DecodeFailure).cause,
          isA<EarthquakeReportSourceException>().having(
            (e) => e.code,
            'code',
            EarthquakeReportSourceError.identityMismatch,
          ),
        );
        expect(cache.writes, isEmpty);
        expect(await cache.readBytes(_reportUrl), isNull);
      },
    );

    test(
      'a wildcard ETag cannot condition a Core request or seed the cache',
      () async {
        await cache.writeBytes(_reportUrl, etag: '*', bytes: modern);
        cache.writes.clear();
        final origin = _Origin((_) async => _response(modern, etag: '*'));
        final source = await _repository(
          origin,
          cache: cache,
        ).getSourceSnapshot(_modernId);
        expect(source.valueOrNull!.etag, isNull);
        expect(origin.requests.single.headers['if-none-match'], isNull);
        expect(cache.writes, isEmpty);
      },
    );

    test('a 304 cannot restore a cached malformed body', () async {
      await cache.writeBytes(
        _reportUrl,
        etag: '"invalid"',
        bytes: utf8.encode('{"report":'),
      );
      final origin = _Origin((request) async {
        if (request.uri.host == _primary) {
          return ResponseBody.fromString('', 304);
        }
        return _response(modern, etag: '"backup"');
      });
      final result = await _repository(
        origin,
        cache: cache,
      ).getSnapshot(_modernId);

      expect(origin.requests.map((r) => r.uri.host), [_primary, _backup]);
      expect(origin.requests.first.headers['if-none-match'], isNull);
      expect(origin.requests.last.headers['if-none-match'], isNull);
      expect(result.valueOrNull!.etag, '"backup"');
      expect(result.valueOrNull!.bodySha256, _modernHash);
    });
  });

  test(
    'when all regions return malformed JSON the network failure is typed',
    () async {
      final origin = _Origin((_) async => _response(utf8.encode('{"report":')));
      final result = await _repository(origin).get(_modernId);

      expect(origin.requests.map((r) => r.uri.host), [_primary, _backup]);
      expect(
        result.failureOrNull,
        isA<NetworkFailure>().having(
          (f) => f.message,
          'message',
          'Network error',
        ),
      );
    },
  );

  test('v3 distinguishes decode errors from transport failures', () async {
    final malformed = _repository(
      _Origin((_) async => _response(utf8.encode('{"report":'))),
    );
    expect(
      (await malformed.getSourceSnapshot(_modernId)).failureOrNull,
      isA<DecodeFailure>(),
    );
    final transport = _repository(
      _Origin((_) async => ResponseBody.fromString('', 503)),
    );
    expect(
      (await transport.getSourceSnapshot(_modernId)).failureOrNull,
      isA<NetworkFailure>(),
    );
  });

  test('escapes diagnostic pointers and checks extra nested objects', () {
    final body = utf8.encode(r'{"~x":[{"a/b":1,"a\/b":2}]}');
    expect(
      () => EarthquakeReportSnapshot.decode(body, requestedReportId: _modernId),
      throwsA(
        isA<EarthquakeReportSourceException>()
            .having(
              (e) => e.code,
              'code',
              EarthquakeReportSourceError.duplicateKey,
            )
            .having((e) => e.path, 'path', '/~0x/0/a~1b'),
      ),
    );
  });

  test('reports malformed decimal syntax at the numeric field', () {
    final body = utf8.encode(
      modernText.replaceFirst('"mag":3.9', '"mag":03.9'),
    );
    expect(
      () => EarthquakeReportSnapshot.decode(body, requestedReportId: _modernId),
      throwsA(
        isA<EarthquakeReportSourceException>()
            .having(
              (e) => e.code,
              'code',
              EarthquakeReportSourceError.malformedJson,
            )
            .having((e) => e.path, 'path', '/mag'),
      ),
    );
  });

  test(
    'rejects non-finite, non-numeric, and truncating values at source paths',
    () {
      for (final (token, replacement, field) in [
        ('"mag":3.9', '"mag":1e999', '/mag'),
        ('"mag":3.9', '"mag":"3.9"', '/mag'),
        ('"time":1776827724000', '"time":1776827724000.5', '/time'),
        ('"time":1776827724000', '"time":253402272000000', '/time'),
        ('"trem":0', '"trem":9223372036854775808', '/trem'),
        ('"int":2', '"int":2e0', '/list/臺東縣/int'),
        ('"lon":121.37', '"lon":null', '/list/臺東縣/town/成功/lon'),
      ]) {
        final invalid = utf8.encode(
          modernText.replaceFirst(token, replacement),
        );
        expect(
          () => EarthquakeReportSnapshot.decode(
            invalid,
            requestedReportId: _modernId,
          ),
          throwsA(
            isA<EarthquakeReportSourceException>()
                .having(
                  (e) => e.code,
                  'code',
                  EarthquakeReportSourceError.invalidField,
                )
                .having((e) => e.path, 'path', field),
          ),
        );
      }
    },
  );

  test(
    'uses the failover response for both the report and its evidence',
    () async {
      final origin = _Origin((request) async {
        if (request.uri.host == 'api.core-tnn1.exptech.dev') {
          return ResponseBody.fromString('', 503);
        }
        return _response(modern);
      });
      final result = await _repository(origin).getSnapshot(_modernId);
      expect(origin.requests.map((request) => request.uri.host), [
        'api.core-tnn1.exptech.dev',
        'api.core-tyo1.exptech.dev',
      ]);
      expect(result.valueOrNull!.report.id, _modernId);
      expect(result.valueOrNull!.bodySha256, _modernHash);
    },
  );

  test(
    'refreshes a lossy legacy cache row and revalidates exact raw bytes',
    () async {
      final db = openMemoryDb();
      addTearDown(db.close);
      await EtagCacheStore.createSchema(db);
      final cache = EtagCacheStore(db);
      const url =
          'https://api.core-tnn1.exptech.dev/api/v2/eq/report/$_modernId';
      const etag = '"current"';
      final exact = utf8.encode(
        modernText.replaceFirst('"mag":3.9', '"mag":3.900'),
      );
      await cache.write(url, etag: etag, body: modernText);
      final origin = _Origin(
        (request) async => request.headers['if-none-match'] == etag
            ? ResponseBody.fromString('', 304)
            : _response(exact, etag: etag),
      );
      final api = _api(origin, cache: cache);

      final fresh = await api.getReport(_modernId);
      expect(fresh.etag, etag);
      expect(fresh.bytes, exact);
      expect(origin.requests.single.headers['if-none-match'], isNull);
      // Cache writes are asynchronous. Wait for the binary validator, which is
      // the same metadata the next HTTP request will use.
      for (
        var attempt = 0;
        attempt < 40 && await cache.readEtag(url, binary: true) == null;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      final revalidated = await api.getReport(_modernId);
      expect(origin.requests, hasLength(2));
      expect(origin.requests.last.headers['if-none-match'], etag);
      expect(revalidated.bytes, exact);
      final freshSnapshot = EarthquakeReportSnapshot.decode(
        fresh.bytes,
        requestedReportId: _modernId,
      );
      final restoredSnapshot = EarthquakeReportSnapshot.decode(
        revalidated.bytes,
        requestedReportId: _modernId,
      );
      expect(restoredSnapshot.report, freshSnapshot.report);
      expect(restoredSnapshot.sourceNumbers['/mag'], '3.900');
      expect(
        freshSnapshot.bodySha256,
        'e0f8a4102b6a60ff5876d80a71ba26daac419d9951af30a0d6ebbf2fbdecb8ba',
      );
      expect(restoredSnapshot.bodySha256, freshSnapshot.bodySha256);
      expect(revalidated.etag, etag);
    },
  );

  test(
    'a 304 for an overwritten body fails over instead of mixing snapshots',
    () async {
      final db = openMemoryDb();
      addTearDown(db.close);
      await EtagCacheStore.createSchema(db);
      final cache = EtagCacheStore(db);
      const url =
          'https://api.core-tnn1.exptech.dev/api/v2/eq/report/$_modernId';
      Future<void> write(String etag, Uint8List bytes) =>
          cache.writeBytes(url, etag: etag, bytes: bytes, size: bytes.length);

      await write('"old"', modern);
      final replacement = utf8.encode(
        modernText.replaceFirst('"mag":3.9', '"mag":4.2'),
      );
      final origin = _Origin((request) async {
        if (request.uri.toString() != url) {
          return _response(modern, etag: '"failover"');
        }
        expect(request.headers['if-none-match'], '"old"');
        await write('"new"', replacement);
        return ResponseBody.fromString('', 304);
      });

      final result = await _repository(
        origin,
        cache: cache,
      ).getSnapshot(_modernId);
      expect(origin.requests, hasLength(2));
      expect(result.valueOrNull!.bodySha256, _modernHash);
      expect(result.valueOrNull!.etag, '"failover"');
      expect(result.valueOrNull!.sourceNumbers['/mag'], '3.9');
      final cached = await cache.readBytes(url);
      expect(cached!.etag, '"new"');
      expect(cached.bytes, replacement);
    },
  );
}
