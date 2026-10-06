import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ok exposes the value and no failure', () {
    const result = Ok<int>(7);
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, 7);
    expect(result.failureOrNull, isNull);
    expect(result.when(ok: (v) => v, err: (_) => -1), 7);
    expect(result.map((v) => '$v').valueOrNull, '7');
  });

  test('Err exposes the failure and no value', () {
    const failure = NetworkFailure('down');
    const result = Err<int>(failure);
    expect(result.isOk, isFalse);
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull, failure);
    expect(result.when(ok: (v) => v, err: (f) => f.message), 'down');
    expect(result.map((v) => '$v').failureOrNull, failure);
  });

  test('each failure type keeps the message it was given', () {
    const cases = <Failure>[
      NoDataFailure('empty'),
      MeshChannelNoSlotFailure('full'),
      MeshChannelConflictFailure('key'),
      PermissionDeniedFailure('denied'),
      TimeoutFailure('slow'),
      DecodeFailure('shape'),
      NotFoundFailure('gone'),
      UnexpectedFailure('boom'),
    ];
    expect(cases.map((f) => f.message), [
      'empty',
      'full',
      'key',
      'denied',
      'slow',
      'shape',
      'gone',
      'boom',
    ]);
  });
}
