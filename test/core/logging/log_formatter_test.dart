/// The console formatter, on both sides of the colour switch.
///
/// Whether an escape sequence renders is the terminal's business, not the
/// app's — see [Log.enableConsoleColor] for why this is a `--dart-define`
/// rather than a detection.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/core/logging/log.dart';

const _esc = 27;

String format(String message, {required bool colour}) =>
    const TagFormatter().fmt(
      LogDetails(
        message: message,
        level: LogLevel.warning,
        pen: AnsiPen()..yellow(),
      ),
      TalkerLoggerSettings(enableColors: colour),
    );

void main() {
  // `ansicolor` disables itself when stdout is not a terminal, and a test host
  // is not one. `TalkerLogger`'s constructor forces it back on regardless of
  // stdout — which is why the escapes reached a pipe that could not read them
  // in the first place — so the coloured path has to be opened here to be
  // exercised at all.
  setUp(() => ansiColorDisabled = false);
  tearDown(() => ansiColorDisabled = true);

  test('colour off: the line is exactly the message', () {
    final out = format('[WARN] | 12:00 | hi', colour: false);
    expect(out, '[WARN] | 12:00 | hi');
    expect(out.codeUnits, isNot(contains(_esc)));
  });

  test('colour on: only the tag is painted', () {
    final out = format('[WARN] | 12:00 | hi', colour: true);
    expect(out.codeUnits, contains(_esc), reason: 'the tag is coloured');
    // A fully coloured line is harder to read than a plain one, and a leak
    // into a window that cannot render it then costs one token, not the line.
    final afterTag = out.substring(out.indexOf('|'));
    expect(afterTag.codeUnits, isNot(contains(_esc)));
    expect(out, contains('hi'));
  });

  test('a line with no tag is left alone', () {
    expect(format('no tag here', colour: true), 'no tag here');
  });

  test('the default build ships no escapes at all', () {
    // The common window — VS Code's Debug Console — prints them literally.
    expect(Log.enableConsoleColor, isFalse);
  });
}
