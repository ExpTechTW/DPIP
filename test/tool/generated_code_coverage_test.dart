/// Generated code stays out of test coverage because every generated file says
/// so itself.
///
/// `flutter test --coverage` leaves out each file that carries
/// `// coverage:ignore-file`, and that comment is the only exclusion there is:
/// CI's report and the editor's coverage view both show what the test runner
/// collected. A generated file without it breaks nothing else. It quietly adds
/// thousands of lines nobody writes tests for, and moves the total whenever a
/// translation or a model changes.
///
/// freezed writes the comment on its own. build.yaml has source_gen add it to
/// every `.g.dart`, and l10n.yaml has gen-l10n add it to the localizations. The
/// files tool/gen/ and tool/release/build_info.sh write hold constants only,
/// which have no lines to count, so they are not held to it.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _marker = '// coverage:ignore-file';

/// The first line of everything build_runner writes, `.g.dart` and
/// `.freezed.dart` alike.
const _buildRunnerHeader = '// GENERATED CODE - DO NOT MODIFY BY HAND';

void main() {
  final root = Directory.current.path;
  final sources = Directory('$root/lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  final fromBuildRunner = [
    for (final file in sources)
      if (file.readAsLinesSync().firstOrNull == _buildRunnerHeader) file,
  ];
  final fromGenL10n = [
    for (final file in sources)
      if (file.path.startsWith('$root/lib/l10n/gen/')) file,
  ];

  test('there is generated code to check', () {
    // A move or a renamed header that emptied these lists would let every
    // test below pass without looking at anything.
    expect(
      fromBuildRunner.where((f) => f.path.endsWith('.g.dart')),
      isNotEmpty,
    );
    expect(
      fromBuildRunner.where((f) => f.path.endsWith('.freezed.dart')),
      isNotEmpty,
    );
    expect(fromGenL10n, isNotEmpty);
  });

  for (final (generator, files, regenerate) in [
    ('build_runner', fromBuildRunner, 'tool/dev/codegen.sh'),
    ('gen-l10n', fromGenL10n, 'tool/dev/l10n.sh'),
  ]) {
    test('everything $generator writes is left out of coverage', () {
      final unmarked = [
        for (final file in files)
          if (!file.readAsLinesSync().contains(_marker))
            file.path.substring(root.length + 1),
      ];
      expect(
        unmarked,
        isEmpty,
        reason:
            'missing `$_marker`. Regenerate with $regenerate; the comment '
            'comes from build.yaml and l10n.yaml.',
      );
    });
  }
}
