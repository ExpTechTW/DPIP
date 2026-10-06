/// One reported bug is read-only. A staff reply that looks like a user, a
/// deleted body that renders as an empty bubble, or a Discord hand-off that
/// fails silently would hide who answered and where the conversation lives.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';
import 'package:dpip/features/bug_tracker/presentation/pages/bug_thread_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Repo implements BugRepository {
  Result<BugThreadDetail>? detail;
  int loads = 0;

  @override
  Future<Result<List<BugThread>>> threads() async => const Ok([]);

  @override
  Future<Result<BugThreadDetail>> thread(int id) async {
    loads++;
    return detail ?? const Err(NetworkFailure('down'));
  }

  @override
  Future<Result<Uint8List>> avatar(String url) async =>
      const Err(NetworkFailure('no avatar'));
}

BugThreadDetail _detail() {
  final thread = BugThread(
    id: 7,
    title: 'Map freezes on unlock',
    tags: const ['android', 'map'],
    body: '**steps** to reproduce',
    author: 780043079385612319,
    authorName: 'Admin Ada',
    authorAvatar: '',
    createdAt: DateTime.utc(2026, 3, 1, 8),
    locked: true,
  );
  return BugThreadDetail(
    thread: thread,
    messages: [
      BugMessage(
        id: 1,
        author: 452103762320949248,
        authorName: 'Staff Sam',
        authorAvatar: 'https://cdn.example/a.png',
        body: 'looking at it',
        time: DateTime.utc(2026, 3, 1, 9),
      ),
      BugMessage(
        id: 2,
        author: 42,
        authorName: 'Regular Ren',
        authorAvatar: '',
        body: null,
        time: DateTime.utc(2026, 3, 1, 10),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Provider<BugRepository>.value(
      value: repo,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BugThreadPage(id: 7, repository: repo),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows lock, badges, markdown, and a deleted reply', (
    tester,
  ) async {
    final repo = _Repo()..detail = Ok(_detail());
    await _pump(tester, repo);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text('Map freezes on unlock'), findsOneWidget);
    expect(find.text('android'), findsOneWidget);
    expect(find.text(l10n.bugTrackerDeveloper), findsOneWidget);
    expect(find.text(l10n.bugTrackerStaff), findsOneWidget);
    expect(find.text(l10n.bugTrackerReplies), findsOneWidget);
    expect(find.text('looking at it'), findsOneWidget);
    expect(find.text(l10n.bugTrackerCannotDisplay), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsWidgets);
    expect(repo.loads, 1);

    await tester.tap(find.text(l10n.bugTrackerCannotDisplay));
    await tester.pump();
    await tester.tap(find.text(l10n.bugTrackerJoinDiscussion));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed load offers retry', (tester) async {
    final repo = _Repo();
    await _pump(tester, repo);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(repo.loads, 1);

    repo.detail = Ok(
      BugThreadDetail(
        thread: BugThread(
          id: 7,
          title: 'Recovered',
          body: '',
          author: 9,
          authorName: 'Pat',
          authorAvatar: '',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
    expect(find.text('Replies'), findsNothing);
    expect(repo.loads, 2);
  });
}
