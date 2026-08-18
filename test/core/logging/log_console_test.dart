/// What the console actually receives.
///
/// `flutter run` prefixes every printed line with `flutter: `, and nothing on
/// that pipe interprets ANSI — so the default logger's box drew three prefixed
/// lines around one message and its colours arrived as the literal text
/// `^[[38;5;4m`.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dpip/core/logging/log.dart';

List<String> _printed(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  test('one entry prints one line', () {
    final lines = _printed(() {
      Log.info('a line');
      Log.warning('another');
    });
    expect(lines.length, 2);
  });

  test('nothing is drawn around it', () {
    final line = _printed(() => Log.info('a line')).single;
    expect(line, isNot(contains('\u2500')), reason: 'no rule');
    expect(line, isNot(contains('\u2502')), reason: 'no border');
    expect(line, isNot(contains('\u250c')));
    expect(line, isNot(contains('\u2514')));
  });

  test('no escape sequence reaches a pipe that cannot read one', () {
    final line = _printed(() => Log.error('a line')).single;
    expect(line, isNot(contains(String.fromCharCode(27))));
  });

  test('the level tag and the message both survive', () {
    final line = _printed(() => Log.warning('poll failed')).single;
    expect(line, contains('[WARN]'));
    expect(line, contains('poll failed'));
  });
}
