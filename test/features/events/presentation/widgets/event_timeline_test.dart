/// The events timeline is how a township's history is told apart from a
/// failed fetch. An empty success and an error must not look the same, and
/// the cards must read newest first whatever order the server lists them in.
library;

import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/presentation/widgets/event_card_tile.dart';
import 'package:dpip/features/events/presentation/widgets/event_timeline.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/day_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../event_card_fixtures.dart';

class _Repo implements EventRepository {
  _Repo(this.result);

  Result<List<EventCard>> result;
  final List<String?> requests = [];

  @override
  Future<Result<List<EventCard>>> events({String? regionCode}) async {
    requests.add(regionCode);
    return result;
  }

  @override
  Future<Result<List<EventCard>>> activeEvents({String? regionCode}) async =>
      result;

  @override
  Future<Result<EventCardDetail>> detail({
    required int id,
    String? regionCode,
  }) async => const Err(NetworkFailure('unused'));
}

/// Card [id], sent at 03:04 Taipei time today plus [minutes].
EventCard _card(int id, String title, {int minutes = 0}) {
  final today = AppTime.taipei(AppTime.utc);
  return eventCard(
    id: id,
    hazard: id == 1 ? EventHazard.earthquake : EventHazard.tsunami,
    title: title,
    subtitle: 'detail $id',
    send: DateTime.utc(today.year, today.month, today.day - 1, 19, 4 + minutes),
    expires: AppTime.utc.add(const Duration(days: 1)),
  );
}

Future<void> _pump(WidgetTester tester, EventRepository repo) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Provider<EventRepository>.value(
      value: repo,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: EventTimeline(regionCode: '63000')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('two cards render titles, times, and subtitles', (tester) async {
    final repo = _Repo(Ok([_card(1, 'Quake'), _card(2, 'Wave')]));
    await _pump(tester, repo);
    expect(find.text('Quake'), findsOneWidget);
    expect(find.text('Wave'), findsOneWidget);
    expect(find.text('detail 1'), findsOneWidget);
    expect(find.text('03:04'), findsNWidgets(2));
    expect(repo.requests, ['63000']);
  });

  test('cards group under one heading per Taipei day', () {
    // 23:30 and 16:30 UTC are 07:30 and 00:30 the next day in Taipei; 15:30
    // UTC is still 23:30 on the first day.
    final late = eventCard(id: 3, send: DateTime.utc(2026, 11, 27, 23, 30));
    final early = eventCard(id: 2, send: DateTime.utc(2026, 11, 27, 16, 30));
    final before = eventCard(id: 1, send: DateTime.utc(2026, 11, 27, 15, 30));

    final rows = EventTimeline.rowsOf([late, early, before]);

    expect(rows, hasLength(5));
    expect(
      rows[0],
      isA<EventTimelineDay>()
          .having((r) => r.day, 'day', DateTime(2026, 11, 28))
          .having((r) => r.count, 'count', 2)
          .having((r) => r.first, 'first', isTrue),
    );
    expect(
      rows[1],
      isA<EventTimelineCard>()
          .having((r) => r.card, 'card', late)
          .having((r) => r.isFirst, 'isFirst', isTrue)
          .having((r) => r.isLast, 'isLast', isFalse),
    );
    expect(
      rows[2],
      isA<EventTimelineCard>()
          .having((r) => r.card, 'card', early)
          .having((r) => r.isLast, 'isLast', isTrue),
    );
    expect(
      rows[3],
      isA<EventTimelineDay>()
          .having((r) => r.day, 'day', DateTime(2026, 11, 27))
          .having((r) => r.count, 'count', 1)
          .having((r) => r.first, 'first', isFalse),
    );
    expect(
      rows[4],
      isA<EventTimelineCard>()
          .having((r) => r.isFirst, 'isFirst', isTrue)
          .having((r) => r.isLast, 'isLast', isTrue),
    );
    expect(EventTimeline.rowsOf(const []), isEmpty);
  });

  testWidgets('an older card shows its clock under its day heading', (
    tester,
  ) async {
    final today = AppTime.taipei(AppTime.utc);
    // 19:04 UTC three days back is 03:04 Taipei two days ago.
    final older = eventCard(
      id: 5,
      title: 'Older',
      send: DateTime.utc(today.year, today.month, today.day - 3, 19, 4),
      expires: AppTime.utc.subtract(const Duration(days: 1)),
    );
    final repo = _Repo(Ok([_card(1, 'Quake'), older]));
    await _pump(tester, repo);

    expect(find.byType(DayHeader), findsNWidgets(2));
    // The heading names the day; the row does not repeat it.
    expect(find.text('03:04'), findsNWidgets(2));
  });

  testWidgets('a feed of one card can be pulled to fetch it again', (
    tester,
  ) async {
    final repo = _Repo(Ok([_card(1, 'Quake')]));
    await _pump(tester, repo);

    await tester.fling(find.text('Quake'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.requests, ['63000', '63000']);
    expect(find.text('Quake'), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('cards read newest first, not in the server id order', (
    tester,
  ) async {
    // Ascending id, as the server sends them; the later id was sent earlier.
    await _pump(
      tester,
      _Repo(
        Ok([
          _card(1, 'Sent last', minutes: 30),
          _card(2, 'Sent first'),
          _card(3, 'Sent second', minutes: 10),
        ]),
      ),
    );
    final titles = tester
        .widgetList<EventCardTile>(find.byType(EventCardTile))
        .map((tile) => tile.card.title)
        .toList();
    expect(titles, ['Sent last', 'Sent second', 'Sent first']);
  });

  testWidgets('saved history is listed under a banner, never as current', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo(
        Ok([
          _card(1, 'Quake'),
        ], stale: const Staleness(failure: NetworkFailure('offline'))),
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text('Quake'), findsOneWidget);
    expect(find.text(l10n.freshnessSavedCopyUnknownAge), findsOneWidget);
    expect(find.text(l10n.commonFetchFailed), findsNothing);
  });

  testWidgets('an empty feed is not an error', (tester) async {
    await _pump(tester, _Repo(const Ok([])));
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('a failed fetch can be retried into a list', (tester) async {
    final repo = _Repo(const Err(NetworkFailure('offline')));
    await _pump(tester, repo);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);

    repo.result = Ok([_card(1, 'Quake')]);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Quake'), findsOneWidget);
  });
}
