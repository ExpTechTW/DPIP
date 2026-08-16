/// The version scheme's behaviour, exercised against a scratch repository.
///
/// The repo-level test next door checks the shape of today's output; this one
/// checks the *rules* — what makes a build a release, how the weekly letter
/// advances, and what happens at a year boundary. They are worth pinning
/// because every one of them fails late: a wrong train reaches Apple as a
/// silently rewritten number, and a wrong letter collides at the last step of
/// a release, after both platforms have been built.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory repo;
  final script = '${Directory.current.path}/tool/version.sh';

  void git(List<String> args, {String? at}) {
    final result = Process.runSync(
      'git',
      args,
      workingDirectory: repo.path,
      environment: at == null
          ? null
          : {'GIT_AUTHOR_DATE': at, 'GIT_COMMITTER_DATE': at},
    );
    expect(result.exitCode, 0, reason: '${args.join(' ')}: ${result.stderr}');
  }

  void commit(String at) {
    File('${repo.path}/f').writeAsStringSync(at);
    git(['add', '-A'], at: at);
    git(['commit', '-m', at], at: at);
  }

  Map<String, Object?> version() {
    final result = Process.runSync('bash', [
      script,
      '--json',
    ], workingDirectory: repo.path);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
  }

  setUp(() {
    repo = Directory.systemTemp.createTempSync('dpip-version');
    git(['init', '-q', '.']);
    git(['config', 'user.email', 'test@example.com']);
    git(['config', 'user.name', 'test']);
    // Monday of ISO week 33, 2026.
    commit('2026-08-10T10:00:00Z');
  });

  tearDown(() => repo.deleteSync(recursive: true));

  test('a snapshot is named for its week, and lettered in order', () {
    expect(version()['label'], '26w33a');
    git(['tag', '26w33a']);
    commit('2026-08-11T10:00:00Z');
    expect(version()['label'], '26w33b');
    git(['tag', '26w33b']);
    commit('2026-08-12T10:00:00Z');
    expect(version()['label'], '26w33c');
  });

  test('only a `v` tag makes a build a release', () {
    // The failure this prevents is unrecoverable. Every published snapshot is
    // tagged, so `git describe --exact-match` — which answers with whichever
    // tag it likes — would take the release branch on the very next run and
    // set the train to `26w33a`. Flutter does not reject that: it strips the
    // letters and ships `2633.0.0` to Apple, where a marketing version can
    // never go down again, and the whole `26.x` range is gone.
    git(['tag', '26w33a']);
    final snapshot = version();
    expect(snapshot['label'], '26w33b', reason: 'still a snapshot');
    expect(snapshot['train'], matches(r'^\d+(\.\d+){0,2}$'));

    git(['tag', 'v26.1']);
    final release = version();
    expect(release['label'], '26.1');
    expect(release['train'], '26.1');
  });

  test('the tag is the release name, verbatim', () {
    git(['tag', 'v26.1.1']);
    final v = version();
    expect(v['label'], '26.1.1');
    expect(v['train'], '26.1.1');
  });

  test('a snapshot is named for the release it precedes', () {
    git(['tag', 'v26.1']);
    commit('2026-08-13T10:00:00Z');
    expect(
      version()['train'],
      '26.2',
      reason: 'the next release, not the last',
    );
  });

  test('a name already taken is skipped, not reused', () {
    // A run that tagged and then failed to publish leaves the count and the
    // tags disagreeing. A duplicate would fail the release at its last step,
    // after both platforms had been built.
    git(['tag', '26w33b']); // as if `a` were never tagged
    expect(version()['label'], isNot('26w33b'));
  });

  test('the year rolls over into its own first week', () {
    git(['tag', 'v26.4']);
    commit('2027-01-06T10:00:00Z');
    final v = version();
    expect(v['label'], '27w01a');
    expect(v['train'], '27.1', reason: 'a new year restarts at .1');
  });

  test('the code only ever increases', () {
    final first = version()['code']! as int;
    commit('2026-08-11T10:00:00Z');
    final second = version()['code']! as int;
    expect(second, greaterThan(first));
  });

  test('a busy year cannot outrun the next year\'s first build', () {
    // The count restarts each January, so the year digits are the only thing
    // carrying the ordering across the boundary. A year full of commits is the
    // case that would break it if the margin were too small.
    for (var day = 11; day < 25; day++) {
      commit('2026-08-${day}T10:00:00Z');
    }
    final busyYear = version()['code']! as int;

    commit('2027-01-06T10:00:00Z');
    final newYear = version()['code']! as int;
    expect(newYear, greaterThan(busyYear));
    // And the margin is a whole million — the count would need that many
    // commits in one year to cross it.
    expect(newYear ~/ 1000000, busyYear ~/ 1000000 + 1);
  });
}
