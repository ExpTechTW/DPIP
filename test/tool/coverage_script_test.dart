/// `tool/dev/coverage.sh`, end to end, against a fake toolchain.
///
/// The script is thin, but each thing it decides is a way to report a coverage
/// run that did not happen: a failed suite recorded as a pass, or a refresh
/// that never happens after an edit. These run the real script and `_lib.sh` in
/// a throwaway repository, with `mise` stubbed so `flutter test` is a fixture
/// instead of a minute.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Writes the lcov a real run would have written, counts how often it was
/// called, and exits with `FAKE_EXIT`.
///
/// The lcov is written *before* a failing exit, and that order is the point:
/// `flutter test` collects coverage and only then exits with the suite's status
/// (flutter_tools `TestCommand`), so a failed run still leaves a
/// complete-looking file behind. A fake that wrote nothing on failure would let
/// a script that stamped that run as a pass go unnoticed.
const _fakeMise = r'''#!/bin/sh
echo run >> "$FAKE_LOG"
path=coverage/lcov.info
while [ $# -gt 0 ]; do
  if [ "$1" = --coverage-path ]; then path="$2"; fi
  shift
done
mkdir -p "$(dirname "$path")"
cat > "$path" <<LCOV
SF:lib/a.dart
DA:1,1
DA:2,${FAKE_EXIT:-0}
LF:2
LH:1
end_of_record
LCOV
exit "${FAKE_EXIT:-0}"
''';

class Repo {
  Repo._(this.dir);

  final Directory dir;

  static Repo create() {
    final dir = Directory.systemTemp.createTempSync('dpipcovscript');
    addTearDown(() => dir.deleteSync(recursive: true));
    Process.runSync('git', ['init', '-q', dir.path]);
    for (final path in ['tool/dev/_lib.sh', 'tool/dev/coverage.sh']) {
      final target = File('${dir.path}/$path')
        ..parent.createSync(recursive: true);
      File('${Directory.current.path}/$path').copySync(target.path);
    }
    Process.runSync('chmod', ['+x', '${dir.path}/tool/dev/coverage.sh']);
    File('${dir.path}/lib/a.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('int a() => 1;\n');
    File('${dir.path}/lib/a_part.dart')
        .writeAsStringSync("part of 'a.dart';\n");
    File('${dir.path}/test/a_test.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('void main() {}\n');
    // What a checkout ignores; the report must not invalidate the cache key it
    // is computed alongside.
    File('${dir.path}/.gitignore')
        .writeAsStringSync('/coverage/\n/.dart_tool/\n');

    final bin = Directory('${dir.path}/bin')..createSync();
    final mise = File('${bin.path}/mise')..writeAsStringSync(_fakeMise);
    Process.runSync('chmod', ['+x', mise.path]);
    return Repo._(dir);
  }

  File get lcov => File('${dir.path}/coverage/lcov.info');
  File get _log => File('${dir.path}/fake.log');
  int get flutterRuns => _log.existsSync() ? _log.readAsLinesSync().length : 0;

  ProcessResult run({bool ifChanged = false, int exit = 0}) => Process.runSync(
    '${dir.path}/tool/dev/coverage.sh',
    [if (ifChanged) '--if-changed'],
    workingDirectory: dir.path,
    environment: {
      'PATH': '${dir.path}/bin:${Platform.environment['PATH']}',
      // Past require_mise: the fake is not an SDK install to inspect.
      'DPIP_MISE_CHECKED': '1',
      'DPIP_NO_CACHE': '',
      'FAKE_LOG': _log.path,
      'FAKE_EXIT': '$exit',
    },
  );
}

void main() {
  test('a run writes the report and imports every library', () {
    final repo = Repo.create();

    final result = repo.run();

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(repo.lcov.readAsStringSync(), contains('SF:lib/a.dart'));
    final all = File(
      '${repo.dir.path}/.dart_tool/dpip_coverage/all_libraries_test.dart',
    ).readAsStringSync();
    expect(all, contains("import 'package:dpip/a.dart' as l0;"));
    expect(
      all,
      isNot(contains('a_part.dart')),
      reason: '`part of` cannot be imported',
    );
  });

  test('--if-changed skips an unchanged tree and reruns after an edit', () {
    final repo = Repo.create();
    expect(repo.run().exitCode, 0);
    expect(repo.flutterRuns, 1);

    expect(repo.run(ifChanged: true).exitCode, 0);
    expect(repo.flutterRuns, 1, reason: 'nothing the suite reads has changed');

    File('${repo.dir.path}/lib/a.dart').writeAsStringSync('int a() => 2;\n');
    expect(repo.run(ifChanged: true).exitCode, 0);
    expect(repo.flutterRuns, 2, reason: 'an edit is exactly when to refresh');
  });

  test('--if-changed still runs when there is no report to keep', () {
    final repo = Repo.create();
    expect(repo.run().exitCode, 0);
    repo.lcov.deleteSync();

    expect(repo.run(ifChanged: true).exitCode, 0);

    expect(repo.flutterRuns, 2);
    expect(repo.lcov.existsSync(), isTrue);
  });

  test('a failing suite fails, and its tree is not stamped as passing', () {
    final repo = Repo.create();
    expect(repo.run().exitCode, 0);
    File('${repo.dir.path}/lib/a.dart').writeAsStringSync('int a() => 3;\n');

    final failed = repo.run(exit: 1);

    expect(failed.exitCode, isNot(0));
    // The same tree again: had the failure been stamped as a pass, this would
    // be skipped.
    expect(repo.run(ifChanged: true).exitCode, 0);
    expect(repo.flutterRuns, 3);
  });
}
