/// `tool/check_commits.sh` — the gate that decides what may be committed.
///
/// Tested because its failure branches only run on bad input, so nothing
/// exercises them until CI rejects somebody. One of them referenced a variable
/// that had been deleted, and under `set -u` that is not a wrong verdict but a
/// crash — which the caller reads as "not zero", i.e. as a rejection with no
/// usable reason. It shipped, because a good message never reaches that line.
///
/// Every case below asserts the exit code **and** that the reason names the
/// rule, so a branch that dies on the way to printing one fails here.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

({int code, String out}) _check(String message) {
  final file = File(
    '${Directory.systemTemp.createTempSync('gate').path}/msg.txt',
  )..writeAsStringSync(message);
  final r = Process.runSync('bash', [
    'tool/check_commits.sh',
    '--message',
    file.path,
  ]);
  return (code: r.exitCode, out: '${r.stdout}${r.stderr}');
}

void _accepts(String message) {
  final r = _check(message);
  expect(r.code, 0, reason: r.out);
}

void _rejects(String message, String because) {
  final r = _check(message);
  expect(r.code, isNot(0), reason: 'should have been rejected:\n${r.out}');
  expect(
    r.out,
    contains(because),
    reason: 'rejected, but without saying why:\n${r.out}',
  );
}

void main() {
  group('accepts', () {
    test('a user-facing change with both required languages', () {
      _accepts(
        'feat(map): overlay radar echo\n\n'
        'New(zh-Hant): 地圖可以疊加雷達回波\n'
        'New(en-US): the map can overlay radar echo\n',
      );
    });

    test('several entries across several categories', () {
      _accepts(
        'perf(changelog): fetch one page at a time\n\n'
        'Optimization(zh-Hant): 甲\nOptimization(en-US): a\n'
        'Fix(zh-Hant): 乙\nFix(en-US): b\n',
      );
    });

    test('an optional language, without pairing it into every category', () {
      _accepts(
        'fix(changelog): show one language\n\n'
        'Fix(zh-Hant): 甲\nFix(en-US): a\nFix(ja-JP): あ\n',
      );
    });

    test('a type that owes the changelog nothing', () {
      _accepts('ci: cache the Swift package resolution\n');
    });

    test('a squashed summary, whose ` (#123)` nobody chose', () {
      // GitHub appends it; counting it against the limit failed commits on
      // main that had passed this gate while their PR was open.
      _accepts(
        'perf(changelog): fetch one page at a time and hide snapshots by '
        'default (#528)\n\n'
        'Optimization(zh-Hant): 甲\nOptimization(en-US): a\n',
      );
    });
  });

  group('rejects', () {
    test('a user-facing change with no entry at all', () {
      _rejects(
        'feat(map): overlay radar echo\n\nSome prose about why.\n',
        'needs at least one',
      );
    });

    test('中文 in the summary', () {
      // The branch that crashed: it names the rule, and naming it is the
      // whole point of a gate.
      _rejects(
        'fix(changelog): name the badges 測試版 and 正式版\n\n'
            'Fix(zh-Hant): 甲\nFix(en-US): a\n',
        'plain-ASCII',
      );
    });

    test('a summary past the limit', () {
      _rejects(
        'feat(changelog): ${'x' * 80}\n\nNew(zh-Hant): 甲\nNew(en-US): a\n',
        'the limit is 72',
      );
    });

    test('a summary that is not <type>(<scope>): <summary>', () {
      _rejects('Fix report\n', 'summary must be');
    });

    test('one language written and the other forgotten', () {
      _rejects(
        'feat(map): overlay radar\n\nNew(zh-Hant): 地圖可以疊加雷達回波\n',
        'missing en-US',
      );
    });

    test('lists that do not pair up', () {
      // Two 中文 entries and one English leaves those readers a shorter list,
      // with nothing to show it happened.
      _rejects(
        'fix(map): x\n\nFix(zh-Hant): 甲\nFix(zh-Hant): 乙\nFix(en-US): a\n',
        'they must pair up',
      );
    });

    test('a locale the app does not ship', () {
      _rejects(
        'feat(map): x\n\nNew(zh-Hant): 甲\nNew(en-US): a\nNew(de-DE): d\n',
        'unknown locale',
      );
    });

    test('a line that only looks like an entry', () {
      // `en_US` for `en-US`: silently not an entry, and the only symptom is a
      // shorter published list.
      _rejects(
        'feat(map): x\n\nNew(zh-Hant): 甲\nNew(en_US): a\n',
        'malformed entry',
      );
    });

    test('the marker the old format used', () {
      _rejects(
        'feat(map): x\n\nEnglish.\n\n=== 中文 ===\n中文\n',
        'declare entries as',
      );
    });

    test('a tool writing itself into the record', () {
      _rejects(
        'feat(map): x\n\nGenerated with something\n\n'
            'New(zh-Hant): 甲\nNew(en-US): a\n',
        'no tool attribution',
      );
    });

    test('a platform trailer that is neither android nor ios', () {
      // A typo silently drops the tag from the note rather than failing.
      _rejects(
        'fix(map): x\n\nPlatform: andriod\n\nFix(zh-Hant): 甲\nFix(en-US): a\n',
        "must be 'android' or 'ios'",
      );
    });
  });
}
