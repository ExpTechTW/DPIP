/// The events timeline is how a township's history is told apart from a
/// failed fetch. An empty success and an error must not look the same, and
/// the rail has to stop at the first and last event or the thread looks
/// endless.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/presentation/widgets/event_timeline.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Repo implements EventRepository {
  _Repo(this.result);

  Result<List<Event>> result;

  @override
  Future<Result<List<Event>>> events({String? regionCode}) async => result;

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async =>
      result;
}

Event _event(String id, String title) => Event(
  id: id,
  type: id == '1' ? EventType.earthquake : EventType.tsunami,
  time: DateTime(2026, 1, 2, 3, 4),
  title: title,
  description: 'detail $id',
);

Future<void> _pump(WidgetTester tester, EventRepository repo) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Provider<EventRepository>.value(
      value: repo,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: EventTimeline(regionCode: '63000')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('two events render titles, times, and descriptions', (
    tester,
  ) async {
    await _pump(tester, _Repo(Ok([_event('1', 'Quake'), _event('2', 'Wave')])));
    expect(find.text('Quake'), findsOneWidget);
    expect(find.text('Wave'), findsOneWidget);
    expect(find.text('detail 1'), findsOneWidget);
    expect(find.text('03:04'), findsNWidgets(2));
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

    repo.result = Ok([_event('1', 'Quake')]);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Quake'), findsOneWidget);
  });
}
