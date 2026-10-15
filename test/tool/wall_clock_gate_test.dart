/// tool/check/wall_clock.sh, the gate that makes every device-clock read in
/// lib/ say why the device clock is the right one.
///
/// A gate like this has two ways to fail and they are not equally bad. Flagging
/// a line it should not costs a comment; missing a line it should flag is the
/// silent failure the gate exists to end — a `DateTime.now()` subtracted from a
/// server stamp, on the one phone whose clock is wrong. So most of these are
/// about what it must still catch, and the rest about what it must not.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A throwaway tree with [files] under it and the real gate script copied in,
/// so the test cannot drift from what CI runs.
Directory treeWith(Map<String, String> files) {
  final dir = Directory.systemTemp.createTempSync('dpipclock');
  addTearDown(() => dir.deleteSync(recursive: true));
  for (final entry in files.entries) {
    File('${dir.path}/${entry.key}')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(entry.value);
  }
  File('${dir.path}/tool/check/wall_clock.sh').parent
      .createSync(recursive: true);
  File('${Directory.current.path}/tool/check/wall_clock.sh')
      .copySync('${dir.path}/tool/check/wall_clock.sh');
  return dir;
}

ProcessResult gate(Directory tree) =>
    Process.runSync('bash', ['${tree.path}/tool/check/wall_clock.sh']);

/// Runs the gate over one file at lib/a.dart and returns what it said.
({int exitCode, String output}) check(String source) {
  final result = gate(treeWith({'lib/a.dart': source}));
  return (
    exitCode: result.exitCode,
    output: '${result.stdout}${result.stderr}',
  );
}

void main() {
  test('an unmarked call fails, by file and line, pointing at the rule', () {
    final result = check('''
void f() {
  final t = DateTime.now();
}
''');
    expect(result.exitCode, 1);
    expect(result.output, contains('lib/a.dart:2:'));
    expect(result.output, contains('ARCHITECTURE.md → Calibrated time'));
  });

  test('a reason on the same line passes', () {
    final result = check('''
final t = DateTime.now(); // wall-clock: compared only with itself
''');
    expect(result.exitCode, 0, reason: result.output);
  });

  test('a reason anywhere in the comment directly above passes', () {
    final result = check('''
void f() {
  // wall-clock: the native side stamps this with the device clock, so its
  // age is measured by the same one.
  final t = DateTime.now();
}
''');
    expect(result.exitCode, 0, reason: result.output);
  });

  test('a comment above an annotation still counts', () {
    final result = check('''
class C {
  // wall-clock: this is the device clock, by name.
  @override
  DateTime now() => DateTime.now();
}
''');
    expect(result.exitCode, 0, reason: result.output);
  });

  test('a bare marker with no reason does not', () {
    // The marker is not a password. It is there to make the author decide
    // which clock the value is compared with, and an empty one decides nothing.
    final result = check('''
final t = DateTime.now(); // wall-clock:
''');
    expect(result.exitCode, 1);
  });

  test('a marker separated from the call by code does not', () {
    final result = check('''
void f() {
  // wall-clock: meant for something else
  final a = 1;
  final t = DateTime.now();
}
''');
    expect(result.exitCode, 1);
    expect(result.output, contains('lib/a.dart:4:'));
  });

  test('a tear-off is a read of the clock too', () {
    final result = check('''
class C {
  C({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
}
''');
    expect(result.exitCode, 1);
    expect(result.output, contains('lib/a.dart:2:'));
  });

  test('DateTime.timestamp() is the same read', () {
    final result = check('''
final t = DateTime.timestamp();
''');
    expect(result.exitCode, 1);
  });

  test('a call interpolated into a string is still a call', () {
    final result = check(r'''
final s = 'at ${DateTime.now()}';
''');
    expect(result.exitCode, 1);
  });

  test('a // inside a string does not hide the call after it', () {
    // A naive "everything after // is a comment" would read the rest of this
    // line as a comment and wave the call through.
    final result = check('''
final u = 'https://example.com'; final t = DateTime.now();
''');
    expect(result.exitCode, 1);
  });

  test('a mention in a comment is not a call', () {
    final result = check('''
/// Never [DateTime.now] for anything a server stamped.
// The device clock — `DateTime.now()`.
final t = 1; // not DateTime.now()
/* DateTime.now() */
''');
    expect(result.exitCode, 0, reason: result.output);
  });

  test('generated files are skipped', () {
    final tree = treeWith({
      'lib/a.g.dart': 'final t = DateTime.now();\n',
      'lib/b.freezed.dart': 'final t = DateTime.now();\n',
      'lib/l10n/gen/c.dart': 'final t = DateTime.now();\n',
    });
    final result = gate(tree);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('every offender is listed, not just the first', () {
    final result = check('''
final a = DateTime.now();
final b = DateTime.now();
''');
    expect(result.exitCode, 1);
    expect(result.output, contains('lib/a.dart:1:'));
    expect(result.output, contains('lib/a.dart:2:'));
  });
}
