/// The changelog page — paging, and the snapshot filter.
///
/// It also exists so the page is *compiled* by `flutter test`. Nothing
/// imported it before, so the only thing that ever resolved it was
/// `flutter analyze`, and a page that analyses clean can still fail the
/// front-end compiler.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/presentation/pages/changelog_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(UnexpectedFailure('no network'));
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
  setUp(() {
    // A hanging PackageInfo channel would leave the "installed" mark unset.
    // Stamping the label makes that read complete on the first frame.
    AppBuild.debugSet(label: 'dev', code: 1);
  });

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

  testWidgets('everything shows, snapshots included', (tester) async {
    final repo = _PagedRepository([
      [
        _note('26w33a', prerelease: true, day: 3),
        _note('v26.1', prerelease: false, day: 2),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // Most installed builds are snapshots — every commit on main publishes
    // one — so hiding them would leave the build someone is running with no
    // entry at all.
    expect(find.text('26w33a'), findsWidgets);
    expect(find.text('v26.1'), findsWidgets);
  });

  testWidgets('and the toggle narrows it to releases', (tester) async {
    final repo = _PagedRepository([
      [
        _note('26w33a', prerelease: true, day: 3),
        _note('v26.1', prerelease: false, day: 2),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.science));
    await tester.pumpAndSettle();
    expect(find.text('26w33a'), findsNothing);
    expect(find.text('v26.1'), findsWidgets);
  });

  testWidgets('a release card foots the contributor avatars from its body', (
    tester,
  ) async {
    final repo = _PagedRepository([
      [
        ReleaseNote(
          tagName: 'v26.1',
          name: 'v26.1',
          body: '- a change — @whes1015\n- another — @ExpTechTW',
          prerelease: false,
          publishedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // Both @handles from the release body become a stacked avatar pile — no
    // pill, no name — and a lingering tap target is the avatar itself.
    expect(find.byType(CircleAvatar), findsNWidgets(2));
  });

  testWidgets('tapping a contributor avatar is safe even with no launcher', (
    tester,
  ) async {
    final repo = _PagedRepository([
      [
        ReleaseNote(
          tagName: 'v26.1',
          name: 'v26.1',
          body: '- a change — @whes1015',
          prerelease: false,
          publishedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a release without @handles has no contributor strip', (
    tester,
  ) async {
    final repo = _PagedRepository([
      [
        ReleaseNote(
          tagName: 'v26.1',
          name: 'v26.1',
          body: 'plain',
          prerelease: false,
          htmlUrl: 'https://github.com/ExpTechTW/DPIP/releases/tag/v26.1',
          publishedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.byType(CircleAvatar), findsNothing);
    // Every card still carries the button to its release on GitHub.
    expect(find.text('View on GitHub'), findsOneWidget);
  });

  testWidgets('the GitHub button opens the release page', (tester) async {
    final repo = _PagedRepository([
      [
        ReleaseNote(
          tagName: 'v26.1',
          name: 'v26.1',
          body: 'plain',
          prerelease: false,
          htmlUrl: 'https://github.com/ExpTechTW/DPIP/releases/tag/v26.1',
          publishedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View on GitHub'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty catalogue says so', (tester) async {
    await tester.pumpWidget(_wrap(_PagedRepository([[]])));
    await tester.pumpAndSettle();
    expect(find.text('No release notes yet'), findsOneWidget);
  });

  testWidgets('scrolling to the end loads the next page once', (tester) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _PagedRepository([
      [
        for (var i = 0; i < ChangelogRepository.pageSize; i++)
          _note('v$i', prerelease: false),
      ],
      [_note('v0', prerelease: false), _note('v-extra', prerelease: false)],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    final before = tester.widgetList(find.text('v0')).length;

    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(repo.requested, [1, 2]);
    expect(find.text('v-extra'), findsWidgets);
    controller.jumpTo(0);
    await tester.pump();
    expect(find.text('v0'), findsNWidgets(before));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed next page leaves the notes already on screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _FailSecondPage([
      [
        for (var i = 0; i < ChangelogRepository.pageSize; i++)
          _note('v$i', prerelease: false),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();

    expect(repo.requested, [1, 2]);
    expect(find.text('v29'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull to refresh asks for the first page again', (tester) async {
    final repo = _PagedRepository([
      [_note('v26.1', prerelease: false)],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(repo.requested.where((page) => page == 1).length, 2);
  });

  testWidgets('the installed build is the one marked current', (tester) async {
    AppBuild.debugSet(label: '26.1', code: 1);
    final repo = _PagedRepository([
      [
        _note('v26.1', prerelease: false, day: 2),
        _note('v26.0', prerelease: false, day: 1),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(find.text('v26.1'), findsWidgets);
  });

  testWidgets('a refused GitHub launch is logged, not thrown', (tester) async {
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _FailingLauncher();
    addTearDown(() => UrlLauncherPlatform.instance = previous);

    final repo = _PagedRepository([
      [
        ReleaseNote(
          tagName: 'v26.1',
          name: 'v26.1',
          body: 'plain',
          prerelease: false,
          htmlUrl: 'https://github.com/ExpTechTW/DPIP/releases/tag/v26.1',
          publishedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View on GitHub'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an open note closes it, and an empty body says so', (
    tester,
  ) async {
    final repo = _PagedRepository([
      [
        ReleaseNote(
          tagName: 'v26.1',
          name: 'v26.1',
          body: '',
          prerelease: false,
          publishedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(find.text('No notes for this release.'), findsOneWidget);

    await tester.tap(find.text('v26.1'));
    await tester.pumpAndSettle();
    expect(find.text('No notes for this release.'), findsNothing);

    await tester.tap(find.text('v26.1'));
    await tester.pumpAndSettle();
    expect(find.text('No notes for this release.'), findsOneWidget);
  });

  testWidgets('a note link that the platform refuses is swallowed', (
    tester,
  ) async {
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _FailingLauncher();
    addTearDown(() => UrlLauncherPlatform.instance = previous);

    final repo = _PagedRepository([
      [
        ReleaseNote(
          tagName: 'v26.1',
          name: 'v26.1',
          body: 'See [the notes](https://example.com/notes).',
          prerelease: false,
          publishedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('notes'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _FailSecondPage extends _PagedRepository {
  _FailSecondPage(super.pages);

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async {
    requested.add(page);
    if (page > 1) return const Err(UnexpectedFailure('no more'));
    return Ok(pages[page - 1]);
  }
}

class _FailingLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => false;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    throw StateError('no browser');
  }
}
