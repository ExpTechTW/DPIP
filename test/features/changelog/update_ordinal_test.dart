/// Ordering by the ordinal, which is the whole point of separating it from the
/// name.
library;

import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/domain/update_check.dart';
import 'package:flutter_test/flutter_test.dart';

ReleaseNote _release(
  String tag, {
  required bool prerelease,
  int? code,
  String? label,
}) => ReleaseNote(
  tagName: tag,
  name: label ?? tag,
  body: code == null ? 'notes' : 'notes\n\n<!-- dpip-build: $code -->',
  prerelease: prerelease,
  publishedAt: DateTime.utc(2026, 8, 16),
);

void main() {
  test('a release advertises its ordinal invisibly', () {
    expect(
      buildCodeOf(_release('v26.1', prerelease: false, code: 408282756)),
      408282756,
    );
    expect(buildCodeOf(_release('v26.1', prerelease: false)), isNull);
  });

  test('a snapshot named for a later week does not outrank the release', () {
    // The exact case the name comparison gets wrong: `26w40a` reads larger
    // than `26.1`, and was built first.
    final releases = [
      _release('snapshot/26w40a', prerelease: true, code: 408_200_000),
      _release('v26.1', prerelease: false, code: 408_900_000),
    ];
    // On the stable channel, running the snapshot's predecessor.
    final update = findUpdate(
      releases: releases,
      currentVersion: '26.1',
      currentBuild: 408_100_000,
    );
    expect(update?.tagName, 'v26.1');
  });

  test('a channel still only hears about itself', () {
    final releases = [
      _release('snapshot/26w33a', prerelease: true, code: 409_000_000),
      _release('v26.1', prerelease: false, code: 408_900_000),
    ];
    // A stable user is not pushed onto the newer snapshot.
    expect(
      findUpdate(
        releases: releases,
        currentVersion: '26.1',
        currentBuild: 408_000_000,
      )?.tagName,
      'v26.1',
    );
  });

  test('an unnumbered release is skipped, not guessed at', () {
    final releases = [_release('v26.2', prerelease: false)];
    expect(
      findUpdate(
        releases: releases,
        currentVersion: '26.1',
        currentBuild: 408_000_000,
      ),
      isNull,
    );
  });

  test('the same build is never offered twice', () {
    final releases = [_release('v26.2', prerelease: false, code: 409_000_000)];
    expect(
      findUpdate(
        releases: releases,
        currentVersion: '26.1',
        currentBuild: 408_000_000,
        promptedBuild: 409_000_000,
      ),
      isNull,
    );
  });

  test('a build with no ordinal falls back to the old name compare', () {
    // Made before the scheme existed: it still gets offered the releases it
    // would have been, by DPIP's inflated-patch numbering.
    final releases = [
      _release('v3.9.9', prerelease: false),
      _release('v3.10.0', prerelease: false),
    ];
    expect(
      findUpdate(releases: releases, currentVersion: '3.9.9')?.tagName,
      'v3.10.0',
    );
  });

  group('one language, not both', () {
    const body = '''
# 26.2

### 🌟 新功能

- 地圖頁新增閃電圖層

<!-- dpip-en -->
<details>
<summary>English</summary>

### 🌟 New features

- add a lightning layer

</details>
<!-- /dpip-en -->

<!-- dpip-build: 426000301 -->''';

    test('a Chinese reader gets the Chinese half', () {
      final out = localizedReleaseBody(body, 'zh');
      expect(out, contains('地圖頁新增閃電圖層'));
      expect(out, isNot(contains('add a lightning layer')));
      // The fold is HTML, which the in-app renderer does not implement — left
      // in, its summary would print as prose.
      expect(out, isNot(contains('<details>')));
    });

    test('everyone else gets the English half, unfolded', () {
      final out = localizedReleaseBody(body, 'en');
      expect(out, contains('add a lightning layer'));
      expect(out, isNot(contains('地圖頁新增閃電圖層')));
      expect(out, isNot(contains('<details>')));
      expect(out, isNot(contains('<summary>')));
    });

    test('a note from before the scheme is left alone', () {
      // Better a bilingual note than an empty one.
      const old = 'Just some notes.';
      expect(localizedReleaseBody(old, 'zh'), old);
      expect(localizedReleaseBody(old, 'en'), old);
    });
  });
}
