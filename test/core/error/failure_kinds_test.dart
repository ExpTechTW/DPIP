/// "Nothing right now" and "your radio already has this channel under another
/// key" are not generic errors. Collapsing either into UnexpectedFailure
/// makes the UI offer a retry that cannot work.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no-data and a channel-key clash stay their own types', () {
    const empty = NoDataFailure('nothing right now');
    const clash = MeshChannelConflictFailure(
      'A channel named DPIP already exists with a different key',
    );
    expect(empty, isA<Failure>());
    expect(empty.message, 'nothing right now');
    expect(clash.message, contains('different key'));
    expect(clash, isNot(isA<UnexpectedFailure>()));
    expect(clash, isNot(isA<MeshChannelNoSlotFailure>()));
  });

  test('each failure kind keeps the message it was given', () {
    final kinds = <Failure>[
      TimeoutFailure('timed out'),
      DecodeFailure('not json'),
      NoDataFailure('empty'),
      NotFoundFailure('gone'),
      UnexpectedFailure('unexpected'),
      MeshChannelNoSlotFailure('no slot'),
      MeshChannelConflictFailure('clash'),
      PermissionDeniedFailure('denied'),
      NetworkFailure('offline'),
    ];
    expect(kinds.map((f) => f.message), [
      'timed out',
      'not json',
      'empty',
      'gone',
      'unexpected',
      'no slot',
      'clash',
      'denied',
      'offline',
    ]);
  });
}
