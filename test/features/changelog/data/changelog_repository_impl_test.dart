/// A release the parser cannot read must be skipped, and the avatar fetch
/// must return the bytes the card paints. Failing the whole page on one bad
/// release blanks the changelog the update check reads.
library;

import 'dart:typed_data';

import 'package:dpip/features/changelog/data/changelog_api.dart';
import 'package:dpip/features/changelog/data/changelog_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements ChangelogApi {
  int? page;
  String? avatarLogin;

  @override
  Future<List<dynamic>> getReleases({int page = 1}) async {
    this.page = page;
    return [
      {
        'tag_name': 'v2',
        'prerelease': false,
        'published_at': '2026-10-02T00:00:00Z',
      },
      'not-a-release',
      {'tag_name': 'broken'},
      {
        'tag_name': 'v1',
        'prerelease': true,
        'published_at': '2026-09-01T00:00:00Z',
      },
    ];
  }

  @override
  Future<Uint8List> getAvatarBytes(String login) async {
    avatarLogin = login;
    return Uint8List.fromList([1, 2, 3]);
  }
}

void main() {
  test('releases skip a bad entry and avatars come back as bytes', () async {
    final api = _Api();
    final repo = ChangelogRepositoryImpl(api);

    final notes = await repo.releases(page: 2);
    final bytes = await repo.avatarBytes('whes1015');

    expect(api.page, 2);
    expect(notes.valueOrNull!.map((n) => n.tagName), ['v2', 'v1']);
    expect(api.avatarLogin, 'whes1015');
    expect(bytes.valueOrNull, [1, 2, 3]);
  });
}
