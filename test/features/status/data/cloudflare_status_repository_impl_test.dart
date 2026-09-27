/// [CloudflareStatusRepositoryImpl] has one job: fold [CloudflareStatusApi]'s
/// transport faults into a typed [Failure], and otherwise hand the raw body
/// to `parseCloudflareStatus` untouched.
///
/// Unlike `ServerStatusRepositoryImpl` next to it, there is no decode-failure
/// case to test here: `parseCloudflareStatus` treats anything that isn't the
/// exact shape it expects (not a Map, no `components` list, a component
/// missing `name`/`status`) as "nothing observed" rather than an error — down
/// to the empty-components case pinned below. So this file's contract is the
/// transport-fault mapping plus one proof that a real payload survives the
/// trip through the repository as-is.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/features/status/data/cloudflare_status_api.dart';
import 'package:dpip/features/status/data/cloudflare_status_repository_impl.dart';
import 'package:dpip/features/status/domain/cloudflare_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns [answer] from `getComponents`, or throws it when it is an
/// [Exception]/[Error] — enough to script both the fault matrix and the
/// happy path without a mocking framework.
class _ScriptedCloudflareStatusApi implements CloudflareStatusApi {
  _ScriptedCloudflareStatusApi(this.answer);

  final Object answer;

  @override
  Future<dynamic> getComponents() async {
    if (answer is Exception || answer is Error) throw answer;
    return answer;
  }
}

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(
    path: 'https://www.cloudflarestatus.com/api/v2/components.json',
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
    final repo = CloudflareStatusRepositoryImpl(
      _ScriptedCloudflareStatusApi(
        _dio(DioExceptionType.badResponse, status: 404),
      ),
    );

    final result = await repo.status();

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('a timeout folds into TimeoutFailure', () async {
    final repo = CloudflareStatusRepositoryImpl(
      _ScriptedCloudflareStatusApi(_dio(DioExceptionType.connectionTimeout)),
    );

    final result = await repo.status();

    expect(result.failureOrNull, isA<TimeoutFailure>());
  });

  test('a dropped connection folds into NetworkFailure', () async {
    final repo = CloudflareStatusRepositoryImpl(
      _ScriptedCloudflareStatusApi(_dio(DioExceptionType.connectionError)),
    );

    final result = await repo.status();

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      final repo = CloudflareStatusRepositoryImpl(
        _ScriptedCloudflareStatusApi(StateError('boom')),
      );

      final result = await repo.status();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
    },
  );

  test(
    'a real payload survives the trip: Taipei kept, others dropped',
    () async {
      final repo = CloudflareStatusRepositoryImpl(
        _ScriptedCloudflareStatusApi({
          'components': [
            {
              'name': 'Taipei - (TPE)',
              'status': 'operational',
              'updated_at': '2026-01-01T00:00:00Z',
            },
            {
              'name': 'Frankfurt - (FRA)',
              'status': 'major_outage',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          ],
        }),
      );

      final result = await repo.status();

      final status = result.valueOrNull;
      expect(status, isNotNull);
      expect(status!.components, hasLength(1));
      expect(status.components.single.name, 'Taipei - (TPE)');
      expect(
        status.components.single.state,
        CloudflareComponentState.operational,
      );
    },
  );

  test('a body with no components list is not an error — an empty snapshot '
      'rather than a decode failure', () async {
    final repo = CloudflareStatusRepositoryImpl(
      _ScriptedCloudflareStatusApi(<String, dynamic>{}),
    );

    final result = await repo.status();

    expect(result.valueOrNull?.components, isEmpty);
    expect(result.valueOrNull?.allOperational, isFalse);
  });
}
