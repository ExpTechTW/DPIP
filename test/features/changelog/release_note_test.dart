/// Round-trip + list parsing for [ReleaseNote].
library;

import 'package:dpip/features/changelog/data/changelog_repository_impl.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _sample({
  String tag = 'v3.9.9',
  String name = 'v3.9.9',
  String body = '## Fixes\n- foo',
  bool prerelease = false,
  String publishedAt = '2026-07-01T12:00:00Z',
}) => {
  'tag_name': tag,
  'name': name,
  'body': body,
  'prerelease': prerelease,
  'published_at': publishedAt,
};

void main() {
  group('ReleaseNote.fromJson', () {
    test('round-trips the fields the UI needs', () {
      final json = _sample();
      final note = ReleaseNote.fromJson(json);
      expect(note.tagName, 'v3.9.9');
      expect(note.name, 'v3.9.9');
      expect(note.body, contains('Fixes'));
      expect(note.prerelease, isFalse);
      expect(
        note.publishedAt.toUtc().toIso8601String(),
        startsWith('2026-07-01'),
      );
      expect(note.toJson()['tag_name'], 'v3.9.9');
    });

    test('null body becomes empty string', () {
      final json = _sample()..['body'] = null;
      expect(ReleaseNote.fromJson(json).body, isEmpty);
    });
  });

  group('ChangelogRepositoryImpl.parseReleases', () {
    test('sorts newest first and skips junk', () {
      final notes = ChangelogRepositoryImpl.parseReleases([
        _sample(tag: 'v1.0.0', publishedAt: '2025-01-01T00:00:00Z'),
        'not-a-map',
        _sample(tag: 'v2.0.0', publishedAt: '2026-01-01T00:00:00Z'),
        {'tag_name': 1}, // unmappable
      ]);
      expect(notes.map((n) => n.tagName), ['v2.0.0', 'v1.0.0']);
    });
  });
}
