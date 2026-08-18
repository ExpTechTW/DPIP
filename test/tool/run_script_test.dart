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
        '${bin.path}/flutter run | $root/tool/internal/colorize_logs.sh',
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

  test('the wrapper runs flutter through the pinned toolchain', () {
    // A shell's PATH is resolved once and goes stale; `mise exec` re-reads
    // mise.toml every time. See AGENTS.md → Toolchain.
    expect(_script(), contains('pinned flutter run'));
    expect(_script(), isNot(contains('\nflutter run')));
  });

  test('the toolchain is named in exactly one place', () {
    // The rule the whole tool/ layout exists to make true: `mise exec` appears
    // in the one helper every script sources, and nowhere else. A second copy
    // is a second thing to forget when the toolchain moves — and forgetting is
    // silent, because the wrong SDK builds fine.
    final offenders =
        Directory('${Directory.current.path}/tool')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.sh'))
            .where((f) => f.readAsStringSync().contains('mise exec'))
            .map((f) => f.path.split('/tool/').last)
            .toList()
          ..sort();

    // tooling.sh has to spell the string out to search for it.
    expect(offenders, ['check/tooling.sh', 'dev/_lib.sh']);
  });

  test('the launcher refuses to start without mise', () {
    // The rule that has no second chance: a bare `flutter` builds, runs and
    // passes, off an SDK nobody chose. The launcher is where everybody passes
    // through, so it is where the refusal has to live.
    expect(_script(), contains('require_mise'));
  });

  test('the launcher checks the scripts before it starts anything', () {
    expect(_script(), contains('tool/check/tooling.sh'));
  });

  test('the Windows launcher refuses too', () {
    final ps1 = File('${Directory.current.path}/tool/run.ps1')
        .readAsStringSync();
    expect(ps1, contains('Get-Command mise'));
  });

  test('the git hooks point at a script that exists', () {
    // The hooks have no file extension, so a rename sweep over `*.sh` misses
    // them — and the failure is one line of shell noise on every commit that
    // nobody reads, while build_info.g.dart quietly stops being refreshed and
    // the Debug-info page names the wrong build.
    final hooks = Directory('${Directory.current.path}/.githooks').listSync();
    expect(hooks, isNotEmpty);

    for (final hook in hooks.whereType<File>()) {
      final target = RegExp(r'show-toplevel\)"?/(\S+?)"')
          .firstMatch(hook.readAsStringSync())
          ?.group(1);
      if (target == null) continue;
      expect(
        File('${Directory.current.path}/$target').existsSync(),
        isTrue,
        reason: '${hook.path.split('/').last} runs $target, which is not there',
      );
    }
  });

  test('every dev script goes through that helper', () {
    final scripts = Directory('${Directory.current.path}/tool/dev')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sh') && !f.path.endsWith('_lib.sh'));

    for (final script in scripts) {
      expect(
        script.readAsStringSync(),
        contains('_lib.sh'),
        reason: '${script.path.split('/').last} does not source the helper',
      );
    }
  });
}

String _script() =>
    File('${Directory.current.path}/tool/run.sh').readAsStringSync();
