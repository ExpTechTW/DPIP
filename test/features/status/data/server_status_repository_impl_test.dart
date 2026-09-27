/// [ServerStatusRepositoryImpl] folds [ServerStatusApi] transport faults into
/// a typed [Failure], and — unlike `CloudflareStatusRepositoryImpl` next to
/// it — also has one genuine, repository-visible decode fault: `parseStatus`
/// throws a bare `FormatException` when the Grafana reply has no `results`
/// map at all, which is exactly the shape [guardResult] folds into a
/// [DecodeFailure].
///
/// The scalar/instance extraction inside `parseStatus` (the `values[1][0]`
/// digging, the per-refId instance label) is that function's own contract,
/// not this repository's — this file proves the wiring with one realistic
/// payload rather than re-deriving every branch of a collaborator that has
/// its own test coverage.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/features/status/data/server_status_api.dart';
import 'package:dpip/features/status/data/server_status_repository_impl.dart';
import 'package:dpip/features/status/domain/server_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns [answer] from `getStatus`, or throws it when it is an
/// [Exception]/[Error] — enough to script both the fault matrix and the
/// happy path without a mocking framework.
class _ScriptedServerStatusApi implements ServerStatusApi {
  _ScriptedServerStatusApi(this.answer);

  final Object answer;

  @override
  Future<dynamic> getStatus() async {
    if (answer is Exception || answer is Error) throw answer;
    return answer;
  }
}

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(
    path: 'https://status.exptech.dev/api/ds/query',
  );
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

void main() {
  test('a 404 folds into NotFoundFailure, not a crash', () async {
    final repo = ServerStatusRepositoryImpl(
      _ScriptedServerStatusApi(_dio(DioExceptionType.badResponse, status: 404)),
    );

    final result = await repo.status();

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('a timeout folds into TimeoutFailure', () async {
    final repo = ServerStatusRepositoryImpl(
      _ScriptedServerStatusApi(_dio(DioExceptionType.connectionTimeout)),
    );

    final result = await repo.status();

    expect(result.failureOrNull, isA<TimeoutFailure>());
  });

  test('a dropped connection folds into NetworkFailure', () async {
    final repo = ServerStatusRepositoryImpl(
      _ScriptedServerStatusApi(_dio(DioExceptionType.connectionError)),
    );

    final result = await repo.status();

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      final repo = ServerStatusRepositoryImpl(
        _ScriptedServerStatusApi(StateError('boom')),
      );

      final result = await repo.status();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
    },
  );

  test('a reply with no results map is the one decode fault this repository '
      'can produce', () async {
    final repo = ServerStatusRepositoryImpl(
      _ScriptedServerStatusApi({'results': 'oops'}),
    );

    final result = await repo.status();

    expect(result.failureOrNull, isA<DecodeFailure>());
  });

  test('a real Grafana payload maps into ServerStatus', () async {
    final repo = ServerStatusRepositoryImpl(
      _ScriptedServerStatusApi({
        'results': {
          'status': {
            'frames': [
              {
                'data': {
                  'values': [
                    [0],
                    [2],
                  ],
                },
              },
            ],
          },
          'error_rate_5xx': {
            'frames': [
              {
                'data': {
                  'values': [
                    [0],
                    [12.5],
                  ],
                },
                'schema': {
                  'fields': [
                    {},
                    {
                      'labels': {'instance': 'lb-tpe1'},
                    },
                  ],
                },
              },
            ],
          },
          'avg_latency': {
            'frames': [
              {
                'data': {
                  'values': [
                    [0],
                    [42],
                  ],
                },
              },
            ],
          },
        },
      }),
    );

    final result = await repo.status();

    final status = result.valueOrNull;
    expect(status, isNotNull);
    expect(status!.down.value, 2);
    expect(status.down.instance, isNull);
    expect(status.errorRate.value, 12.5);
    expect(status.errorRate.instance, 'lb-tpe1');
    expect(status.latency.value, 42);
    // Two nginx jobs reporting down means the summary must read "down", not
    // merely degraded — this is the one condition `allUp`/`health` cannot
    // afford to get backwards.
    expect(status.allUp, isFalse);
    expect(status.health, StatusHealth.down);
  });
}
