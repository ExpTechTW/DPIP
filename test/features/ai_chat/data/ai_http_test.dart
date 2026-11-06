import 'package:dio/dio.dart';
import 'package:dpip/features/ai_chat/data/ai_http.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('statuses map to what the page explains', () {
    AiFailureKind kind(int status) => aiExceptionForStatus(status, '').kind;
    expect(kind(401), AiFailureKind.unauthorized);
    expect(kind(403), AiFailureKind.unauthorized);
    expect(kind(404), AiFailureKind.notFound);
    expect(kind(429), AiFailureKind.rateLimited);
    expect(kind(400), AiFailureKind.rejected);
    expect(kind(422), AiFailureKind.rejected);
    expect(kind(503), AiFailureKind.server);
  });

  test('the reason is read from the common error shapes', () {
    expect(errorDetail('{"error":{"message":"bad key"}}'), 'bad key');
    expect(errorDetail('{"error":"model not found"}'), 'model not found');
    expect(errorDetail('{"message":"slow down"}'), 'slow down');
    expect(errorDetail('{"detail":"nope"}'), 'nope');
    expect(errorDetail('[{"error":{"message":"gemini says"}}]'), 'gemini says');
    expect(errorDetail('plain words'), 'plain words');
    expect(errorDetail('<html>gateway</html>'), isNull);
    expect(errorDetail(''), isNull);
    expect(errorDetail('x' * 400), hasLength(301));
  });

  test('a cancellation is not a failure', () {
    expect(
      aiExceptionForDio(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
        ),
      ),
      isNull,
    );
    expect(
      aiExceptionForDio(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        ),
      )?.kind,
      AiFailureKind.timeout,
    );
  });
}
