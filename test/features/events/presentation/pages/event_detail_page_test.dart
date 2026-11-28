/// The detail page is where a reader checks what a card said and whether it
/// still holds. A failed load must offer a retry, every report must be there
/// newest first, a cancellation must say so, and translated text must be one
/// tap from the original.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_caution.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_facts.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/presentation/pages/event_detail_page.dart';
import 'package:dpip/features/events/presentation/widgets/event_fact_chip.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../event_card_fixtures.dart';

class _Repo implements EventRepository {
  _Repo(this.result);

  Result<EventCardDetail> result;
  Completer<void>? gate;
  final List<({int id, String? regionCode})> requests = [];

  @override
  Future<Result<List<EventCard>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<List<EventCard>>> activeEvents({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<EventCardDetail>> detail({
    required int id,
    String? regionCode,
  }) async {
    requests.add((id: id, regionCode: regionCode));
    final gate = this.gate;
    if (gate != null) await gate.future;
    return result;
  }
}

late AppLocalizations _l10n;

Future<void> _pump(
  WidgetTester tester,
  _Repo repo, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Provider<EventRepository>.value(
      value: repo,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EventDetailPage(id: 1800000000, regionCode: '200'),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// A heavy-rain card issued 3 hours ago, updated 2 hours ago and cancelled 10
/// minutes ago, by serial as the server sends it.
EventCardDetail _cancelled() {
  final now = AppTime.utc;
  return EventCardDetail(
    lang: 'en',
    reports: [
      eventReport(
        serial: 1,
        kind: EventReportKind.issue,
        title: 'First',
        send: now.subtract(const Duration(hours: 3)),
        expires: now.add(const Duration(hours: 5)),
      ),
      eventReport(
        serial: 2,
        title: 'Second',
        send: now.subtract(const Duration(hours: 2)),
        expires: now.add(const Duration(hours: 6)),
      ),
      eventReport(
        serial: 3,
        kind: EventReportKind.cancel,
        title: 'Third',
        send: now.subtract(const Duration(minutes: 10)),
        expires: now.subtract(const Duration(minutes: 10)),
      ),
    ],
  );
}

void main() {
  setUpAll(() async {
    _l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('loads, with the card id and township it was opened with', (
    tester,
  ) async {
    final repo = _Repo(Ok(_cancelled()))..gate = Completer<void>();
    await _pump(tester, repo, settle: false);
    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.text(_l10n.eventDetailTitle), findsOneWidget);
    expect(repo.requests.single, (id: 1800000000, regionCode: '200'));

    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LoadingView), findsNothing);
    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('a failed load can be retried into the card', (tester) async {
    final repo = _Repo(const Err(NetworkFailure('offline')));
    await _pump(tester, repo);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(_l10n.commonFetchFailed), findsOneWidget);

    repo.result = Ok(_cancelled());
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Third'), findsNWidgets(2));
    expect(repo.requests, hasLength(2));
  });

  testWidgets('every report is listed newest first, under the latest one', (
    tester,
  ) async {
    await _pump(tester, _Repo(Ok(_cancelled())));
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    // The header and the newest report both carry the latest title.
    expect(find.text('Third'), findsNWidgets(2));
    expect(
      top(_l10n.eventReportSerial(3)),
      lessThan(top(_l10n.eventReportSerial(2))),
    );
    expect(
      top(_l10n.eventReportSerial(2)),
      lessThan(top(_l10n.eventReportSerial(1))),
    );
    expect(find.text(_l10n.eventReportKindIssue), findsOneWidget);
    expect(find.text(_l10n.eventReportKindUpdate), findsOneWidget);
    expect(find.text(_l10n.eventReportKindCancel), findsOneWidget);
  });

  testWidgets('a corrected report carries a "corrected" tag in the caution '
      'tone, and nothing of what it said before', (tester) async {
    final now = AppTime.utc;
    await _pump(
      tester,
      _Repo(
        Ok(
          EventCardDetail(
            lang: 'en',
            reports: [
              eventReport(
                serial: 1,
                kind: EventReportKind.issue,
                title: 'Heavy rain advisory',
                send: now.subtract(const Duration(hours: 2)),
                expires: now.add(const Duration(hours: 3)),
              ),
              eventReport(
                serial: 2,
                kind: EventReportKind.correct,
                title: 'Heavy rain advisory (corrected)',
                send: now.subtract(const Duration(hours: 1)),
                expires: now.add(const Duration(hours: 3)),
              ),
            ],
          ),
        ),
      ),
    );
    final tag = find.text(_l10n.eventReportKindCorrect);
    expect(tag, findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: tag, matching: find.byType(DecoratedBox)).first,
    );
    final context = tester.element(tag);
    expect(
      (box.decoration as BoxDecoration).color,
      AppCaution.container(context),
    );
    // The issue report keeps its own tag; only the corrected one is marked.
    expect(find.text(_l10n.eventReportKindIssue), findsOneWidget);
  });

  testWidgets('a cancelled card says so at the top, never "in effect"', (
    tester,
  ) async {
    await _pump(tester, _Repo(Ok(_cancelled())));
    expect(find.text(_l10n.eventStatusCancelled), findsOneWidget);
    expect(find.text(_l10n.eventStatusActive), findsNothing);
    expect(find.text(_l10n.eventStatusEnded), findsNothing);
  });

  testWidgets('a report shown translated can be switched to its original', (
    tester,
  ) async {
    final now = AppTime.utc;
    final detail = EventCardDetail(
      lang: 'en',
      reports: [
        eventReport(
          serial: 1,
          kind: EventReportKind.issue,
          title: 'Heavy rain advisory',
          subtitle: 'Taipei City',
          description: 'Heavy rain in Taipei City',
          send: now.subtract(const Duration(hours: 2)),
          expires: now.add(const Duration(hours: 2)),
          original: const EventOriginal(
            title: '大雨特報',
            subtitle: '臺北市',
            description: '臺北市有大雨',
          ),
        ),
        eventReport(
          serial: 2,
          lang: 'zh-TW',
          title: '大雨特報更新',
          subtitle: '新北市',
          send: now.subtract(const Duration(hours: 1)),
          expires: now.add(const Duration(hours: 3)),
        ),
      ],
    );
    await _pump(tester, _Repo(Ok(detail)));
    // Only the translated report has a toggle.
    expect(find.text(_l10n.eventDetailShowOriginal), findsOneWidget);
    expect(find.text('Heavy rain in Taipei City'), findsOneWidget);
    expect(find.text('臺北市有大雨'), findsNothing);

    await tester.tap(find.text(_l10n.eventDetailShowOriginal));
    await tester.pumpAndSettle();
    expect(find.text('大雨特報'), findsOneWidget);
    expect(find.text('臺北市'), findsOneWidget);
    expect(find.text('臺北市有大雨'), findsOneWidget);
    expect(find.text('Heavy rain in Taipei City'), findsNothing);
    expect(find.text(_l10n.eventDetailShowTranslation), findsOneWidget);

    await tester.tap(find.text(_l10n.eventDetailShowTranslation));
    await tester.pumpAndSettle();
    expect(find.text('Heavy rain in Taipei City'), findsOneWidget);
    expect(find.text('臺北市有大雨'), findsNothing);
  });

  testWidgets('only a report in its original text says it is untranslated', (
    tester,
  ) async {
    final now = AppTime.utc;
    await _pump(
      tester,
      _Repo(
        Ok(
          EventCardDetail(
            lang: 'en',
            reports: [
              eventReport(
                serial: 1,
                kind: EventReportKind.issue,
                title: 'First',
                send: now.subtract(const Duration(hours: 2)),
                expires: now.add(const Duration(hours: 1)),
                requestedLang: 'en',
              ),
              eventReport(
                serial: 2,
                title: '第二報',
                lang: 'zh-TW',
                send: now.subtract(const Duration(hours: 1)),
                expires: now.add(const Duration(hours: 1)),
                requestedLang: 'en',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text(_l10n.eventUntranslatedNotice), findsOneWidget);
  });

  testWidgets('headline facts are chips, and an earthquake has no end time', (
    tester,
  ) async {
    final now = AppTime.utc;
    final quake = eventReport(
      serial: 1,
      kind: EventReportKind.issue,
      type: 'earthquake.eew',
      hazard: EventHazard.earthquake,
      title: 'Earthquake early warning',
      send: now.subtract(const Duration(minutes: 1)),
      expiresOpen: true,
      addition: const {
        'eq': {'mag': 6.4, 'max': 5, 'depth': 10, 'loc': 'Hualien offshore'},
      },
    );
    final facts = eventFactsOfReport(quake);
    expect(facts, isNotEmpty);

    await _pump(
      tester,
      _Repo(Ok(EventCardDetail(lang: 'en', reports: [quake]))),
    );
    expect(find.byType(EventFactChip), findsNWidgets(facts.length));
    for (final fact in facts) {
      // The type's summary may repeat a value; the chips hold each once.
      expect(
        find.descendant(
          of: find.byType(EventFactChip),
          matching: find.textContaining(fact.display, findRichText: true),
        ),
        findsOneWidget,
        reason: fact.kind.name,
      );
    }
    // The type's family puts its summary under the header.
    expect(find.text(_l10n.eventDetailEewLatest), findsOneWidget);
    // An earthquake is over when it is reported: no state, no end time.
    expect(
      find.text(_l10n.eventDetailEnds(_l10n.eventDetailEndsUndetermined)),
      findsNothing,
    );
    expect(find.text(_l10n.eventStatusOpenEnded), findsNothing);
    expect(find.text(_l10n.eventStatusActive), findsNothing);
  });

  testWidgets('a warning with an open end time is "not set"', (tester) async {
    final now = AppTime.utc;
    await _pump(
      tester,
      _Repo(
        Ok(
          EventCardDetail(
            lang: 'en',
            reports: [
              eventReport(
                serial: 1,
                kind: EventReportKind.issue,
                type: 'tsunami.warning',
                hazard: EventHazard.tsunami,
                title: 'Tsunami warning',
                send: now.subtract(const Duration(hours: 1)),
                expiresOpen: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      find.text(_l10n.eventDetailEnds(_l10n.eventDetailEndsUndetermined)),
      findsOneWidget,
    );
    expect(find.text(_l10n.eventStatusOpenEnded), findsOneWidget);
  });

  testWidgets('a withdrawn earthquake warning still says so', (tester) async {
    final now = AppTime.utc;
    await _pump(
      tester,
      _Repo(
        Ok(
          EventCardDetail(
            lang: 'en',
            reports: [
              eventReport(
                serial: 2,
                kind: EventReportKind.cancel,
                type: 'earthquake.eew',
                hazard: EventHazard.earthquake,
                title: 'Earthquake early warning',
                send: now.subtract(const Duration(minutes: 1)),
                expires: now.subtract(const Duration(minutes: 1)),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text(_l10n.eventStatusCancelled), findsOneWidget);
    expect(find.text(_l10n.eventStatusEnded), findsNothing);
  });

  test('reports sort newest first, the later serial first on a tie', () {
    final at = DateTime.utc(2026, 11, 27, 1);
    final sorted = EventDetailPage.newestFirst([
      eventReport(serial: 1, send: at),
      eventReport(serial: 2, send: at),
      eventReport(serial: 3, send: at.subtract(const Duration(hours: 1))),
    ]);
    expect(sorted.map((report) => report.serial), [2, 1, 3]);
  });
}
