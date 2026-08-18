/// The content-hash cache in `tool/dev/_lib.sh`, which lets `tool/check.sh`
/// reproduce all of CI in about a second.
///
/// A cache in front of a gate has exactly one dangerous failure: handing back a
/// pass for a tree that has since changed. Nothing would say so — the gate
/// would simply never run again, and the first sign would be a red CI on a
/// branch that had been green locally all day. So these are mostly tests that
/// the key *does* change, and one that it deliberately does not.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A throwaway git repo with [files] in it, plus `tool/dev/_lib.sh` copied from
/// this repository — the real one, so it cannot drift from what ships.
Directory repoWith(Map<String, String> files) {
  final dir = Directory.systemTemp.createTempSync('dpipcache');
  addTearDown(() => dir.deleteSync(recursive: true));
  Process.runSync('git', ['init', '-q', dir.path]);

  for (final entry in files.entries) {
    final file = File('${dir.path}/${entry.key}')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(entry.value);
    expect(file.existsSync(), isTrue);
  }
  Directory('${dir.path}/tool/dev').createSync(recursive: true);
  File('${Directory.current.path}/tool/dev/_lib.sh')
      .copySync('${dir.path}/tool/dev/_lib.sh');
  return dir;
}

/// Sources the real helper and runs [script] inside [repo].
ProcessResult sh(Directory repo, String script, {String? noCache}) {
  return Process.runSync(
    'bash',
    ['-c', 'source tool/dev/_lib.sh\n$script'],
    workingDirectory: repo.path,
    // Set either way, never merely omitted. `Process.run` inherits the parent
    // environment, so a developer running the suite under DPIP_NO_CACHE=1 —
    // which is exactly what somebody debugging the cache does — would have
    // every caching test silently assert the opposite of what it says.
    environment: {'DPIP_NO_CACHE': noCache ?? ''},
  );
}

String keyOf(Directory repo, String paths) =>
    (sh(repo, 'cache_key $paths').stdout as String).trim();

void main() {
  test('the key follows the contents', () {
    final repo = repoWith({'lib/a.dart': 'one'});
    final before = keyOf(repo, 'lib');

    File('${repo.path}/lib/a.dart').writeAsStringSync('two');

    expect(keyOf(repo, 'lib'), isNot(before));
  });

  test('a touch alone does not invalidate', () {
    // The reason this is content-hashed and not mtime-based. A format pass, a
    // branch switch and a checkout all bump mtimes without changing what the
    // code says, and a cache that re-runs the whole suite after `git switch`
    // is a cache people turn off.
    final repo = repoWith({'lib/a.dart': 'one'});
    final before = keyOf(repo, 'lib');

    final f = File('${repo.path}/lib/a.dart');
    f.setLastModifiedSync(DateTime(2030));

    expect(keyOf(repo, 'lib'), before);
  });

  test('a rename invalidates, even with identical bytes', () {
    final repo = repoWith({'lib/a.dart': 'one'});
    final before = keyOf(repo, 'lib');

    File('${repo.path}/lib/a.dart').renameSync('${repo.path}/lib/b.dart');

    expect(keyOf(repo, 'lib'), isNot(before));
  });

  test('a deletion invalidates', () {
    final repo = repoWith({'lib/a.dart': 'one', 'lib/b.dart': 'two'});
    final before = keyOf(repo, 'lib');

    File('${repo.path}/lib/b.dart').deleteSync();

    expect(keyOf(repo, 'lib'), isNot(before));
  });

  test('a new untracked file invalidates', () {
    // Untracked-but-not-ignored counts: a test file somebody just wrote is the
    // most important thing in the input set and it has never been committed.
    final repo = repoWith({'lib/a.dart': 'one'});
    final before = keyOf(repo, 'lib');

    File('${repo.path}/lib/new.dart').writeAsStringSync('three');

    expect(keyOf(repo, 'lib'), isNot(before));
  });

  test('an ignored file does not', () {
    final repo = repoWith({'lib/a.dart': 'one', '.gitignore': 'lib/junk/\n'});
    final before = keyOf(repo, 'lib');

    File('${repo.path}/lib/junk/x.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('build output');

    expect(keyOf(repo, 'lib'), before);
  });

  test('a passing command is cached, and does not run twice', () {
    final repo = repoWith({'lib/a.dart': 'one'});
    const script = '''
      run() { echo ran >> ran.log; }
      cached demo "\$(cache_key lib)" run
      cached demo "\$(cache_key lib)" run
    ''';

    sh(repo, script);

    expect(File('${repo.path}/ran.log').readAsLinesSync(), ['ran']);
  });

  test('a failing command is never cached', () {
    // The one thing worse than re-running a slow check is skipping it because
    // it failed last time.
    final repo = repoWith({'lib/a.dart': 'one'});
    const script = '''
      run() { echo ran >> ran.log; return 1; }
      cached demo "\$(cache_key lib)" run || true
      cached demo "\$(cache_key lib)" run || true
    ''';

    sh(repo, script);

    expect(File('${repo.path}/ran.log').readAsLinesSync(), ['ran', 'ran']);
  });

  test('DPIP_NO_CACHE forces a run', () {
    final repo = repoWith({'lib/a.dart': 'one'});
    const script = '''
      run() { echo ran >> ran.log; }
      cached demo "\$(cache_key lib)" run
      cached demo "\$(cache_key lib)" run
    ''';

    sh(repo, script, noCache: '1');

    expect(File('${repo.path}/ran.log').readAsLinesSync(), ['ran', 'ran']);
  });

  test('an edit re-runs, and undoing the edit does not', () {
    // The frequent-commit case this exists for: try something, undo it, and the
    // proven state is still proven. Keeping one stamp per check would charge a
    // full run for the round trip.
    final repo = repoWith({'lib/a.dart': 'one'});
    const script = '''
      run() { echo ran >> ran.log; }
      cached demo "\$(cache_key lib)" run
    ''';

    sh(repo, script);
    File('${repo.path}/lib/a.dart').writeAsStringSync('two');
    sh(repo, script);
    File('${repo.path}/lib/a.dart').writeAsStringSync('one');
    sh(repo, script);

    expect(File('${repo.path}/ran.log').readAsLinesSync(), ['ran', 'ran']);
  });

  test('stamps do not accumulate without bound', () {
    final repo = repoWith({'lib/a.dart': 'seed'});
    const script = '''
      run() { :; }
      cached demo "\$(cache_key lib)" run
    ''';

    for (var i = 0; i < 20; i++) {
      File('${repo.path}/lib/a.dart').writeAsStringSync('content $i');
      sh(repo, script);
    }

    final stamps = Directory('${repo.path}/.git/dpip-checks').listSync();
    expect(stamps.length, lessThanOrEqualTo(8));
  });
}
