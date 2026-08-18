/// `tool/release/discord.py` — the release announcement, inside Discord's
/// limits.
///
/// The truncation path only runs on a release big enough to overflow, which is
/// exactly the release nobody wants to discover it on. These force the overflow
/// with a smaller budget so the behaviour is exercised on every run, and read a
/// committed fixture rather than the API so they are neither flaky nor
/// rate-limited.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _android = '<:android:1539201870935892028>';
const _ios = '<:ios:1539201897766981692>';

Map<String, Object?> payload({int? limit, bool short = false}) {
  final root = Directory.current.path;
  final result = Process.runSync(
    'python3',
    ['$root/tool/release/discord.py', '26w34c', '--dry-run'],
    environment: {
      'DPIP_RELEASE_JSON': '$root/test/tool/fixtures/release_26w34c.json',
      'DPIP_EMOJI_ANDROID': short ? '<:a:1>' : _android,
      'DPIP_EMOJI_IOS': short ? '<:i:2>' : _ios,
      if (limit != null) 'DPIP_DISCORD_LIMIT': '$limit',
    },
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout as String) as Map<String, Object?>;
}

List<Object?> embeds(Map<String, Object?> p) => p['embeds']! as List<Object?>;
String description(Map<String, Object?> p) =>
    (embeds(p).single as Map<String, Object?>)['description']! as String;

/// `… (15/22)` → 15.
int shown(String text) =>
    RegExp(r'… \((\d+)/\d+\)')
        .allMatches(text)
        .map((m) => int.parse(m.group(1)!))
        .fold(0, (a, b) => a + b);

void main() {
  test('one embed, always inside the description limit', () {
    for (final limit in [4096, 3000, 2000, 1200]) {
      final p = payload(limit: limit);
      expect(embeds(p), hasLength(1), reason: 'limit $limit');
      expect(
        description(p).length,
        lessThanOrEqualTo(limit),
        reason: 'limit $limit',
      );
    }
  });

  test('the whole note when it fits, nothing marked missing', () {
    // Short ids stand in for a guild whose emoji names are brief; the note then
    // fits and no category should claim to be cut. Shortening only one of the
    // two still overflows — 55 entries pay for both on almost every line.
    final text = description(payload(short: true));

    expect(text, isNot(contains('… (')));
    expect(text, contains('修正換行的更新日誌條目在發布時被從中間截斷'));
  });

  test('hashes are dropped before any entry is', () {
    // The order matters: a hash costs a click on the link at the bottom, a
    // dropped entry means a change shipped and nobody was told.
    final full = description(payload(short: true));
    final tight = description(payload());

    expect(full, contains('`c5fdbd31`'));
    expect(tight, isNot(contains('`c5fdbd31`')));
  });

  test('a cut is split evenly between the categories', () {
    // Filling from the top until the budget runs out would spend it all on
    // 新功能 and post 錯誤修正 as an empty heading — a release where the fixes
    // are the point would read as a release with no fixes.
    final text = description(payload(limit: 1500));
    final counts = RegExp(r'… \((\d+)/(\d+)\)')
        .allMatches(text)
        .map((m) => int.parse(m.group(1)!))
        .toList();

    expect(counts, hasLength(greaterThanOrEqualTo(2)));
    expect(counts.toSet(), hasLength(1), reason: 'categories got $counts');
  });

  test('a smaller budget never shows more', () {
    expect(
      shown(description(payload(limit: 1200))),
      lessThanOrEqualTo(shown(description(payload(limit: 2000)))),
    );
  });

  test('the heading, the subtext and the link all survive a cut', () {
    final text = description(payload(limit: 1200));

    expect(text, startsWith('# 26w34c'));
    expect(text, contains('-# 快照，取自 main 的'));
    expect(text, contains('releases/tag/26w34c'));
  });
}
