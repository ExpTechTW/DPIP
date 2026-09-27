/// The report catalogue page: what it asks the repository for, how rows are
/// grouped, and the three states that go wrong without saying anything — a
/// failure that renders as an empty list, an empty result that does not admit a
/// filter caused it, and a row tap that carries the wrong id to the detail page.
///
/// The clock is pinned so "Today" and "Yesterday" come from the calendar rather
/// than from the time the suite happens to run. The boundary that matters is
/// Taipei midnight (16:00 UTC), not the device's: the list is grouped in
/// `Asia/Taipei` and a report filed at 23:00 local belongs to that day.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_list_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 2026-03-10 14:00 Taipei.
final _now = DateTime.utc(2026, 3, 10, 6);

/// 2026-03-10 11:00 Taipei.
final _todayMorning = DateTime.utc(2026, 3, 10, 3);

/// 2026-03-10 23:00 Taipei — the same Taipei day as [_todayMorning], and the
/// instant a UTC-day grouping would put on the wrong date.
final _todayLate = DateTime.utc(2026, 3, 10, 15);

/// 2026-03-09 18:00 Taipei.
final _yesterday = DateTime.utc(2026, 3, 9, 10);

class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

class _ZeroElapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _FixedSource implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => Ok(_now.millisecondsSinceEpoch);
}

class _FakeReportRepository implements ReportRepository {
  final List<({int limit, int page, ReportListQuery query})> calls = [];
  Failure? nextError;
  List<PartialEarthquakeReport> nextPage = const [];

  /// When set, the first page never arrives — the state the list is in between
  /// the first frame and the server's answer.
  Completer<Result<List<PartialEarthquakeReport>>>? pending;

  @override
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  }) async {
    calls.add((limit: limit, page: page, query: query));
    final gate = pending;
    if (gate != null) return gate.future;
    final error = nextError;
    if (error != null) return Err(error);
    return Ok(page == 1 ? nextPage : const []);
  }

  @override
  Future<Result<EarthquakeReport>> get(String id) => throw UnimplementedError();
}

PartialEarthquakeReport _report(
  String id, {
  required DateTime originUtc,
  String location = '花蓮縣',
  double magnitude = 5.0,
}) => PartialEarthquakeReport(
  id: id,
  longitude: 121.5,
  latitude: 24.0,
  location: location,
  depth: 10.0,
  magnitude: magnitude,
  intensity: 4,
  time: originUtc.millisecondsSinceEpoch,
  trem: 0,
  md5: 'md5-$id',
);

Future<void> _pump(
  WidgetTester tester,
  _FakeReportRepository repository, {
  // A spinner never settles, so a test that expects one pumps a frame instead.
  bool settle = true,
}) async {
  // Tall enough that the whole list lays out; a lazy `ListView` would not build
  // the rows below the fold and the day assertions would pass vacuously.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ReportListPage()),
      GoRoute(
        path: '/report/:id',
        name: AppRoutes.earthquakeReport,
        builder: (context, state) =>
            Scaffold(body: Text('report:${state.pathParameters['id']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [Provider<ReportRepository>.value(value: repository)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  setUpAll(() async {
    final clock = ServerClock(_FixedClock(), _ZeroElapsed(), _FixedSource());
    await clock.sync();
    AppTime.install(clock);
  });

  group('grouping', () {
    test('a Taipei day is the UTC instant plus eight hours', () {
      expect(taipeiCalendarDay(_todayMorning), DateTime(2026, 3, 10));
      expect(taipeiCalendarDay(_todayLate), DateTime(2026, 3, 10));
      // 16:00 UTC is midnight in Taipei — the one instant where a UTC-day
      // grouping and a Taipei-day grouping disagree.
      expect(
        taipeiCalendarDay(DateTime.utc(2026, 3, 10, 15, 59)),
        DateTime(2026, 3, 10),
      );
      expect(
        taipeiCalendarDay(DateTime.utc(2026, 3, 10, 16)),
        DateTime(2026, 3, 11),
      );
    });

    test('consecutive reports on one day share a section', () {
      final sections = groupReportsByTaipeiDay([
        _report('a', originUtc: _todayMorning),
        _report('b', originUtc: _todayLate),
        _report('c', originUtc: _yesterday),
        _report('d', originUtc: _yesterday.subtract(const Duration(hours: 1))),
      ]);

      expect(sections, hasLength(2));
      expect(sections.first.reports.map((r) => r.id), ['a', 'b']);
      expect(sections.last.reports.map((r) => r.id), ['c', 'd']);
    });

    test('a day that reappears starts a new section, not a merge', () {
      // The server sends newest-first, so a repeat is an ordering anomaly. Fold
      // the second one back into the first and the header would sit far above
      // rows that belong to it, which reads as the wrong date on real data.
      final sections = groupReportsByTaipeiDay([
        _report('a', originUtc: _todayMorning),
        _report('b', originUtc: _yesterday),
        _report('c', originUtc: _todayLate),
      ]);

      expect(sections.map((s) => s.reports.single.id), ['a', 'b', 'c']);
    });

    test('no reports is no sections', () {
      expect(groupReportsByTaipeiDay(const []), isEmpty);
    });
  });

  group('the page', () {
    testWidgets('opens on page 1 with no filter applied', (tester) async {
      final repository = _FakeReportRepository()
        ..nextPage = [_report('a', originUtc: _todayMorning)];

      await _pump(tester, repository);

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.limit, 30);
      expect(repository.calls.single.page, 1);
      expect(repository.calls.single.query.isEmpty, isTrue);
    });

    testWidgets('an unanswered first load is a spinner, not an empty list', (
      tester,
    ) async {
      // The distinction the shared views exist for: a request still in flight
      // and a catalogue with nothing in it look identical as an empty screen,
      // and only one of them is worth retrying.
      final repository = _FakeReportRepository()..pending = Completer();

      await _pump(tester, repository, settle: false);

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.byType(EmptyView), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('a dead source is an error with a retry, never a blank list', (
      tester,
    ) async {
      final repository = _FakeReportRepository()
        ..nextError = const NetworkFailure('No connection');

      await _pump(tester, repository);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('No connection'), findsOneWidget);
      expect(find.byType(EmptyView), findsNothing);

      // The retry has to actually reach the repository — a button that only
      // rebuilds the same error is the failure this pins.
      repository.nextError = null;
      repository.nextPage = [_report('a', originUtc: _todayMorning)];
      await tester.tap(find.widgetWithText(FilledButton, l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsNothing);
      expect(repository.calls, hasLength(2));
    });

    testWidgets('nothing in the catalogue says so', (tester) async {
      await _pump(tester, _FakeReportRepository());

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text(l10n.reportListEmpty), findsOneWidget);
      expect(find.text(l10n.reportListEmptyFiltered), findsNothing);
    });

    testWidgets('rows are grouped under their Taipei day', (tester) async {
      final repository = _FakeReportRepository()
        ..nextPage = [
          _report('a', originUtc: _todayMorning, magnitude: 5.2),
          _report('b', originUtc: _todayLate, magnitude: 4.1),
          _report('c', originUtc: _yesterday, magnitude: 6.0),
        ];

      await _pump(tester, repository);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.textContaining(l10n.reportListToday), findsOneWidget);
      expect(find.textContaining(l10n.reportListYesterday), findsOneWidget);
      expect(find.text(l10n.reportListDayCount(2)), findsOneWidget);
      expect(find.text(l10n.reportListDayCount(1)), findsOneWidget);
      expect(find.text(l10n.reportListMagnitude('5.2')), findsOneWidget);
      expect(find.text(l10n.reportListMagnitude('4.1')), findsOneWidget);
      expect(find.text(l10n.reportListMagnitude('6.0')), findsOneWidget);
      // The 23:00 Taipei report is under today, not under tomorrow.
      expect(find.text(l10n.reportListEnd), findsOneWidget);
    });

    testWidgets('tapping a row hands that report id to the detail page', (
      tester,
    ) async {
      final repository = _FakeReportRepository()
        ..nextPage = [
          _report('a', originUtc: _todayMorning, location: '花蓮縣'),
          _report('b', originUtc: _todayLate, location: '臺東縣'),
        ];

      await _pump(tester, repository);
      await tester.tap(find.text('臺東縣'));
      await tester.pumpAndSettle();

      expect(find.text('report:b'), findsOneWidget);
    });

    testWidgets('applying a filter re-queries and marks the action', (
      tester,
    ) async {
      final repository = _FakeReportRepository()
        ..nextPage = [_report('a', originUtc: _todayMorning)];

      await _pump(tester, repository);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      // Sort order alone is a filter: the sheet reports it back as a non-empty
      // query even though no range was touched.
      await tester.tap(find.text(l10n.reportFilterOrderAsc));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reportFilterApply));
      await tester.pumpAndSettle();

      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.query.order, 'asc');
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
    });

    testWidgets('an empty result under a filter says the filter is why', (
      tester,
    ) async {
      final repository = _FakeReportRepository();

      await _pump(tester, repository);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.reportListEmpty), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reportFilterOrderAsc));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reportFilterApply));
      await tester.pumpAndSettle();

      // Still empty, but now it must not claim the catalogue is empty — the
      // rows exist and the user's own filter is hiding them.
      expect(find.text(l10n.reportListEmptyFiltered), findsOneWidget);
      expect(find.text(l10n.reportListEmpty), findsNothing);
    });
  });
}
