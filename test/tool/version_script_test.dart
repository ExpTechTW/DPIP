/// `tool/release/version.sh` — the one place a version is decided.
///
/// Tested because its three outputs fail late and expensively: a code that
/// repeats is refused by a store permanently, and a train that is not one to
/// three integers is silently rewritten by Flutter before Apple ever sees it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _run() {
  final result = Process.runSync('bash', ['tool/release/version.sh', '--json']);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

void main() {
  test('prints a label, a train and a code', () {
    final v = _run();
    expect(v['label'], isA<String>());
    expect(v['train'], isA<String>());
    expect(v['code'], isA<int>());
  });

  test('the train is something Apple will accept', () {
    // `CFBundleShortVersionString` must be "a period-separated list of at most
    // three non-negative integers" — ERROR ITMS-90060, enforced at upload, so
    // TestFlight is not a way around it.
    //
    // And the failure is worse than a rejection: Flutter's
    // `validatedBuildNameForPlatform` *strips* every character outside
    // `[0-9.]` before the build, so `26w14a` would reach Apple as `2614.0.0`
    // with only a trace-level notice. An App Store version can never go down,
    // so one accepted `2614.0.0` would lock out every number below it forever.
    expect(_run()['train'] as String, matches(r'^\d+(\.\d+){0,2}$'));
  });

  test('one number serves both stores, and its digits say what it is', () {
    final code = _run()['code']! as int;
    final year = int.parse(
      (Process.runSync('git', [
                'log',
                '-1',
                '--date=format:%y',
                '--format=%cd',
              ]).stdout
              as String)
          .trim(),
    );
    final commits = int.parse(
      (Process.runSync('git', [
                'rev-list',
                '--count',
                'HEAD',
                '--since=20$year-01-01T00:00:00Z',
              ]).stdout
              as String)
          .trim(),
    );
    // `4 | yy | commits-this-year`, readable straight off the digits. The
    // count is the only value anywhere that maps back to an exact revision —
    // a label names a week, not a commit.
    expect(code, 400000000 + year * 1000000 + commits);
  });

  test('the generation digit clears both stores at once', () {
    final code = _run()['code']! as int;
    // This is what lets the two platforms share one number, so it is worth a
    // test rather than a comment.
    //
    //   300909022  published on Play (3.9.9 build 22 under the layout the app
    //              shipped with); a versionCode is unique and increasing
    //              app-wide and forever.
    //   408283049  in TestFlight under train 26.1; within a train a build
    //              number may only increase.
    //
    // Clearing the second is also what makes train 26.1 usable again — drop
    // the generation to 3 and the year's first release could not be 26.1.
    expect(code, greaterThan(300909022));
    expect(code, greaterThan(408283049));
    // Android lint errors (`HighAppVersionCode`) a hundred million below
    // Play's own 2,100,000,000 cap. Year 99 with a million commits in it still
    // lands at 499,999,999.
    expect(code, lessThan(2000000000));
  });

  test('the label is free to be a name, and the train is not it', () {
    // The separation *is* the feature: a snapshot is named for the week it was
    // cut and uploads under the number of the release it precedes. A release's
    // train carries its major.minor, which is the number a user compares
    // against the store page — never the patch.
    final v = _run();
    final label = v['label']! as String;
    if (label.contains('w')) {
      expect(label, matches(r'^\d{2}w\d{2}[a-z]+$'));
      expect(label, isNot(v['train']));
    } else {
      expect(v['train'], matches(r'^\d+\.\d+$'));
    }
  });

  test('pubspec stays legal semver, because pub still parses it', () {
    // `version: 26.1` fails `flutter pub get` outright ("must have three
    // numeric components"), and `26w14a` fails to parse at all. It is a local
    // placeholder now, not the source of truth — but it must still be valid.
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    expect(line.split(':')[1].trim(), matches(r'^\d+\.\d+\.\d+\+\d+$'));
  });

  test('a three-part release advertises its major.minor as the train', () {
    // Apple's marketing version and the hero card's big number are the same
    // thing, and neither wants the patch: `v26.2.1` is the full version (the
    // label), but the train — and the card's leading number — is `26.2`. A
    // two-part label (`26.1`) already is its own train.
    const tag = 'v26.2.1-test-temp';
    addTearDown(() {
      Process.runSync('git', ['tag', '-d', tag]);
    });
    final tagResult = Process.runSync('git', ['tag', tag]);
    expect(tagResult.exitCode, 0, reason: tagResult.stderr.toString());

    final result = Process.runSync('bash', [
      'tool/release/version.sh',
      '--json',
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final v = jsonDecode(result.stdout.toString()) as Map<String, Object?>;
    expect(v['label'], '26.2.1-test-temp');
    expect(v['train'], '26.2');
  });
}
