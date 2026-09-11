/// Which source names a build, and in what order.
library;

import 'package:dpip/core/build_info.g.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a debug build names itself from the generated file', () async {
    // The case this exists for: `flutter run` never goes through CI, so there
    // is no --dart-define and the pubspec placeholder would have it report
    // `26.1.0 (1)` — a version that exists nowhere. The git hooks write the
    // same values tool/release/version.sh gives CI.
    await AppBuild.ensureLoaded();
    expect(AppBuild.label, kBuildLabel);
    expect(AppBuild.code, kBuildCode);
    expect(AppBuild.label, isNot('26.1.0'));
  });

  test('the cycle names the year, never the train inside it', () {
    // The highlights belong to the whole cycle, so 26.1 and 26.2 have to
    // reach the same heading — otherwise the second train reads as though the
    // first one's highlights were never written.
    AppBuild.debugSet(label: '26w35a', code: 42, train: '26.1');
    expect(AppBuild.cycle, '26.x');
    AppBuild.debugSet(label: '26w36e', code: 43, train: '26.2');
    expect(AppBuild.cycle, '26.x');
    AppBuild.debugSet(label: '27w01a', code: 44, train: '27.1');
    expect(AppBuild.cycle, '27.x');
    // A build outside the repository has no train to shorten; a heading of
    // '.x' would be worse than none.
    AppBuild.debugSet(label: 'dev', code: 0, train: '');
    expect(AppBuild.cycle, isEmpty);
    addTearDown(() => AppBuild.debugSet(label: 'dev', code: 0));
  });

  test('an unknown ordinal never counts as older', () {
    // Not knowing is not evidence of being behind, and prompting an update on
    // no evidence is how a user gets pushed off a build that works.
    expect(AppBuild.isNewerThan(500, current: 0), isFalse);
    expect(AppBuild.isNewerThan(0, current: 500), isFalse);
    expect(AppBuild.isNewerThan(501, current: 500), isTrue);
    expect(AppBuild.isNewerThan(500, current: 500), isFalse);
  });
}
