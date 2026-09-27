/// The typhoon repository's half of the data layer's contract: a transport or
/// decode fault leaves as a typed [Failure], never as a thrown `DioException`
/// or a silent empty dataset.
///
/// Ten one-line methods make this easy to get wrong exactly once — a method
/// that forgets the guard returns `Ok` on a dead source, and for the typhoon
/// track that is a map with no storm on it rather than an error the user can
/// act on. So every method is exercised against the same fault, plus the one
/// decode the repository does itself (the delta-encoded history axis).
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/typhoon/data/meteor_typhoon_api.dart';
import 'package:dpip/features/typhoon/data/meteor_typhoon_repository_impl.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every dataset answers with the same fault, so one loop can hold all ten
/// methods to the contract instead of ten near-identical tests.
class _FailingApi implements MeteorTyphoonApi {
  _FailingApi(this.error);

  final Object error;

  @override
  Future<Map<String, dynamic>> getCyclones() async => throw error;

  @override
  Future<Map<String, dynamic>> getTrack() async => throw error;

  @override
  Future<Map<String, dynamic>> getPotential() async => throw error;

  @override
  Future<Map<String, dynamic>> getProbability() async => throw error;

  @override
  Future<Map<String, dynamic>> getWarning() async => throw error;

  @override
  Future<List<dynamic>> getList(TyphoonKind kind) async => throw error;

  @override
  Future<Map<String, dynamic>> getAt(TyphoonKind kind, int second) async =>
      throw error;
}

/// Answers only the history axis, and records which dataset was asked for —
/// the kind is the one argument the repository has to pass through intact.
class _HistoryApi implements MeteorTyphoonApi {
  _HistoryApi(this.axis);

  final List<dynamic> axis;
  final List<TyphoonKind> asked = [];

  @override
  Future<List<dynamic>> getList(TyphoonKind kind) async {
    asked.add(kind);
    return axis;
  }

  @override
  Future<Map<String, dynamic>> getCyclones() async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getTrack() async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getPotential() async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getProbability() async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getWarning() async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getAt(TyphoonKind kind, int second) async =>
      throw UnimplementedError();
}

/// The ten methods, as calls, so a fault can be held against every one.
final Map<String, Future<Result<Object?>> Function(MeteorTyphoonRepository)>
_calls = {
  'cyclones': (repo) => repo.cyclones(),
  'track': (repo) => repo.track(),
  'potential': (repo) => repo.potential(),
  'probability': (repo) => repo.probability(),
  'warning': (repo) => repo.warning(),
  'history': (repo) => repo.history(TyphoonKind.track),
  'trackAt': (repo) => repo.trackAt(0),
  'potentialAt': (repo) => repo.potentialAt(0),
  'probabilityAt': (repo) => repo.probabilityAt(0),
  'warningAt': (repo) => repo.warningAt(0),
};

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v5/meteor/typhoon');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

Future<void> _expectEveryCallFailsWith(Object error, Matcher failure) async {
  final repo = MeteorTyphoonRepositoryImpl(_FailingApi(error));

  for (final entry in _calls.entries) {
    final result = await entry.value(repo);
    expect(result.failureOrNull, failure, reason: entry.key);
    expect(result.valueOrNull, isNull, reason: entry.key);
  }
}

void main() {
  test('a 404 folds into NotFoundFailure, not a crash', () async {
    // The one status where retrying is not a recovery — a history snapshot past
    // the end of retention answers this once a second for a whole replay.
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

  test('a server error folds into NetworkFailure carrying the code', () async {
    final repo = MeteorTyphoonRepositoryImpl(
      _FailingApi(_dio(DioExceptionType.badResponse, status: 503)),
    );

    final failure = (await repo.track()).failureOrNull;
    expect(
      failure,
      isA<NetworkFailure>().having(
        (f) => f.message,
        'message',
        contains('503'),
      ),
    );
  });

  test('malformed JSON folds into DecodeFailure', () async {
    await _expectEveryCallFailsWith(
      const FormatException('unexpected token'),
      isA<DecodeFailure>(),
    );
  });

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      await _expectEveryCallFailsWith(
        StateError('no element'),
        isA<UnexpectedFailure>(),
      );
    },
  );

  test('history restores the delta axis to absolute seconds', () async {
    final api = _HistoryApi([1000, 5, 5, 0]);

    final result = await MeteorTyphoonRepositoryImpl(api)
        .history(TyphoonKind.potential);

    // The repository's own decode: `/list` sends one base plus deltas, and
    // everything downstream (the timeline scrubber) reads absolute seconds.
    expect(result.valueOrNull, [1000, 1005, 1010, 1010]);
    expect(api.asked, [TyphoonKind.potential]);
  });
}
