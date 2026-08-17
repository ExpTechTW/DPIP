/// The one shape a log line has, in the console and in an uploaded dump.
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
  test('a line reads [time][TAG] : message', () {
    expect(
      logLine(
        tag: 'INFO',
        time: DateTime(2026, 8, 18, 5, 32, 38),
        message: 'Firebase initialized',
      ),
      '[5:32:38][INFO]    : Firebase initialized',
    );
  });

  test('the colons line up whatever the tag', () {
    final columns = <int>{};
    for (final tag in [
      'VERBOSE',
      'DEBUG',
      'INFO',
      'WARN',
      'ERROR',
      'CRITICAL',
    ]) {
      final line = logLine(
        tag: tag,
        time: DateTime(2026, 8, 18, 5, 32, 38),
        message: 'x',
      );
      columns.add(line.indexOf(': '));
    }
    expect(columns.length, 1, reason: 'one column, or the messages step');
  });

  test('minutes and seconds are padded, the hour is not', () {
    expect(
      logLine(tag: 'INFO', time: DateTime(2026, 8, 18, 5, 2, 3), message: 'x'),
      startsWith('[5:02:03]'),
    );
  });

  test('the console prints that same shape', () {
    // Talker hands the formatter a finished string, so this is a parse — if
    // its layout ever changes, this fails instead of the terminal.
    final line = _printed(() => Log.warning('poll failed')).single;
    expect(line, endsWith(': poll failed'));
    expect(line, contains('[WARN]'));
    expect(RegExp(r'^\[\d{1,2}:\d{2}:\d{2}\]').hasMatch(line), isTrue);
    // Padded to the same column the builder uses.
    expect(
      line.indexOf(': '),
      logLine(tag: 'WARN', time: DateTime.now(), message: 'x').indexOf(': '),
    );
  });

  test('the console keeps one line per entry', () {
    expect(
      _printed(() {
        Log.info('a');
        Log.error('b');
      }).length,
      2,
    );
  });
}
