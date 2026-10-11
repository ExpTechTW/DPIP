/// `pinned` runs the toolchain without the variables git sets for a hook.
///
/// A hook runs with `GIT_DIR` set — always, in a linked worktree — and the
/// Flutter tool finds its own version by running git inside its SDK. With
/// `GIT_DIR` inherited that git read this repository instead: Flutter called
/// itself `2.5.501-0.0.pre` after DPIP's oldest tag, `pub get` refused every
/// package needing a real SDK, and every pre-push from a worktree failed with
/// a dependency error that had nothing to do with the dependencies.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('git hook variables do not reach the toolchain', () {
    final gitDir = Process.runSync('git', [
      'rev-parse',
      '--absolute-git-dir',
    ]).stdout.toString().trim();

    final result = Process.runSync(
      'bash',
      ['-c', 'source tool/dev/_lib.sh\npinned printenv GIT_DIR'],
      environment: {'GIT_DIR': gitDir, 'GIT_INDEX_FILE': '$gitDir/index'},
    );

    // printenv exits 1, printing nothing, for a variable that is not set.
    expect(result.stdout, isEmpty, reason: result.stderr.toString());
    expect(result.exitCode, 1);
  });
}
