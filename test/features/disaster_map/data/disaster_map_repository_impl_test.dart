/// [DisasterMapRepositoryImpl] wires three near-identical JSON detail
/// fetches through the shared `guardResult`/`mapException` machinery, and
/// forwards [DisasterMapRepositoryImpl.tileUrl] and both prefetch methods
/// straight through to its two collaborators.
///
/// The three detail models are not symmetric: [AedDetail]'s core fields
/// (`id`, `aed_id`, `name`, `lat`, `lng`) are all required, so a malformed or
/// empty response is a genuine, repository-visible [DecodeFailure] here.
/// [RestroomDetail] and [ShelterDetail] default every field instead, so the
/// same empty response decodes to a valid-looking, all-zero/blank object
/// rather than an error. This file pins that difference rather than papering
/// over it — only the AED path can be exercised for a decode fault at all;
/// the other two get a test proving what they do instead.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/disaster_map/data/disaster_map_api.dart';
import 'package:dpip/features/disaster_map/data/disaster_map_repository_impl.dart';
import 'package:dpip/features/disaster_map/data/dpm_tile_prefetcher.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every detail getter answers with the same fault; [tileUrl] is never
/// exercised by these tests, so it throws loudly rather than answering
/// silently.
class _FailingApi implements DisasterMapApi {
  _FailingApi(this.error);

  final Object error;

  @override
  String tileUrl(String layer) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getAedDetail(int id) async => throw error;

  @override
  Future<Map<String, dynamic>> getRestroomDetail(int id) async => throw error;

  @override
  Future<Map<String, dynamic>> getShelterDetail(int id) async => throw error;
}

/// Answers each detail getter from its own configurable JSON map (empty by
/// default) and records the id it was asked for — the one argument each
/// getter has to pass through intact. [tileUrl] returns a value derived from
/// [layer] so pure delegation can be checked without throwing.
class _DetailApi implements DisasterMapApi {
  Map<String, dynamic> aed = const {};
  Map<String, dynamic> restroom = const {};
  Map<String, dynamic> shelter = const {};
  final List<int> aedCalls = [];
  final List<int> restroomCalls = [];
  final List<int> shelterCalls = [];

  @override
  String tileUrl(String layer) => 'template:$layer';

  @override
  Future<Map<String, dynamic>> getAedDetail(int id) async {
    aedCalls.add(id);
    return aed;
  }

  @override
  Future<Map<String, dynamic>> getRestroomDetail(int id) async {
    restroomCalls.add(id);
    return restroom;
  }

  @override
  Future<Map<String, dynamic>> getShelterDetail(int id) async {
    shelterCalls.add(id);
    return shelter;
  }
}

/// Records `prefetch`/`cancel` calls without touching MapLibre or the network.
class _RecordingPrefetcher implements DpmTilePrefetcher {
  int cancelCalls = 0;
  final List<
    ({
      String layer,
      double south,
      double west,
      double north,
      double east,
      double zoom,
    })
  >
  prefetchCalls = [];

  @override
  void cancel() => cancelCalls++;

  @override
  Future<void> prefetch({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) async {
    prefetchCalls.add((
      layer: layer,
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
    ));
  }
}

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v2/tiles/dpm/aed/1');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

/// The three JSON detail getters, as calls, so one fault can be held against
/// all of them instead of three near-identical tests.
final Map<String, Future<Result<Object?>> Function(DisasterMapRepository)>
_calls = {
  'aedDetail': (repo) => repo.aedDetail(1),
  'restroomDetail': (repo) => repo.restroomDetail(1),
  'shelterDetail': (repo) => repo.shelterDetail(1),
};

Future<void> _expectEveryCallFailsWith(Object error, Matcher failure) async {
  final repo = DisasterMapRepositoryImpl(
    _FailingApi(error),
    _RecordingPrefetcher(),
  );

  for (final entry in _calls.entries) {
    final result = await entry.value(repo);
    expect(result.failureOrNull, failure, reason: entry.key);
    expect(result.valueOrNull, isNull, reason: entry.key);
  }
}

void main() {
  test('a 404 folds into NotFoundFailure, not a crash', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.badResponse, status: 404),
      isA<NotFoundFailure>(),
    );
  });

  test('a timeout folds into TimeoutFailure', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.connectionTimeout),
      isA<TimeoutFailure>(),
    );
  });

  test('a dropped connection folds into NetworkFailure', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.connectionError),
      isA<NetworkFailure>(),
    );
  });

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      await _expectEveryCallFailsWith(
        StateError('boom'),
        isA<UnexpectedFailure>(),
      );
    },
  );

  test('aedDetail maps a full JSON object into AedDetail', () async {
    final api = _DetailApi()
      ..aed = const {
        'id': 7,
        'aed_id': 'A007',
        'name': 'Station 7',
        'lat': 24.1,
        'lng': 120.7,
      };
    final repo = DisasterMapRepositoryImpl(api, _RecordingPrefetcher());

    final result = await repo.aedDetail(7);

    final detail = result.valueOrNull;
    expect(detail, isNotNull);
    expect(detail!.id, 7);
    expect(detail.aedId, 'A007');
    expect(detail.name, 'Station 7');
    expect(api.aedCalls, [7]);
  });

  test('aedDetail on an empty response is the one repository-visible '
      'DecodeFailure these three models can produce', () async {
    final api = _DetailApi();
    final repo = DisasterMapRepositoryImpl(api, _RecordingPrefetcher());

    final result = await repo.aedDetail(1);

    expect(result.failureOrNull, isA<DecodeFailure>());
  });

  test(
    'restroomDetail on an empty response decodes to all-default fields '
    'instead of a decode failure — every RestroomDetail field is optional',
    () async {
      final api = _DetailApi();
      final repo = DisasterMapRepositoryImpl(api, _RecordingPrefetcher());

      final result = await repo.restroomDetail(1);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.name, '');
      expect(result.valueOrNull?.latitude, 0);
      expect(api.restroomCalls, [1]);
    },
  );

  test(
    'shelterDetail on an empty response decodes to all-default fields '
    'instead of a decode failure — every ShelterDetail field is optional',
    () async {
      final api = _DetailApi();
      final repo = DisasterMapRepositoryImpl(api, _RecordingPrefetcher());

      final result = await repo.shelterDetail(1);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.name, '');
      expect(result.valueOrNull?.category, isEmpty);
      expect(api.shelterCalls, [1]);
    },
  );

  test('tileUrl forwards straight through to the api', () {
    final api = _DetailApi();
    final repo = DisasterMapRepositoryImpl(api, _RecordingPrefetcher());

    expect(repo.tileUrl('aed'), 'template:aed');
  });

  test('prefetchTiles forwards every argument to the prefetcher', () async {
    final prefetcher = _RecordingPrefetcher();
    final repo = DisasterMapRepositoryImpl(
      _FailingApi(StateError('unused')),
      prefetcher,
    );

    await repo.prefetchTiles(
      layer: 'shelter',
      south: 21.9,
      west: 120.0,
      north: 25.3,
      east: 122.0,
      zoom: 12.0,
    );

    expect(prefetcher.prefetchCalls, [
      (
        layer: 'shelter',
        south: 21.9,
        west: 120.0,
        north: 25.3,
        east: 122.0,
        zoom: 12.0,
      ),
    ]);
  });

  test('cancelTilePrefetch forwards to the prefetcher', () {
    final prefetcher = _RecordingPrefetcher();
    final repo = DisasterMapRepositoryImpl(
      _FailingApi(StateError('unused')),
      prefetcher,
    );

    repo.cancelTilePrefetch();

    expect(prefetcher.cancelCalls, 1);
  });
}
