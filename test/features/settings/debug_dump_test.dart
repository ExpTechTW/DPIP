/// What a diagnostics dump carries, and what it drops when it cannot carry it.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:dpip/features/settings/domain/debug_dump.dart';

void main() {
  List<String> lines(int n) => [
    for (var i = n - 1; i >= 0; i--) '[1:00:00][INFO]    : line $i',
  ];

  test('diagnostics first, then the log, separated by a blank line', () {
    final out = buildDump(
      diagnostics: 'Version: 26w34b',
      logLines: ['[1:00:00][INFO]    : started'],
    );
    expect(
      out,
      '=== 除錯資訊 ===\n'
      'Version: 26w34b\n'
      '\n'
      '=== 日誌紀錄 ===\n'
      '[1:00:00][INFO]    : started',
    );
  });

  test('the whole thing fits the limit', () {
    final out = buildDump(diagnostics: 'x' * 500, logLines: lines(2000));
    expect(out.length, lessThanOrEqualTo(dumpLimit));
  });

  test('the log is filled from the newest backwards', () {
    // Sized so exactly one line fits, rather than padded until it does.
    const head = '=== 除錯資訊 ===\nd\n\n=== 日誌紀錄 ===\n';
    const line = '[1:00:00][INFO]    : newest';
    final out = buildDump(
      diagnostics: 'd',
      logLines: const [line, '[1:00:00][INFO]    : oldest'],
      limit: head.length + line.length + 1,
    );
    expect(out, contains('newest'));
    expect(out, isNot(contains('oldest')));
  });

  test('but reads oldest first, like a log', () {
    final out = buildDump(
      diagnostics: 'x',
      logLines: ['[1:00:02][INFO]    : third', '[1:00:01][INFO]    : second'],
    );
    expect(out.indexOf('second'), lessThan(out.indexOf('third')));
  });

  test('diagnostics are never cut to make room', () {
    // A partial diagnostic reads as a complete one and is answered as if it
    // were, which is worse than carrying no log at all.
    final big = 'Version: 26w34b\n${'x' * 5000}';
    final out = buildDump(diagnostics: big, logLines: lines(50));
    expect(out, contains('Version: 26w34b'));
    expect(out, contains('x' * 5000));
    expect(out, isNot(contains('line 0')));
  });

  test('no log at all still produces a readable dump', () {
    final out = buildDump(diagnostics: 'Version: 26w34b', logLines: const []);
    expect(out, endsWith('=== 日誌紀錄 ==='));
  });

  test('a line is taken whole or not at all', () {
    const head = '=== 除錯資訊 ===\nd\n\n=== 日誌紀錄 ===\n';
    final out = buildDump(
      diagnostics: 'd',
      logLines: const ['[1:00:00][INFO]    : a line that will not fit'],
      // One short of what the line needs.
      limit: head.length + 10,
    );
    // Half a line is a lie about what was logged.
    expect(out, isNot(contains('a line')));
    expect(out.length, lessThanOrEqualTo(head.length + 10));
  });
}
