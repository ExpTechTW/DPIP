/// The reported-bug index: state, sort, all-selected tag filtering and the id a
/// row hands to its detail route.
///
/// The repository is a read-only mirror, so sort and filter deliberately happen
/// in this page without another fetch. That makes the two quiet regressions easy
/// to ship: sorting the source list in place (the next rebuild starts from a
/// different order), or treating two selected tags as OR when the UI promises a
/// thread must carry both. The assertions below make both observable.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/bug_tracker/bug_tracker_counter.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';
import 'package:dpip/features/bug_tracker/presentation/pages/bug_list_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _BugRepository implements BugRepository {
  Result<List<BugThread>> next = const Ok([]);
  int calls = 0;

  @override
  Future<Result<List<BugThread>>> threads() async {
    calls++;
    return next;
  }

  @override
  Future<Result<BugThreadDetail>> thread(int id) => throw UnimplementedError();

  @override
  Future<Result<Uint8List>> avatar(String url) async => Ok(Uint8List(0));
}

BugThread _thread(
  int id, {
  required String title,
  required int replies,
  required int activity,
  List<String> tags = const [],
  String body = 'body',
}) => BugThread(
  id: id,
  title: title,
  tags: tags,
  body: body,
  author: id,
  authorName: 'author $id',
  authorAvatar: '',
  createdAt: DateTime.utc(2026, 1, id),
  messageCount: replies,
  lastMessageId: activity,
);

Future<void> _pump(WidgetTester tester, _BugRepository repository) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => BugListPage(repository: repository),
      ),
      GoRoute(
        path: '/thread/:id',
        name: AppRoutes.bugThread,
        builder: (_, state) =>
            Scaffold(body: Text('thread:${state.pathParameters['id']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<BugRepository>.value(value: repository),
        ChangeNotifierProvider(create: (_) => BugTrackerCounter(repository)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty mirror states that it is empty', (tester) async {
    final repository = _BugRepository();
    await _pump(tester, repository);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text(l10n.bugTrackerEmpty), findsOneWidget);
    expect(repository.calls, 1);
  });

  testWidgets('a dead mirror is an error with a retry', (tester) async {
    final repository = _BugRepository()
      ..next = const Err(NetworkFailure('No connection'));
    await _pump(tester, repository);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(ErrorView), findsOneWidget);
    // `AsyncView` deliberately exposes the shared fetch-failed copy rather than
    // leaking a transport message into presentation.
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);
    expect(find.byType(EmptyView), findsNothing);

    repository.next = Ok([
      _thread(1, title: 'recovered', replies: 0, activity: 1),
    ]);
    await tester.tap(find.widgetWithText(FilledButton, l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text('recovered'), findsOneWidget);
    expect(repository.calls, 2);
  });

  testWidgets('last activity is the default sort', (tester) async {
    final repository = _BugRepository()
      ..next = Ok([
        _thread(1, title: 'older', replies: 99, activity: 10),
        _thread(2, title: 'newer', replies: 1, activity: 20),
      ]);
    await _pump(tester, repository);

    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .where((s) => s == 'older' || s == 'newer'),
      ['newer', 'older'],
    );
  });

  testWidgets('most discussed changes the order without another fetch', (
    tester,
  ) async {
    final repository = _BugRepository()
      ..next = Ok([
        _thread(1, title: 'many replies', replies: 99, activity: 10),
        _thread(2, title: 'latest reply', replies: 1, activity: 20),
      ]);
    await _pump(tester, repository);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(
      find.widgetWithText(ChoiceChip, l10n.bugTrackerSortMostDiscussed),
    );
    await tester.pump();

    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .where((s) => s == 'many replies' || s == 'latest reply'),
      ['many replies', 'latest reply'],
    );
    expect(repository.calls, 1, reason: 'sort is display-only');
  });

  testWidgets('two selected tags mean AND, not OR', (tester) async {
    final repository = _BugRepository()
      ..next = Ok([
        _thread(
          1,
          title: 'both',
          replies: 1,
          activity: 3,
          tags: ['android', 'critical'],
        ),
        _thread(
          2,
          title: 'android only',
          replies: 1,
          activity: 2,
          tags: ['android'],
        ),
        _thread(
          3,
          title: 'critical only',
          replies: 1,
          activity: 1,
          tags: ['critical'],
        ),
      ]);
    await _pump(tester, repository);

    await tester.tap(find.text('android').first);
    await tester.pump();
    expect(find.text('both'), findsOneWidget);
    expect(find.text('android only'), findsOneWidget);
    expect(find.text('critical only'), findsNothing);

    await tester.tap(find.text('critical').first);
    await tester.pump();
    expect(find.text('both'), findsOneWidget);
    expect(find.text('android only'), findsNothing);
    expect(find.text('critical only'), findsNothing);
    expect(repository.calls, 1, reason: 'filter is display-only');
  });

  testWidgets('no match says the filters caused the empty view', (
    tester,
  ) async {
    final repository = _BugRepository()
      ..next = Ok([
        _thread(
          1,
          title: 'android only',
          replies: 0,
          activity: 1,
          tags: ['android'],
        ),
        _thread(2, title: 'ios only', replies: 0, activity: 2, tags: ['ios']),
      ]);
    await _pump(tester, repository);

    await tester.tap(find.text('android').first);
    await tester.pump();
    await tester.tap(find.text('ios').first);
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.bugTrackerNoMatch), findsOneWidget);
    expect(find.text(l10n.bugTrackerEmpty), findsNothing);
  });

  testWidgets('a row carries its own id to the detail page', (tester) async {
    final repository = _BugRepository()
      ..next = Ok([_thread(42, title: 'open me', replies: 0, activity: 1)]);
    await _pump(tester, repository);

    await tester.tap(find.text('open me'));
    await tester.pumpAndSettle();

    expect(find.text('thread:42'), findsOneWidget);
  });

  testWidgets('markdown is stripped in the two-line preview', (tester) async {
    final repository = _BugRepository()
      ..next = Ok([
        _thread(
          1,
          title: 'markdown',
          replies: 0,
          activity: 1,
          body:
              '# Heading\n- **bold** [link](https://example.com) '
              '![image](https://example.com/a.png)',
        ),
      ]);
    await _pump(tester, repository);

    expect(find.text('Heading • bold link'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
  });
}
