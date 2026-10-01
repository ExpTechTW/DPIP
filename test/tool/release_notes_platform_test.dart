/// `notes.sh`'s platform marks, and the history the trailer rule cannot reach.
///
/// The `Platform:` trailer became required at one commit, and main is never
/// rewritten — so the first release after it covered 59 entries written before
/// the rule, none with a trailer. The script stopped on the first of them, and
/// v26.3 shipped to both stores with no release published.
///
/// So: a commit from before the rule with no trailer is marked for both
/// platforms, as it was when written; a commit with a trailer keeps it; and a
/// commit after the rule with none still stops the note.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs the script's `platform_tag` on [sha] in [repo], with the platform
/// images replaced by `A` and `I`.
ProcessResult _tag(String sha, {String? repo}) {
  final script = File('${Directory.current.path}/tool/release/notes.sh')
      .readAsStringSync();
  final start = script.indexOf('PLATFORM_REQUIRED_SINCE=');
  final end = script.indexOf('\n}\n', script.indexOf('platform_tag()'));
  expect(start, isNot(-1), reason: 'the history cut-off is gone');
  final function = script.substring(start, end + 2);
  return Process.runSync('bash', [
    '-c',
    'TAG_ANDROID=A; TAG_IOS=I\n$function\nplatform_tag "\$1"',
    'platform_tag',
    sha,
  ], workingDirectory: repo);
}

void main() {
  test('a commit from before the rule, with no trailer, is for both', () {
    // b6ea9e89 — the commit v26.3's release notes stopped on.
    final result = _tag('b6ea9e89');

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, 'A I ');
  });

  test('a trailer is honoured, before the rule or after it', () {
    // 61f69f1a says `Platform: android`; af88c549 says `Platform: all`.
    expect(_tag('61f69f1a').stdout, 'A ');
    expect(_tag('af88c549').stdout, 'A I ');
  });

  test('a commit after the rule with no trailer still stops the note', () {
    final repo = Directory.systemTemp.createTempSync('notes').path;
    void git(List<String> args) {
      final r = Process.runSync('git', args, workingDirectory: repo);
      expect(r.exitCode, 0, reason: r.stderr.toString());
    }

    git(['init', '-q']);
    git([
      '-c',
      'user.name=t',
      '-c',
      'user.email=t@t',
      'commit',
      '-q',
      '--allow-empty',
      '-m',
      'fix: x\n\nFix(en-US): y',
    ]);

    final result = _tag('HEAD', repo: repo);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('no Platform: trailer'));
  });
}
