/// The changelog page — paging, and the snapshot filter.
///
/// It also exists so the page is *compiled* by `flutter test`. Nothing
/// imported it before, so the only thing that ever resolved it was
/// `flutter analyze`, and a page that analyses clean can still fail the
/// front-end compiler.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/presentation/pages/changelog_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

ReleaseNote _note(String tag, {required bool prerelease, int day = 1}) =>
    ReleaseNote(
      tagName: tag,
      name: tag,
      body: 'notes for $tag',
      prerelease: prerelease,
      publishedAt: DateTime.utc(2026, 8, day),
    );

class _PagedRepository implements ChangelogRepository {
  _PagedRepository(this.pages);

  final List<List<ReleaseNote>> pages;
  final requested = <int>[];

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async {
    requested.add(page);
    if (page > pages.length) return const Ok([]);
    return Ok(pages[page - 1]);
  }
}

Widget _wrap(ChangelogRepository repo) => Provider<ChangelogRepository>.value(
  value: repo,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const ChangelogPage(),
  ),
);

void main() {
  testWidgets('asks for one page, not all of them', (tester) async {
    final repo = _PagedRepository([
      [
        for (var i = 0; i < ChangelogRepository.pageSize; i++)
          _note('v26.$i', prerelease: false, day: i + 1),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // A snapshot is published on every push, so fetching the whole list to
    // show the top of it gets slower every week.
    expect(repo.requested, [1]);
  });

  testWidgets('a short page is the last one', (tester) async {
    final repo = _PagedRepository([
      [_note('v26.1', prerelease: false)],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // Fewer entries than the page size means GitHub has no more — cheaper than
    // parsing the Link header it also sends, and it means no trailing spinner.
    expect(repo.requested, [1]);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('snapshots are hidden until asked for', (tester) async {
    final repo = _PagedRepository([
      [
        _note('26w33a', prerelease: true, day: 3),
        _note('v26.1', prerelease: false, day: 2),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // They outnumber releases by an order of magnitude within a week.
    expect(find.text('26w33a'), findsNothing);
    expect(find.text('v26.1'), findsWidgets);

    await tester.tap(find.byIcon(Icons.science_outlined));
    await tester.pumpAndSettle();
    expect(find.text('26w33a'), findsWidgets);
  });
}
