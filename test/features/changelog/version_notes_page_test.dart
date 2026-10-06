/// Version notes must show the release that names this build, and fall back
/// to the newest note when none does. Showing an empty page for a local
/// label, or the wrong note, is how a tester reports the wrong build.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/presentation/pages/version_notes_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _Repo implements ChangelogRepository {
  _Repo(this.result);

  Result<List<ReleaseNote>> result;

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async => result;

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(NetworkFailure('no avatar'));
}

ReleaseNote _note(String tag, DateTime at, {String body = 'Fixed the gate.'}) =>
    ReleaseNote(
      tagName: tag,
      name: tag,
      body: body,
      prerelease: tag.contains('w'),
      publishedAt: at,
    );

Future<void> _pump(WidgetTester tester, ChangelogRepository repo) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const VersionNotesPage()),
      GoRoute(
        name: AppRoutes.releaseHighlights,
        path: '/highlights',
        builder: (_, _) => const Scaffold(body: Text('highlights-page')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    Provider<ChangelogRepository>.value(
      value: repo,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('matches this build and opens highlights', (tester) async {
    final label = AppBuild.label;
    await _pump(
      tester,
      _Repo(
        Ok([
          _note('older', DateTime.utc(2020)),
          _note(label, DateTime.utc(2026, 3), body: 'Ship note — @someone'),
        ]),
      ),
    );
    expect(find.textContaining(label), findsWidgets);
    expect(find.textContaining('Ship note'), findsOneWidget);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('highlights-page'), findsOneWidget);
  });

  testWidgets('an empty list says there are no notes', (tester) async {
    await _pump(tester, _Repo(const Ok([])));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.moreVersionNotesEmpty), findsOneWidget);
  });

  testWidgets('a fetch error retries into the newest note', (tester) async {
    final repo = _Repo(const Err(NetworkFailure('github down')));
    await _pump(tester, repo);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);
    repo.result = Ok([_note('v9.9', DateTime.utc(2026, 4), body: 'Newest')]);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Newest'), findsOneWidget);
  });
}
