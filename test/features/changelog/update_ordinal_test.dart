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

  group('localizedReleaseBody, per-language blocks', () {
    // Verbatim output of tool/release_notes.sh, so a change to the publishing
    // format fails here rather than on a phone.
    const note = '''
# 26w33b

_快照，取自 main 的 `36c65c5`。未經審查，可能有問題。_

### 🌟 新功能

- 更新日誌的平台標記改用本機圖示，離線也看得到 — YuYu1015
- 「更多」頁面會顯示這個版本的名稱與送審版號 — YuYu1015

### 🔌 最佳化

- 更新日誌改成捲到底再載入下一頁，開啟快很多 — YuYu1015

### 🐞 錯誤修正

- 更新日誌不再中英文一起顯示 — YuYu1015
- ![Android](https://raw.githubusercontent.com/ExpTechTW/DPIP/main/.github/assets/android.svg) 修正位置回報被大量丟棄，警報範圍可能算在舊位置上 — YuYu1015

<!-- dpip-lang:en-US -->
<details>
<summary>English</summary>

### 🌟 New features

- the changelog's platform tags are drawn locally and survive offline — YuYu1015
- the More page shows this build's own version and the train it ships under — YuYu1015

### 🔌 Improvements

- the changelog loads a page at a time and opens much faster — YuYu1015

### 🐞 Bug fixes

- the changelog no longer shows both languages at once — YuYu1015
- ![Android](https://raw.githubusercontent.com/ExpTechTW/DPIP/main/.github/assets/android.svg) fix location reports being dropped, which could aim alerts at a stale position — YuYu1015

</details>
<!-- /dpip-lang:en-US -->

<!-- dpip-lang:ja-JP -->
<details>
<summary>日本語</summary>

### 🐞 不具合修正

- 更新履歴が日本語と英語を同時に表示しなくなりました — YuYu1015

</details>
<!-- /dpip-lang:ja-JP -->

<!-- dpip-build: 426000311 -->
''';

    test('the unfolded language is served to 繁體中文 as-is', () {
      final out = localizedReleaseBody(note, 'zh-Hant-TW');
      expect(out, contains('更新日誌的平台標記改用本機圖示'));
      expect(out, isNot(contains('survive offline')));
      expect(out, isNot(contains('<details>')));
      expect(out, isNot(contains('dpip-lang')));
    });

    test('a reader gets their own language when the note carries it', () {
      final out = localizedReleaseBody(note, 'ja-JP');
      expect(out, contains('更新履歴が日本語と英語を同時に表示しなくなりました'));
      expect(out, isNot(contains('the changelog no longer shows')));
      expect(out, isNot(contains('<summary>')));
    });

    test('the language tag need not match exactly', () {
      // The app hands over `ja`; the note was published as `ja-JP`.
      expect(
        localizedReleaseBody(note, 'ja'),
        contains('更新履歴が日本語と英語を同時に表示しなくなりました'),
      );
      expect(
        localizedReleaseBody(note, 'en'),
        contains('the changelog loads a page at a time'),
      );
    });

    test('an untranslated language falls back to English, not to nothing', () {
      final out = localizedReleaseBody(note, 'th-TH');
      expect(out, contains('the changelog loads a page at a time'));
      expect(out, isNot(contains('更新日誌改成捲到底')));
    });

    test('简体 is not served 繁體 just because both start with zh', () {
      // There is no zh-Hans block here, so the primary text stands rather than
      // a wrong-script match — but it must never pick ja or en for a zh reader.
      final out = localizedReleaseBody(note, 'zh-Hans');
      expect(out, isNot(contains('survive offline')));
      expect(out, isNot(contains('更新履歴が')));
    });

    test('the heading survives translation', () {
      // The title and the snapshot caveat are written once, outside every
      // block; a translated reader would otherwise lose them.
      final out = localizedReleaseBody(note, 'en');
      expect(out, startsWith('# 26w33b'));
      expect(out, contains('快照'));
    });
  });
}
