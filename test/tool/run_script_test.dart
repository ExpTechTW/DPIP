/// `tool/run.sh` — `flutter run` with the log coloured, on the pinned SDK.
///
/// A wrapper around a pipeline has one classic defect: the pipeline reports the
/// *last* command's status, so a failed build exits 0 and the wrapper hides the
/// thing it wraps. That is what these check.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs the wrapper's pipeline with a stub in place of `flutter`.
ProcessResult runWith({required int exitCode, String stdout = ''}) {
  final bin = Directory.systemTemp.createTempSync('fakeflutter');
  final stub = File('${bin.path}/flutter')
    ..writeAsStringSync(
      '#!/bin/sh\nprintf "%s" ${_q(stdout)}\nexit $exitCode\n',
    );
  Process.runSync('chmod', ['+x', stub.path]);
  addTearDown(() => bin.deleteSync(recursive: true));
  final root = Directory.current.path;
  return Process.runSync('bash', [
    '-c',
    'set -euo pipefail\n'
        '${bin.path}/flutter run | $root/tool/colorize_logs.sh',
  ]);
}

String _q(String s) => "'${s.replaceAll("'", r"'\''")}'";

void main() {
  test('a failed build is not reported as success', () {
    // Without `pipefail` this is 0, because the colouriser succeeded.
    expect(runWith(exitCode: 7).exitCode, 7);
  });

  test('a successful run stays successful', () {
    expect(runWith(exitCode: 0).exitCode, 0);
  });

  test('the output still passes through', () {
    final result = runWith(
      exitCode: 0,
      stdout: 'flutter: [INFO] | 1:00:00 1ms | started\n',
    );
    expect(result.stdout, contains('started'));
    expect(result.stdout, isNot(contains('flutter: ')));
  });

  test('the wrapper marks the launch as its own', () {
    // bootstrap warns when this is absent, because a launch that skips the
    // script gets a different SDK and an uncoloured log, and says so nowhere.
    // The exact value is pinned in launch_marker_test.dart — `=1` passed this
    // assertion while being read as `false`, so the value is checked where the
    // reader's rule is documented, not here.
    expect(_script(), contains('DPIP_RUN_SH'));
  });

  test('the wrapper runs flutter through mise', () {
    // A shell's PATH is resolved once and goes stale; `mise exec` re-reads
    // mise.toml every time. See AGENTS.md → Toolchain.
    expect(_script(), contains('mise exec -- flutter run'));
    expect(_script(), isNot(contains('\nflutter run')));
  });
}

String _script() =>
    File('${Directory.current.path}/tool/run.sh').readAsStringSync();
