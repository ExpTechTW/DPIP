/// `tool/colorize_logs.sh` — colour added where ANSI actually works.
///
/// The app writes plain text on purpose: on iOS the platform's log path
/// escapes the escape character, so a terminal that supports ANSI still
/// receives a backslash and the sequence and prints it
/// (flutter/flutter#20663). A pipe in the terminal has neither problem.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _esc = 27;

/// Runs the script over [input]. Without a pty, stdout is not a terminal.
String run(String input, {bool tty = false}) {
  final script = '${Directory.current.path}/tool/colorize_logs.sh';
  final result = tty
      // `script` lends the pipeline a pty, which is the only way to exercise
      // the branch that decides whether to emit anything at all.
      ? Process.runSync('script', [
          '-q',
          '/dev/null',
          'bash',
          '-c',
          'printf %s ${_quote(input)} | $script',
        ])
      : Process.runSync('bash', ['-c', 'printf %s ${_quote(input)} | $script']);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout.toString();
}

String _quote(String s) => "'${s.replaceAll("'", r"'\''")}'";

void main() {
  const line = 'flutter: [WARN] | 4:45:48 492ms | eew SSE not connected\n';

  test('the flutter: prefix is dropped', () {
    expect(run(line), startsWith('[WARN]'));
  });

  test('nothing is coloured when the output is not a terminal', () {
    // Redirected to a file or another program, escapes are exactly the noise
    // this exists to remove.
    expect(run(line).codeUnits, isNot(contains(_esc)));
  });

  test('the tag is coloured when it is', () {
    final out = run(line, tty: true);
    expect(out.codeUnits, contains(_esc));
    expect(out, contains('eew SSE not connected'));
  });

  test('a line that is not ours passes through untouched', () {
    const other = '-[WFIsolatedShortcutRunner init] Taking sandbox\n';
    expect(run(other), other);
  });

  test('every level the app can emit is recognised', () {
    for (final level in [
      'CRITICAL',
      'ERROR',
      'WARN',
      'INFO',
      'DEBUG',
      'VERBOSE',
    ]) {
      final out = run('flutter: [$level] | 1:00:00 1ms | x\n', tty: true);
      expect(out.codeUnits, contains(_esc), reason: level);
    }
  });

  test('an interrupt does not kill it before the writer finishes', () {
    // Ctrl-C reaches every process in the foreground group. Without the trap
    // the filter dies first and `flutter run` — still shutting down, still
    // printing — writes into a closed pipe and reports EPIPE as an unhandled
    // exception.
    final script = '${Directory.current.path}/tool/colorize_logs.sh';
    final result = Process.runSync('bash', [
      '-c',
      // A writer that keeps printing after the signal, as flutter does.
      '( for i in 1 2 3; do echo "flutter: [INFO] | 1:00:0\$i 1ms | line \$i";'
          ' sleep 0.2; done ) | $script & '
          'pid=\$!; sleep 0.3; kill -INT \$pid 2>/dev/null; wait \$pid',
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('line 3'), reason: 'it read to the end');
  });
}
