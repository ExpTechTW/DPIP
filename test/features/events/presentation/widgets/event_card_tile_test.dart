/// A card's row is where a reader decides whether an event still concerns
/// them, so its state label must never call a withdrawn or finished event
/// current, and a hazard this build does not know must still be listed.
library;

import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/features/events/presentation/event_hazard_style.dart';
import 'package:dpip/features/events/presentation/event_labels.dart';
import 'package:dpip/features/events/presentation/widgets/event_card_tile.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../event_card_fixtures.dart';

late AppLocalizations _l10n;

/// Pumps [card] in a router whose detail route records what it was opened
/// with.
Future<List<GoRouterState>> _pump(
  WidgetTester tester,
  EventCard card, {
  String? regionCode,
}) async {
  final opened = <GoRouterState>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: EventCardTile(card: card, regionCode: regionCode),
        ),
      ),
      GoRoute(
        path: AppRoutes.eventDetailPath,
        name: AppRoutes.eventDetail,
        builder: (_, state) {
          opened.add(state);
          return const Scaffold(body: Text('detail'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  setUpAll(() async {
    _l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  final now = AppTime.utc;

  testWidgets('a card in force reads "in effect"', (tester) async {
    await _pump(
      tester,
      eventCard(
        send: now.subtract(const Duration(hours: 1)),
        expires: now.add(const Duration(hours: 2)),
      ),
    );
    expect(find.text(_l10n.eventStatusActive), findsOneWidget);
    expect(find.text('Heavy rain advisory'), findsOneWidget);
    expect(find.text('Taipei City'), findsOneWidget);
    expect(find.byIcon(EventHazard.heavyRain.icon), findsOneWidget);
    // The first report carries no report number.
    expect(find.textContaining(_l10n.eventReportSerial(1)), findsNothing);
  });

  testWidgets('a cancelled card reads "cancelled", never "ended"', (
    tester,
  ) async {
    await _pump(
      tester,
      eventCard(
        serial: 3,
        kind: EventReportKind.cancel,
        send: now.subtract(const Duration(minutes: 10)),
        expires: now.subtract(const Duration(minutes: 10)),
      ),
    );
    expect(find.text(_l10n.eventStatusCancelled), findsOneWidget);
    expect(find.text(_l10n.eventStatusEnded), findsNothing);
    expect(find.text(_l10n.eventStatusActive), findsNothing);
  });

  testWidgets('a cancellation wins even while the end time is ahead', (
    tester,
  ) async {
    await _pump(
      tester,
      eventCard(
        kind: EventReportKind.cancel,
        send: now.subtract(const Duration(minutes: 10)),
        expires: now.add(const Duration(hours: 1)),
      ),
    );
    expect(find.text(_l10n.eventStatusCancelled), findsOneWidget);
    expect(find.text(_l10n.eventStatusActive), findsNothing);
  });

  testWidgets('an open end time reads "no end time yet"', (tester) async {
    await _pump(
      tester,
      eventCard(
        hazard: EventHazard.tsunami,
        type: 'tsunami.warning',
        send: now.subtract(const Duration(days: 2)),
        expiresOpen: true,
      ),
    );
    expect(find.text(_l10n.eventStatusOpenEnded), findsOneWidget);
    expect(find.text(_l10n.eventStatusEnded), findsNothing);
  });

  testWidgets('a card past its end time reads "ended"', (tester) async {
    await _pump(
      tester,
      eventCard(
        send: now.subtract(const Duration(days: 1)),
        expires: now.subtract(const Duration(hours: 1)),
      ),
    );
    expect(find.text(_l10n.eventStatusEnded), findsOneWidget);
    expect(find.text(_l10n.eventStatusActive), findsNothing);
  });

  testWidgets('a card with no end time at all is not shown as in force', (
    tester,
  ) async {
    await _pump(
      tester,
      eventCard(send: now.subtract(const Duration(hours: 1))),
    );
    expect(find.text(_l10n.eventStatusEnded), findsOneWidget);
  });

  testWidgets('an earthquake shows no in-force state', (tester) async {
    for (final (expires, open) in [
      (now.add(const Duration(hours: 2)), false),
      (now.subtract(const Duration(hours: 1)), false),
      (null, true),
    ]) {
      await _pump(
        tester,
        eventCard(
          type: 'earthquake',
          hazard: EventHazard.earthquake,
          title: 'Earthquake report',
          send: now.subtract(const Duration(hours: 2)),
          expires: expires,
          expiresOpen: open,
        ),
      );
      expect(find.text('Earthquake report'), findsOneWidget);
      for (final label in [
        _l10n.eventStatusActive,
        _l10n.eventStatusEnded,
        _l10n.eventStatusOpenEnded,
      ]) {
        expect(find.text(label), findsNothing, reason: '$expires $open');
      }
    }
  });

  testWidgets('an informational tsunami card shows no in-force state', (
    tester,
  ) async {
    for (final type in ['tsunami_note', 'tsunami.info']) {
      await _pump(
        tester,
        eventCard(
          type: type,
          hazard: EventHazard.tsunami,
          title: 'Tsunami information',
          send: now.subtract(const Duration(hours: 1)),
          expires: now.add(const Duration(hours: 23)),
        ),
      );
      expect(find.text('Tsunami information'), findsOneWidget);
      expect(find.text(_l10n.eventStatusActive), findsNothing, reason: type);
    }
  });

  testWidgets('a cancelled earthquake still reads "cancelled"', (tester) async {
    await _pump(
      tester,
      eventCard(
        kind: EventReportKind.cancel,
        type: 'earthquake.eew',
        hazard: EventHazard.earthquake,
        send: now.subtract(const Duration(minutes: 10)),
        expires: now.subtract(const Duration(minutes: 10)),
      ),
    );
    expect(find.text(_l10n.eventStatusCancelled), findsOneWidget);
  });

  testWidgets('the second report on shows its number', (tester) async {
    await _pump(
      tester,
      eventCard(
        serial: 4,
        kind: EventReportKind.update,
        send: now.subtract(const Duration(hours: 1)),
        expires: now.add(const Duration(hours: 1)),
      ),
    );
    expect(
      find.text(
        '${_l10n.eventHazardHeavyRain} · ${_l10n.eventReportSerial(4)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an unknown hazard is listed with the warning mark', (
    tester,
  ) async {
    await _pump(
      tester,
      eventCard(
        hazard: EventHazard.fromCode('meteor_shower'),
        hazardCode: 'meteor_shower',
        type: 'meteor_shower.watch',
        title: 'Something new',
        send: now.subtract(const Duration(hours: 1)),
        expires: now.add(const Duration(hours: 1)),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Something new'), findsOneWidget);
    expect(find.text(_l10n.eventHazardOther), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('a tap opens the detail with the card id and township', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      eventCard(
        id: 1800000001,
        send: now.subtract(const Duration(hours: 1)),
        expires: now.add(const Duration(hours: 1)),
      ),
      regionCode: '100',
    );
    await tester.tap(find.byType(EventCardTile));
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    expect(opened.last.pathParameters['id'], '1800000001');
    expect(opened.last.uri.queryParameters['region'], '100');
  });

  test('every hazard has an icon, a tone and a label', () {
    for (final hazard in EventHazard.values) {
      expect(hazard.label(_l10n), isNotEmpty, reason: hazard.name);
      expect(hazard.icon, isNotNull, reason: hazard.name);
      expect(hazard.tone, isNotNull, reason: hazard.name);
    }
    // Reserved codes keep the "other" name but draw their own picture; an
    // unknown code is a warning triangle.
    expect(EventHazard.typhoon.label(_l10n), _l10n.eventHazardOther);
    expect(EventHazard.typhoon.icon, isNot(EventHazard.unknown.icon));
    expect(EventHazard.unknown.icon, Icons.warning_amber_outlined);
    expect(EventHazard.earthquake.tone, EventHazardTone.seismic);
  });

  group('eventTimeLabel', () {
    // 2026-11-27 12:00 Taipei.
    final noon = DateTime.utc(2026, 11, 27, 4);

    test('the same Taipei day is a clock time', () {
      expect(
        eventTimeLabel(
          DateTime.utc(2026, 11, 26, 16, 30),
          nowUtc: noon,
          locale: 'en_US',
        ),
        '00:30',
      );
    });

    test('an earlier day carries its date', () {
      expect(
        eventTimeLabel(
          DateTime.utc(2026, 11, 26, 15, 59),
          nowUtc: noon,
          locale: 'en_US',
        ),
        '11/26 23:59',
      );
    });
  });
}
