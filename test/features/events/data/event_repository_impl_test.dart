/// Nationwide and a township are different requests. Serving one as the other
/// tells a user about a warning that does not cover them, or hides one that
/// does — so the township code is pinned on its way into the path, and so is
/// what happens when it cannot be read as one.
///
/// Every failure the card API can answer with (404 for an unknown card or
/// language, 410 for a retired route, 503 while its database is down, a body
/// of the wrong shape) must arrive as an `Err`, never as a throw.
library;

import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:dpip/features/events/data/event_repository_impl.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:flutter_test/flutter_test.dart';

const _listBody = '''
{"lang":"en","cards":[
  {"id":1001,"serial":1,"kind":"issue","type":"thunderstorm","hazard":"thunderstorm","status":1,"author":"test","lang":"en","title":"Taipei thunderstorm","subtitle":"Xinyi alert","send":1699996400000,"expires":1700003600000,"hasPolygon":false},
  {"id":1002,"serial":1,"kind":"issue","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"test","lang":"en","title":"Heavy rain advisory","subtitle":"Northern Taiwan","send":1699992800000,"expires":1700007200000,"hasPolygon":true}
]}
''';

const _detailBody = '''
{"lang":"en","cards":[{"id":42,"serial":1,"kind":"issue","type":"earthquake","hazard":"earthquake","status":1,"author":"cwa","lang":"zh-TW","title":"地震","subtitle":"規模 5",
  "send":1000,"expires":2000,"area":[],"hasPolygon":false,"addition":{"max":4,"area":["臺北市"]},"description":"說明"}]}
''';

/// One recorded call: which method, with what `{lang}`, `{region}` and id.
typedef _Call = ({String method, String lang, int? region, int? id});

class _Api implements EventApi {
  final List<_Call> calls = [];

  /// Thrown by every method when set.
  Object? error;

  Staleness? stale;

  @override
  Future<Fetched<EventCardList>> history({
    required String lang,
    int? region,
  }) async {
    calls.add((method: 'history', lang: lang, region: region, id: null));
    if (error case final e?) throw e;
    return (data: EventCardList.fromJson(jsonDecode(_listBody)), stale: stale);
  }

  @override
  Future<EventCardList> realtime({required String lang, int? region}) async {
    calls.add((method: 'realtime', lang: lang, region: region, id: null));
    if (error case final e?) throw e;
    return EventCardList.fromJson(jsonDecode(_listBody));
  }

  @override
  Future<EventCardDetail> detail({
    required String lang,
    required int id,
    required int region,
  }) async {
    calls.add((method: 'detail', lang: lang, region: region, id: id));
    if (error case final e?) throw e;
    return EventCardDetail.fromJson(jsonDecode(_detailBody));
  }
}

DioException _status(int code) {
  final options = RequestOptions(path: '/api/v2/dpip/en/realtime');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: code),
  );
}

void main() {
  late _Api api;
  late Locale locale;
  late EventRepositoryImpl repo;

  setUp(() {
    api = _Api();
    locale = const Locale('zh', 'TW');
    repo = EventRepositoryImpl(api, locale: () => locale);
  });

  group('region code', () {
    test('a township code goes into every request as its integer', () async {
      await repo.events(regionCode: '710');
      await repo.activeEvents(regionCode: '237');
      await repo.detail(id: 42, regionCode: '200');

      expect([for (final c in api.calls) c.region], [710, 237, 200]);
      expect(api.calls.last.id, 42);
    });

    test('a leading zero does not change the township', () async {
      await repo.events(regionCode: '063');

      expect(api.calls.single.region, 63);
    });

    test('null is the nationwide list, and region 0 for a detail', () async {
      await repo.events();
      await repo.activeEvents();
      await repo.detail(id: 7);

      expect(
        [for (final c in api.calls) c.method],
        ['history', 'realtime', 'detail'],
      );
      expect([for (final c in api.calls) c.region], [null, null, 0]);
    });

    for (final bad in [
      '',
      'abc',
      '71O',
      ' 710',
      '+710',
      '-1',
      '0x10',
      '1.5',
      '2147483648',
      '99999999999999999999',
    ]) {
      test('"$bad" falls back to nationwide, with a warning', () async {
        Log.talker.cleanHistory();

        final history = await repo.events(regionCode: bad);
        final active = await repo.activeEvents(regionCode: bad);
        final detail = await repo.detail(id: 42, regionCode: bad);

        expect(history.isOk && active.isOk && detail.isOk, isTrue);
        expect([for (final c in api.calls) c.region], [null, null, 0]);
        final warnings = [
          for (final line in Log.talker.history)
            if (line.message?.contains('region code "$bad"') ?? false) line,
        ];
        expect(warnings, hasLength(3));
      });
    }

    test('the int32 maximum is still a region', () async {
      await repo.events(regionCode: '2147483647');

      expect(api.calls.single.region, 2147483647);
    });
  });

  group('language', () {
    test(
      'each request asks for the injected locale, read at call time',
      () async {
        await repo.events();
        locale = const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        );
        await repo.activeEvents();
        locale = const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        );
        await repo.detail(id: 1);
        locale = const Locale('ja');
        await repo.events(regionCode: '100');
        locale = const Locale('fr');
        await repo.activeEvents();

        expect(
          [for (final c in api.calls) c.lang],
          ['zh-TW', 'zh-Hans', 'zh-Hant-HK', 'ja', 'zh-TW'],
        );
      },
    );
  });

  group('values', () {
    test('lists come back as their cards; a detail as itself', () async {
      final history = await repo.events();
      final active = await repo.activeEvents();
      final detail = await repo.detail(id: 42);

      expect([for (final c in history.valueOrNull!) c.id], [1001, 1002]);
      expect([for (final c in active.valueOrNull!) c.id], [1001, 1002]);
      expect(detail.valueOrNull!.reports, hasLength(1));
    });

    test(
      'saved history keeps its marker; active events never have one',
      () async {
        final since = DateTime.utc(2026, 11, 27, 1);
        api.stale = Staleness(
          failure: const NetworkFailure('Server error (503)'),
          since: since,
        );

        final history = await repo.events(regionCode: '710');
        final active = await repo.activeEvents();
        final detail = await repo.detail(id: 42);

        expect((history as Ok).stale?.since, since);
        expect((active as Ok).stale, isNull);
        expect((detail as Ok).stale, isNull);
      },
    );
  });

  group('failures are Err, never a throw', () {
    final cases = <String, (Object, Matcher)>{
      '404': (_status(404), isA<NotFoundFailure>()),
      '410': (_status(410), isA<NetworkFailure>()),
      '503': (_status(503), isA<NetworkFailure>()),
      '400': (_status(400), isA<NetworkFailure>()),
      'FormatException': (
        const FormatException('cards is not a list'),
        isA<DecodeFailure>(),
      ),
      'connection error': (
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
        isA<NetworkFailure>(),
      ),
    };

    for (final MapEntry(key: name, value: (error, failure)) in cases.entries) {
      test(name, () async {
        api.error = error;

        final results = <Result<Object>>[
          await repo.events(),
          await repo.activeEvents(regionCode: '100'),
          await repo.detail(id: 42, regionCode: '100'),
        ];

        for (final result in results) {
          expect(result, isA<Err<Object>>(), reason: name);
          expect(result.failureOrNull, failure, reason: name);
        }
      });
    }
  });
}
