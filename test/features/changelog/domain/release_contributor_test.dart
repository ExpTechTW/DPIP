import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a contributor decodes from the GitHub user object', () {
    final contributor = ReleaseContributor.fromJson({
      'login': 'whes1015',
      'htmlUrl': 'https://github.com/whes1015',
    });
    expect(contributor.login, 'whes1015');
    expect(contributor.htmlUrl, 'https://github.com/whes1015');
    expect(avatarUrlFor('whes1015'), contains('whes1015'));
  });
}
