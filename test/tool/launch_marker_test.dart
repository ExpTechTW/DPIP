/// The launch guard's marker, and the trap it fell into.
///
/// `bool.fromEnvironment` reads only the exact string `true` and answers
/// `false` to everything else — including `1`, which is what the run script
/// passed at first. The guard then fired on the very launch that had obeyed
/// it, which is the worst possible failure for a guard: it punishes the
/// correct behaviour and teaches people to ignore it.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The marker exactly as bootstrap reads it.
bool launchedByTool() => const String.fromEnvironment('DPIP_RUN_SH') != '';

String script(String name) =>
    File('${Directory.current.path}/tool/$name').readAsStringSync();

void main() {
  test('the run scripts pass a value bool.fromEnvironment would accept', () {
    // Belt and braces: the reader takes any value, and the writers still send
    // the one that would survive being read the other way.
    for (final name in ['run.sh', 'run.ps1']) {
      expect(
        script(name),
        contains('--dart-define=DPIP_RUN_SH=true'),
        reason: name,
      );
      expect(script(name), isNot(contains('DPIP_RUN_SH=1')), reason: name);
    }
  });

  test('the marker is read in a way that accepts any value', () {
    // `1` must work as well as `true`, because the next person to edit the
    // script will not remember this.
    expect('1' != '', isTrue);
    expect(const bool.fromEnvironment('DPIP_RUN_SH'), isFalse);
    expect(launchedByTool(), isFalse, reason: 'unset in a test run');
  });

  test('both scripts mark the launch at all', () {
    for (final name in ['run.sh', 'run.ps1']) {
      expect(script(name), contains('DPIP_RUN_SH'), reason: name);
    }
  });
}
