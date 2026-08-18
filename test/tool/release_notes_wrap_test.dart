/// `tool/release/notes.sh` extracts changelog entries with a whole-line regex,
/// and commit.md's own example wraps an entry across two lines. Those two facts
/// disagreed, and the disagreement shipped: three English sentences in the
/// 26w34b notes end mid-clause — "…is shown at full extent on the monitor and
/// the" — because the indented remainder never matched anything.
///
/// Nothing failed. The note built, the release published, and the only symptom
/// was a sentence that stops.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs the fold the extractor applies to a commit body.
///
/// Lifted from the script by reading it, so a change to the awk that stops
/// folding fails here rather than in a published release note.
String fold(String body) {
  final script = File('${Directory.current.path}/tool/release/notes.sh')
      .readAsStringSync();
  final start = script.indexOf("git log -1 --format=%b \"\$sha\" | awk '");
  expect(start, isNot(-1), reason: 'the fold is no longer where it was');
  final awk = script.substring(
    script.indexOf("'", start) + 1,
    script.indexOf("')", start),
  );

  final tmp = File(
    '${Directory.systemTemp.createTempSync('fold').path}/body.txt',
  )..writeAsStringSync(body);
  return Process.runSync('bash', [
        '-c',
        "awk ${_q(awk)} ${_q(tmp.path)}",
      ]).stdout
      as String;
}

String _q(String s) => "'${s.replaceAll("'", r"'\''")}'";

/// The regex the script uses, verbatim.
bool isEntry(String line) => RegExp(
  r'^(New|Optimization|Fix)\(([A-Za-z]{2,3}(-[A-Za-z0-9]+)*)\):\s*(.+)$',
).hasMatch(line);

void main() {
  test('a wrapped entry survives whole', () {
    const body = '''
New(en-US): a large event is shown at full extent on the monitor and the
  replay map
New(zh-Hant): 大事件在監視器與重播地圖上以完整範圍顯示
''';

    final entries = fold(body).split('\n').where(isEntry).toList();

    expect(entries, hasLength(2));
    // The half that used to be dropped.
    expect(entries.first, endsWith('and the replay map'));
  });

  test('an unwrapped entry is untouched', () {
    const body = 'Fix(en-US): stop the crash\nFix(zh-Hant): 修正閃退\n';

    expect(fold(body), body);
  });

  test('prose after an entry does not get folded into it', () {
    // The body's explanation is not part of the entry. A blank line ends it,
    // which is what separates a continuation from the next paragraph.
    const body = '''
Fix(en-US): stop the crash

The crash came from a null channel.
''';

    final entries = fold(body).split('\n').where(isEntry).toList();

    expect(entries, hasLength(1));
    expect(entries.single, 'Fix(en-US): stop the crash');
  });

  test('the released commit that exposed this now reads whole', () {
    // 41a3c1e8 shipped three truncated sentences. If the fold regresses, this
    // is the commit that will say so.
    final body =
        Process.runSync('git', ['log', '-1', '--format=%b', '41a3c1e8']).stdout
            as String;
    if (body.trim().isEmpty) return; // shallow clone

    final entries = fold(body).split('\n').where(isEntry).toList();

    expect(
      entries.where((e) => e.endsWith(' and the')),
      isEmpty,
      reason: 'an entry still ends mid-clause',
    );
  });
}
